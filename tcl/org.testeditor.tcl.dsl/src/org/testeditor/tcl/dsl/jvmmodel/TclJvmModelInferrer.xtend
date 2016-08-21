/*******************************************************************************
 * Copyright (c) 2012 - 2016 Signal Iduna Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * Contributors:
 * Signal Iduna Corporation - initial API and implementation
 * akquinet AG
 * itemis AG
 *******************************************************************************/
package org.testeditor.tcl.dsl.jvmmodel

import com.google.inject.Inject
import java.util.Set
import org.apache.commons.lang3.StringEscapeUtils
import org.eclipse.core.runtime.Path
import org.eclipse.jdt.core.IClasspathEntry
import org.eclipse.jdt.core.JavaCore
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmField
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.xbase.compiler.output.ITreeAppendable
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder
import org.testeditor.aml.InteractionType
import org.testeditor.aml.ModelUtil
import org.testeditor.dsl.common.util.WorkspaceRootHelper
import org.testeditor.tcl.AbstractTestStep
import org.testeditor.tcl.AssertionTestStep
import org.testeditor.tcl.AssignmentVariable
import org.testeditor.tcl.ComponentTestStepContext
import org.testeditor.tcl.EnvironmentVariable
import org.testeditor.tcl.MacroTestStepContext
import org.testeditor.tcl.SetupAndCleanupProvider
import org.testeditor.tcl.SpecificationStepImplementation
import org.testeditor.tcl.StepContentElement
import org.testeditor.tcl.TclModel
import org.testeditor.tcl.TestCase
import org.testeditor.tcl.TestConfiguration
import org.testeditor.tcl.TestStep
import org.testeditor.tcl.TestStepWithAssignment
import org.testeditor.tcl.VariableReference
import org.testeditor.tcl.VariableReferenceMapAccess
import org.testeditor.tcl.util.TclModelUtil
import org.testeditor.tsl.StepContent
import org.testeditor.tsl.StepContentValue

import static org.testeditor.tcl.TclPackage.Literals.*

class TclJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension JvmTypesBuilder
	@Inject extension ModelUtil
	@Inject extension TclModelUtil
	@Inject TclAssertCallBuilder assertCallBuilder
	@Inject IQualifiedNameProvider nameProvider
	@Inject JvmModelHelper jvmModelHelper
	@Inject TclExpressionBuilder expressionBuilder
	@Inject WorkspaceRootHelper workspaceRootHelper

	def dispatch void infer(TclModel model, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		model.test?.infer(acceptor, isPreIndexingPhase)
		model.config?.infer(acceptor, isPreIndexingPhase)
	}

	/**
	 * Performs the minimal initialization to a class - its super type and
	 * its variables.
	 */
	private def JvmGenericType toClass(SetupAndCleanupProvider element, boolean isPreIndexingPhase) {
		if (isPreIndexingPhase) {
			return element.toClass(nameProvider.getFullyQualifiedName(element))
		} else {
			return element.toClass(nameProvider.getFullyQualifiedName(element)) [
				// Add super type to the element
				addSuperType(element)

				// Create variables for used fixture types
				members += createFixtureVariables(element)
			]
		}
	}

	/**
	 * First perform common operations like variable initialization and then dispatch to subclass specific operations.
	 */
	def dispatch void infer(SetupAndCleanupProvider element, IJvmDeclaredTypeAcceptor acceptor,
		boolean isPreIndexingPhase) {
		// Set package if not defined
		if (element instanceof TestCase) {
			updateNullPackageIn(element.model, element)
		}
		if (element instanceof TestConfiguration) {
			updateNullPackageIn(element.model, element)
		}
		// Create the class with eager initialization
		val generatedClass = element.toClass(isPreIndexingPhase)

		// Stuff that can be done in late initialization
		acceptor.accept(generatedClass) [
			documentation = '''Generated from «element.eResource.URI»'''

			// Create @Before method if relevant
			if (element.setup !== null) {
				members += element.createSetupMethod(envParams)
			}
			// Create @After method if relevant
			if (element.cleanup !== null) {
				members += element.createCleanupMethod(envParams)
			}

			// subclass specific operations
			infer(element)
		]
	}

	def updateNullPackageIn(TclModel model, SetupAndCleanupProvider element) {
		if (model.package == null) {
			model.package = getPackageFromFileSystem(element)
		}
	}

	def String getPackageFromFileSystem(SetupAndCleanupProvider element) {
		val path = new Path(EcoreUtil2.getPlatformResourceOrNormalizedURI(element).trimFragment.path).
			removeFirstSegments(1).removeLastSegments(2)
		val javaProject = JavaCore.create(workspaceRootHelper.root.getFile(path).project)
		val classpathEntries = javaProject.rawClasspath.filter[entryKind == IClasspathEntry.CPE_SOURCE]
		val cpEntry = classpathEntries.filter[it.path.isPrefixOf(path)].head
		val start = path.matchingFirstSegments(cpEntry.path)
		return path.removeFirstSegments(start).segments.join(".")
	}

	private def void addSuperType(JvmGenericType result, SetupAndCleanupProvider element) {
		if (element instanceof TestCase) {
			// Inherit from configuration, if set - need to be done before 
			if (element.config !== null) {
				result.superTypes += typeRef(element.config.toClass(false))
			}
		} // TODO allow explicit definition of super type in TestConfiguration
	}

	private def dispatch void infer(JvmGenericType result, TestConfiguration element) {
		result.abstract = true
	}

	private def dispatch void infer(JvmGenericType result, TestCase element) {
		// create variables for required environment variables
		val envParams = element.model.environmentVariables
		result.members += envParams.map [ environmentVariable |
			environmentVariable.toField(expressionBuilder.variableToVarName(environmentVariable), typeRef(String)) [
				initializer = '''System.getenv("«environmentVariable.name»")'''
			]
		]
		if (!envParams.empty) {
			result.members += element.toMethod('checkEnvironmentVariablesOnExistence', typeRef(Void.TYPE)) [
				exceptions += typeRef(Exception)
				annotations += annotationRef('org.junit.Before') // make sure that junit is in the classpath of the workspace containing the dsl
				body = [
					val output = trace(element, true)
					envParams.forEach[generateEnvironmentVariableAssertion(output)]
				]
			]
		}

		// Create test method
		result.members += element.toMethod('execute', typeRef(Void.TYPE)) [
			exceptions += typeRef(Exception)
			annotations += annotationRef('org.junit.Test') // make sure that junit is in the classpath of the workspace containing the dsl
			body = [element.generateMethodBody(trace(element, true), envParams)]
		]
	}

	/** 
	 * Creates variables for all used fixtures minus the ones already inherited
	 * from the super class. 
	 */
	private def Iterable<JvmField> createFixtureVariables(JvmGenericType type, SetupAndCleanupProvider element) {
		val fixtureTypes = element.fixtureTypes
		val accessibleSuperFieldTypes = jvmModelHelper.getAllAccessibleSuperTypeFields(type).map[it.type.type]
		val typesToInstantiate = fixtureTypes.filter[!accessibleSuperFieldTypes.contains(it)]
		return typesToInstantiate.map [ fixtureType |
			toField(element, fixtureType.fixtureFieldName, fixtureType.typeRef) [
				if (element instanceof TestConfiguration) {
					visibility = JvmVisibility.PROTECTED
				}
				initializer = '''new «fixtureType»()'''
			]
		]
	}

	private def JvmOperation createSetupMethod(SetupAndCleanupProvider container,
		Iterable<EnvironmentVariable> environmentVariables) {
		val setup = container.setup
		return setup.toMethod(container.setupMethodName, typeRef(Void.TYPE)) [
			exceptions += typeRef(Exception)
			annotations += annotationRef('org.junit.Before')
			body = [
				val output = trace(setup, true)
				setup.contexts.forEach[generateContext(output.trace(it), #[], environmentVariables)]
			]
		]
	}

	private def JvmOperation createCleanupMethod(SetupAndCleanupProvider container,
		Iterable<EnvironmentVariable> environmentVariables) {
		val cleanup = container.cleanup
		return cleanup.toMethod(container.cleanupMethodName, typeRef(Void.TYPE)) [
			exceptions += typeRef(Exception)
			annotations += annotationRef('org.junit.After')
			body = [
				val output = trace(cleanup, true)
				cleanup.contexts.forEach[generateContext(output.trace(it), #[], environmentVariables)]
			]
		]
	}

	private def String getSetupMethodName(SetupAndCleanupProvider container) {
		if (container instanceof TestConfiguration) {
			return 'setup' + container.name
		}
		return 'setup'
	}

	private def String getCleanupMethodName(SetupAndCleanupProvider container) {
		if (container instanceof TestConfiguration) {
			return 'cleanup' + container.name
		}
		return 'cleanup'
	}

	def void generateMethodBody(TestCase test, ITreeAppendable output,
		Iterable<EnvironmentVariable> environmentVariables) {
		test.steps.forEach[generate(output.trace(it), environmentVariables)]
	}

	private def void generateEnvironmentVariableAssertion(EnvironmentVariable environmentVariable,
		ITreeAppendable output) {
		output.
			append('''org.junit.Assert.assertNotNull(«expressionBuilder.variableToVarName(environmentVariable)»);''').
			newLine
	}

			private def void generate(SpecificationStepImplementation step, ITreeAppendable output,
				Iterable<EnvironmentVariable> environmentVariables) {
				val comment = '''/* «step.contents.restoreString» */'''
				output.newLine
				output.append(comment).newLine
				step.contexts.forEach[generateContext(output.trace(it), #[], environmentVariables)]
			}

			private def dispatch void generateContext(MacroTestStepContext context, ITreeAppendable output,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				output.newLine
				val macro = context.findMacroDefinition
				if (macro == null) {
					output.append('''// TODO Macro could not be resolved from «context.macroCollection.name»''').newLine
				} else {
					output.append('''// Macro start: «context.macroCollection.name» - «macro.template.normalize»''').
						newLine
					macro.contexts.forEach [
						generateContext(output.trace(it), #[context] + macroUseStack, environmentVariables)
					]
					output.newLine
					output.append('''// Macro end: «context.macroCollection.name» - «macro.template.normalize»''').
						newLine
				}
			}

			private def dispatch void generateContext(ComponentTestStepContext context, ITreeAppendable output,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				output.newLine
				output.append('''// Component: «context.component.name»''').newLine
				context.steps.forEach[generate(output.trace(it), macroUseStack, environmentVariables)]
			}

			protected def void generate(AbstractTestStep step, ITreeAppendable output,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				output.newLine
				if (step instanceof TestStep) {
					output.append('''// - «step.contents.restoreString»''').newLine
				}
				toUnitTestCodeLine(step, output, macroUseStack, environmentVariables)
			}

			/**
			 * @return all {@link JvmType} of all fixtures that are referenced.
			 */
			private def Set<JvmType> getFixtureTypes(SetupAndCleanupProvider element) {
				val contexts = newLinkedList
				if (element instanceof TestCase) {
					contexts += element.steps.map[it.contexts].flatten.filterNull
				}
				if (element.setup !== null) {
					contexts += element.setup.contexts
				}
				if (element.cleanup !== null) {
					contexts += element.cleanup.contexts
				}
				return contexts.map[testStepFixtureTypes].flatten.toSet
			}

			private def dispatch Set<JvmType> getTestStepFixtureTypes(ComponentTestStepContext context) {
				val interactionTypes = getAllInteractionTypes(context.component).toSet
				val fixtureTypes = interactionTypes.map[fixtureType].filterNull.toSet
				return fixtureTypes
			}

			private def dispatch Set<JvmType> getTestStepFixtureTypes(MacroTestStepContext context) {
				val macro = context.findMacroDefinition
				if (macro !== null) {
					return macro.contexts.filterNull.map[testStepFixtureTypes].flatten.toSet
				} else {
					return #{}
				}
			}

			private def String getFixtureFieldName(JvmType fixtureType) {
				return fixtureType.simpleName.toFirstLower
			}

			private def dispatch void toUnitTestCodeLine(AssertionTestStep step, ITreeAppendable output,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				output.append(assertCallBuilder.build(step.assertExpression)).newLine
			}

			private def dispatch void toUnitTestCodeLine(TestStep step, ITreeAppendable output,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				val interaction = step.interaction
				if (interaction !== null) {
					val fixtureField = interaction.defaultMethod?.typeReference?.type?.fixtureFieldName
					val operation = interaction.defaultMethod?.operation
					if (fixtureField !== null && operation !== null) {
						step.maybeCreateAssignment(operation, output)
						output.trace(interaction.defaultMethod) =>
							[
								val codeLine = '''«fixtureField».«operation.simpleName»(«getParameterList(step, interaction, macroUseStack, environmentVariables)»);'''
								append(codeLine) // please call with string, since tests checks against expected string which fails for passing ''' directly
							]
					} else {
						output.
							append('''// TODO interaction type '«interaction.name»' does not have a proper method reference''')
					}
				} else if (step.componentContext != null) {
					output.
						append('''// TODO could not resolve '«step.componentContext.component.name»' - «step.contents.restoreString»''')
				} else {
					output.append('''// TODO could not resolve unknown component - «step.contents.restoreString»''')
				}
			}

			private def void maybeCreateAssignment(TestStep step, JvmOperation operation, ITreeAppendable output) {
				if (step instanceof TestStepWithAssignment) {
					output.trace(step, TEST_STEP_WITH_ASSIGNMENT__VARIABLE, 0) => [
						// TODO should we use output.declareVariable here?
						// val variableName = output.declareVariable(step.variableName, step.variableName)
						val partialCodeLine = '''«operation.returnType.identifier» «step.variable.name» = '''
						output.append(partialCodeLine) // please call with string, since tests checks against expected string which fails for passing ''' directly
					]
				}
			}

			// TODO we could also trace the parameters here
			private def String getParameterList(TestStep step, InteractionType interaction,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {
				val mapping = getVariableToValueMapping(step, interaction.template)
				val stepContents = interaction.defaultMethod.parameters.map [ templateVariable |
					val stepContent = mapping.get(templateVariable)
					val stepContentResolved = if (stepContent instanceof VariableReference) {
							stepContent.resolveVariableReference(macroUseStack, environmentVariables)
						} else {
							stepContent
						}
					return stepContentResolved
				]
				val typedValues = newArrayList
				stepContents.forEach [ stepContent, i |
					val jvmParameter = interaction.getTypeOfFixtureParameter(i)
					typedValues += stepContent.generateCallParameters(jvmParameter, interaction)
				]
				return typedValues.join(', ')
			}

			/**
			 * generate the parameter-code passed to the fixture call depending on the type of the step content
			 */
			private def dispatch Iterable<String> generateCallParameters(StepContentElement stepContent,
				JvmTypeReference expectedType, InteractionType interaction) {
				val element = stepContent.componentElement
				val locator = '''"«element.locator»"'''
				if (interaction.defaultMethod.locatorStrategyParameters.size > 0) {
					// use element locator strategy if present, else use default of interaction
					val locatorStrategy = element.locatorStrategy ?: interaction.locatorStrategy
					return #[locator, locatorStrategy.qualifiedName] // locatorStrategy is the parameter right after locator (convention)
				} else {
					return #[locator]
				}
			}

			/**
			 * generate the parameter-code passed to the fixture call depending on the type of the step content
			 */
			private def dispatch Iterable<String> generateCallParameters(StepContentValue stepContentValue,
				JvmTypeReference expectedType, InteractionType interaction) {
				if (expectedType.qualifiedName == String.name) {
					return #['''"«StringEscapeUtils.escapeJava(stepContentValue.value)»"''']
				} else {
					return #[stepContentValue.value]
				}
			}

			/**
			 * generate the parameter-code passed to the fixture call depending on the type of the step content
			 */
			private def dispatch Iterable<String> generateCallParameters(VariableReference variableReference,
				JvmTypeReference expectedType, InteractionType interaction) {
				val result = expressionBuilder.buildExpression(variableReference)
				if (variableReference instanceof VariableReferenceMapAccess &&
					expectedType.qualifiedName == String.canonicalName) {
					return #[result + '.toString()'] // since the map is generic and thus the actual type is java.lang.Object
				} else {
					return #[result]
				}
			}

			/**
			 * resolve dereferenced variable (in macro) with call site value (recursively if necessary).
			 * 
			 * <pre>
			 * given the following scenario (this is just one example):
			 *   Tcl uses Macro A -> which again uses a Macro B -> which uses a component interaction
			 *   => referencedVariable is the variable name in the context of B
			 *    macroUseStack = #[ B, A ]   (call usage in reverse order)
			 *    environmentVariableReferences = required environment vars of tcl (if present)
			 * 
			 * wanted:
			 *   in order to get the parameter/value that should actually be passed to the
			 *   transitively called fixture method, the value/environment variable of the
			 *   original call site within the tcl must be found.
			 * 
			 *   as long as the the macroUseStack is not empty and the parameter used for the call
			 *   is again a variable reference, this method recursively calls itself:
			 *     the referencedVariable is decoded to the parameter name as it is used in the
			 *     enclosing macro call context and the top is poped off the stack
			 *  </pre>
			 * 
			 * @see org.testeditor.tcl.dsl.validation.TclParameterUsageValidatorTest
			 * 
			 */
			// TODO: There should be a sub class of StepContent, which functions as superclass to VariableReference, StepContentVariable   
			private def StepContent resolveVariableReference(VariableReference referencedVariable,
				Iterable<MacroTestStepContext> macroUseStack, Iterable<EnvironmentVariable> environmentVariables) {

				if (macroUseStack.empty || referencedVariable.variable instanceof AssignmentVariable) {
					// if the macroCallStack is empty, no further resolving is necessary
					// in case of an assignment variable, no resolving is necessary 
					return referencedVariable
				}

				val callSiteMacroContext = macroUseStack.head
				val macroCalled = callSiteMacroContext.findMacroDefinition
				val callSiteMacroTestStep = callSiteMacroContext.step

				if (callSiteMacroTestStep instanceof TestStep) {
					val varValMap = getVariableToValueMapping(callSiteMacroTestStep, macroCalled.template)
					val varKey = varValMap.keySet.findFirst [
						name.equals(referencedVariable.variable.name)
					]

					if (!varValMap.containsKey(
						varKey)) {
						throw new RuntimeException('''The referenced variable='«referencedVariable.variable.name»' cannot be resolved via macro parameters (macro call stack='«macroUseStack.map[findMacroDefinition.name].join('->')»').''')
					} else {
						val callSiteParameter = varValMap.get(varKey)

						if (callSiteParameter instanceof VariableReference) { // needs further variable resolving
							return callSiteParameter.resolveVariableReference(macroUseStack.tail,
								environmentVariables)
						} else {
							return callSiteParameter // could be a StepContentVariable
						}
					}
				} else {
					throw new RuntimeException('''Call site is of type='«callSiteMacroTestStep.class.canonicalName»' but should be of type='«TestStep.canonicalName»'.''')
				}
			}

		}
		