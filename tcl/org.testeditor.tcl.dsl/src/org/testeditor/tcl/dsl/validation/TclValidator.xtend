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
package org.testeditor.tcl.dsl.validation

import java.util.List
import java.util.Map
import java.util.Set
import javax.inject.Inject
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.util.TypeReferences
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xtype.XImportSection
import org.testeditor.aml.Template
import org.testeditor.aml.TemplateVariable
import org.testeditor.dsl.common.util.CollectionUtils
import org.testeditor.tcl.AEVariableReference
import org.testeditor.tcl.AssertionExpression
import org.testeditor.tcl.AssertionTestStep
import org.testeditor.tcl.BinaryAssertionExpression
import org.testeditor.tcl.ComponentTestStepContext
import org.testeditor.tcl.Macro
import org.testeditor.tcl.MacroTestStepContext
import org.testeditor.tcl.SpecificationStepImplementation
import org.testeditor.tcl.StepContentElement
import org.testeditor.tcl.StepContentVariableReference
import org.testeditor.tcl.TclModel
import org.testeditor.tcl.TclPackage
import org.testeditor.tcl.TestCase
import org.testeditor.tcl.TestStep
import org.testeditor.tcl.TestStepContext
import org.testeditor.tcl.TestStepWithAssignment
import org.testeditor.tcl.impl.AssertionTestStepImpl
import org.testeditor.tcl.util.TclModelUtil
import org.testeditor.tsl.SpecificationStep
import org.testeditor.tsl.StepContent
import org.testeditor.tsl.StepContentVariable
import org.testeditor.tsl.TslPackage

class TclValidator extends AbstractTclValidator {

	public static val NO_VALID_IMPLEMENTATION = 'noValidImplementation'
	public static val INVALID_NAME = 'invalidName'
	public static val INVALID_TYPED_VAR_DEREF = "invalidTypeOfVariableDereference"

	public static val UNKNOWN_NAME = 'unknownName'
	public static val INVALID_MAP_REF = 'invalidMapReference'
	public static val VARIABLE_UNKNOWN_HERE = 'varUnknownHere'
	public static val VARIABLE_ASSIGNED_MORE_THAN_ONCE = 'varAssignedMoreThanOnce'
	public static val UNALLOWED_VALUE = 'unallowedValue'
	public static val MISSING_FIXTURE = 'missingFixture'
	public static val MISSING_MACRO = 'missingMacro'
	public static val INVALID_VAR_DEREF = "invalidVariableDereference"
	public static val INVALID_MODEL_CONTENT = "invalidModelContent"

	@Inject extension TclModelUtil
	@Inject TypeReferences typeReferences
	@Inject extension CollectionUtils

	@Check
	def void tclHasOnlyTestCases(TclModel tclModel) {
		val fileExtension = tclModel.eResource.URI.fileExtension
		switch (fileExtension) {
			case "tcl":
				if (tclModel.macroCollection != null) {
					error("this file type may only contain test cases but it contains macro definitions",
						tclModel.macroCollection, null)
				}
			case "tml":
				if (tclModel.test != null) {
					error("this file type may only contain macro definitions but it contains test cases",
						tclModel.test, null)
				}
			default:
				throw new RuntimeException('''unknown file extension (fileExtensions='«fileExtension»')''')
		}
	}

	@Check
	def void referencesComponentElement(StepContentElement contentElement) {
		val component = contentElement.componentElement
		if (component === null) {
			error('No ComponentElement found.', contentElement, null)
		}
	}

	override checkImports(XImportSection importSection) {
		// ignore for now
	}

	@Check
	def checkMaskPresent(ComponentTestStepContext tsContext) {
		if (tsContext.component.eIsProxy) {
			warning("component/mask is not defined in aml", TclPackage.Literals.COMPONENT_TEST_STEP_CONTEXT__COMPONENT,
				UNKNOWN_NAME)
		}
	}

	@Check
	def checkFixtureMethodForExistence(TestStep testStep) {
		if (!(testStep instanceof AssertionTestStep) && testStep.hasComponentContext) {
			val method = testStep.interaction?.defaultMethod
			if ((method == null ) || (method.operation == null) || (method.typeReference?.type == null)) {
				info("test step could not resolve fixture", TclPackage.Literals.TEST_STEP__CONTENTS, MISSING_FIXTURE)
			}
		}
	}

	@Check
	def checkMacroCall(TestStep testStep) {
		if (testStep.hasMacroContext) {
			val normalizedTeststep = testStep.normalize
			val macroCollection = testStep.macroContext.macroCollection
			if (!macroCollection.macros.exists[template.normalize == normalizedTeststep]) {
				warning("test step could not resolve macro usage", TclPackage.Literals.TEST_STEP__CONTENTS,
					MISSING_MACRO)
			}
		}
	}

	@Check
	def checkMacroParameterUsage(Macro macro) {
		val templateParameterNames = macro.template.contents.filter(TemplateVariable).map[name].toSet
		macro.contexts.forEach [ context |
			context.checkAllVariableReferencesAreKnownParameters(templateParameterNames,
				"Dereferenced variable must be a template variable of the macro itself")
		]
	}

	/**
	 *  check that each variable references used is known as parameterName(s)
	 */
	def void checkAllVariableReferencesAreKnownParameters(TestStepContext context, Set<String> parameterNames,
		String errorMessage) {
		switch context {
			ComponentTestStepContext:
				context.steps.forEach [
					checkAllVariableReferencesAreKnownParameters(parameterNames, errorMessage)
				]
			MacroTestStepContext:
				context.step.checkAllVariableReferencesAreKnownParameters(parameterNames, errorMessage)
			default:
				throw new RuntimeException('''Unknown TestStepContextType '«context.class.canonicalName»'.''')
		}
	}

	/**
	 * check that each deref variable used is known as parameterName(s)
	 */
	private def checkAllVariableReferencesAreKnownParameters(TestStep step, Set<String> parameterNames,
		String errorMessage) {
		val erroneousIndexedStepContents = step.contents.indexed.filterValue(StepContentVariableReference).filter [
			!parameterNames.contains(value.variable.name)
		]
		erroneousIndexedStepContents.forEach [
			error(errorMessage, value.eContainer, value.eContainingFeature, key, INVALID_VAR_DEREF)
		]
	}

	/** 
	 * get the actual jvm types from the fixtures that are transitively used and to which this variable/parameter is passed to
	 */
	def dispatch Set<JvmTypeReference> getAllTypeUsagesOfVariable(MacroTestStepContext callingMacroTestStepContext,
		String variable) {
		val macroCalled = callingMacroTestStepContext.findMacroDefinition
		if (macroCalled != null) {
			val templateParamToVarRefMap = mapCalledTemplateParamToCallingVariableReference(
				callingMacroTestStepContext.step, macroCalled.template, variable)
			val calledMacroTemplateParameters = templateParamToVarRefMap.keySet.map[name].toSet
			val contextsUsingAnyOfTheseParameters = macroCalled.contexts.filter [
				makesUseOfVariablesViaReference(calledMacroTemplateParameters)
			]
			val typesOfAllParametersUsed = contextsUsingAnyOfTheseParameters.map [ context |
				context.getAllTypeUsagesOfVariables(calledMacroTemplateParameters)
			].flatten.toSet
			return typesOfAllParametersUsed
		} else {
			return #{}
		}
	}

	def Iterable<JvmTypeReference> getAllTypeUsagesOfVariables(TestStepContext context, Iterable<String> variables) {
		variables.map [ parameter |
			context.getAllTypeUsagesOfVariable(parameter)
		].flatten
	}

	def Map<TemplateVariable, StepContent> mapCalledTemplateParamToCallingVariableReference(TestStep callingStep,
		Template calledMacroTemplate, String callingVariableReference) {
		val varMap = getVariableToValueMapping(callingStep, calledMacroTemplate)
		return varMap.filter [ key, stepContent |
			stepContent.makesUseOfVariablesViaReference(#{callingVariableReference})
		]
	}

	/** 
	 * get the actual jvm types from the fixtures that are transitively used and to which this variable/parameter is passed to
	 */
	def dispatch Set<JvmTypeReference> getAllTypeUsagesOfVariable(ComponentTestStepContext componentTestStepContext,
		String variableReference) {
		val stepsUsingThisVariable = componentTestStepContext.steps.filter [
			contents.filter(StepContentVariableReference).exists[variable.name == variableReference]
		]
		val typesUsages = stepsUsingThisVariable.map [ step |
			step.stepVariableFixtureParameterTypePairs.filterKey(StepContentVariableReference).filter [
				key.variable.name == variableReference
			].map[value]
		].flatten.filterNull.toSet
		return typesUsages
	}

	/**
	 * does the given context make use of (one of the) variables passed via variable reference?
	 */
	private def boolean makesUseOfVariablesViaReference(TestStepContext context, Set<String> variables) {
		switch context {
			ComponentTestStepContext: context.steps.exists[contents.exists[makesUseOfVariablesViaReference(variables)]]
			MacroTestStepContext: context.step.contents.exists[makesUseOfVariablesViaReference(variables)]
			default: false
		}
	}

	/**
	 * does the given step make use of (one of the) variables passed via variable reference?
	 */
	private def boolean makesUseOfVariablesViaReference(StepContent stepContent, Set<String> variables) {
		if (stepContent instanceof StepContentVariableReference) {
			return variables.contains(stepContent.variable.name)
		}
		return false
	}

	@Check
	def void checkVariableUsageWithinAssertionExpressions(Macro macro) {
		val Map<String, String> varTypeMap = newHashMap
		macro.contexts.forEach[it.executeCheckVariableUsageWithinAssertionExpressions(varTypeMap)]
	}

	def dispatch void executeCheckVariableUsageWithinAssertionExpressions(
		ComponentTestStepContext componentTestStepContext, Map<String, String> varTypeMap) {
		executeTestStepCheckVariableUsageWithinAssertionExpressions(componentTestStepContext.steps, varTypeMap)
	}

	def dispatch void executeCheckVariableUsageWithinAssertionExpressions(MacroTestStepContext macroTestStepContext,
		Map<String, String> varTypeMap) {
		executeTestStepCheckVariableUsageWithinAssertionExpressions(#[macroTestStepContext.step], varTypeMap)
	}

	private def void executeTestStepCheckVariableUsageWithinAssertionExpressions(Iterable<TestStep> steps,
		Map<String, String> varTypeMap) {
		steps.forEach [ it, index |
			if (it instanceof TestStepWithAssignment) {
				// check "in order" (to prevent variable usage before assignment)
				if (varTypeMap.containsKey(variable.name)) {
					val message = '''Variable '«variable.name»' is assigned more than once.'''
					error(message, it, TclPackage.Literals.TEST_STEP_WITH_ASSIGNMENT__VARIABLE, index,
						VARIABLE_ASSIGNED_MORE_THAN_ONCE);
				} else {
					varTypeMap.put(variable.name, interaction.defaultMethod.operation.returnType.identifier)
				}
			} else if (it instanceof AssertionTestStepImpl) {
				executeCheckVariableUsageWithinAssertionExpressions(varTypeMap, index)
			}
		]
	}

	private def executeCheckVariableUsageWithinAssertionExpressions(AssertionTestStep step,
		Map<String, String> varTypeMap, int index) {
		step.expression.collectVariableUsage.forEach [
			if (!varTypeMap.containsKey(variable.name)) { // regular variable dereference
				val message = '''Variable «if(variable.name!=null){ '\''+variable.name+'\''}» is unknown here.'''
				error(message, eContainer, eContainingFeature, VARIABLE_UNKNOWN_HERE)
			} else if (key != null) { // dereference map with a key
				val typeIdentifier = varTypeMap.get(variable.name).replaceFirst("<.*", "")
				if (typeIdentifier.
					isNotAssignableToMap) {
					val message = '''Variable '«variable.name»' of type '«typeIdentifier»' does not implement '«Map.canonicalName»'. It cannot be used with key '«key»'.'''
					error(message, eContainer, eContainingFeature, INVALID_MAP_REF)
				}
			}
		]
	}

	private def isNotAssignableToMap(String typeIdentifier) {
		return !typeof(Map).isAssignableFrom(Class.forName(typeIdentifier))
	}

	private def Iterable<AEVariableReference> collectVariableUsage(AssertionExpression expression) {
		switch (expression) {
			BinaryAssertionExpression:
				return expression.left.collectVariableUsage + expression.right.collectVariableUsage
			AEVariableReference:
				return #[expression]
			default:
				return #[]
		}
	}

	@Check
	def checkValueInValueSpace(StepContentVariable stepContentVariable) {
		val valueSpace = stepContentVariable.valueSpaceAssignment?.valueSpace
		if (valueSpace !== null && !valueSpace.isValidValue(stepContentVariable.value)) {
			val message = '''Value is not allowed in this step. Allowed values: '«valueSpace»'.'''
			warning(message, TslPackage.Literals.STEP_CONTENT_VALUE__VALUE, UNALLOWED_VALUE);
		}
	}

	@Check
	def void checkSpec(TestCase testCase) {
		val specification = testCase.specification
		if (specification != null) {
			if (!specification.steps.matches(testCase.steps)) {
				val message = '''Test case does not implement its specification '«specification.name»'.'''
				warning(message, TclPackage.Literals.TEST_CASE__SPECIFICATION, NO_VALID_IMPLEMENTATION)
			}
		}
	}

	@Check
	def void checkVariableUsageWithinAssertionExpressions(TclModel tclModel) {
		val Map<String,String> varTypeMap = newHashMap
		tclModel.test.steps.map[contexts].flatten.forEach[executeCheckVariableUsageWithinAssertionExpressions(varTypeMap)]
	}

	private def boolean matches(List<SpecificationStep> specSteps,
		List<SpecificationStepImplementation> specImplSteps) {
		if (specSteps.size > specImplSteps.size) {
			return false
		}
		return specImplSteps.map[contents.restoreString].containsAll(specSteps.map[contents.restoreString])
	}

	@Check
	def void checkTestName(TclModel tclModel) {
		if (tclModel.test!=null && !getExpectedName(tclModel).equals(tclModel.name)) {
			val message = '''Test case name='«tclModel.name»' does not match expected name='«getExpectedName(tclModel)»' based on  filename='«tclModel.eResource.URI.lastSegment»'.'''
			error(message, TclPackage.Literals.TCL_MODEL__NAME, INVALID_NAME)
		}
		if (tclModel.macroCollection!=null && !getExpectedName(tclModel).equals(tclModel.name)) {
			val message = '''Macro collection does not match '«tclModel.eResource.URI.lastSegment»'.'''
			error(message, TclPackage.Literals.TCL_MODEL__NAME, INVALID_NAME)
		}
	}

	// @Check
	def void checkVariableReferenceUsage(TclModel tclModel) {
		val stringTypeReference = typeReferences.getTypeForName(String, tclModel)
		val environmentParams = tclModel.envParams.map[name].toSet
		val actualTypeMap = newHashMap
		environmentParams.forEach [
			actualTypeMap.put(it, #{stringTypeReference})
		]
		tclModel.test.steps.map[contexts].flatten.forEach [
			checkAllVariableReferencesAreKnownParameters(environmentParams,
				"Dereferenced variable must be a required environment variable")
			checkAllVariableReferencesOnTypeEquality(actualTypeMap)
		]
	}

	/**
	 * check that all deref variables are used according to their actual type (transitively in their fixture)
	 */
	private def void checkAllVariableReferencesOnTypeEquality(TestStepContext ctx,
		Map<String, Set<JvmTypeReference>> actualTypeMap) {
		switch ctx {
			ComponentTestStepContext: ctx.steps.forEach[checkAllVariableReferencesOnTypeEquality(actualTypeMap, ctx)]
			MacroTestStepContext: ctx.step.checkAllVariableReferencesOnTypeEquality(actualTypeMap, ctx)
			default: throw new RuntimeException('''Unknown TestStepContextType '«ctx.class.canonicalName»'.''')
		}
	}

	/**
	 * check that all deref variables are used according to their actual type (transitively in their fixture)
	 */
	private def void checkAllVariableReferencesOnTypeEquality(TestStep step, Map<String, Set<JvmTypeReference>> actualTypeMap,
		TestStepContext context) {
		val indexedVariables = step.contents.indexed.filter [
			value instanceof StepContentVariableReference || value instanceof StepContentVariable ||
				value instanceof StepContentElement
		]
		val derefVariables = indexedVariables.filter[value instanceof StepContentVariableReference]
		derefVariables.forEach [
			val varName=(value as StepContentVariableReference).variable.name
			val expectedTypeSet = context.getAllTypeUsagesOfVariable(varName)
			val actualTypeSet = actualTypeMap.get(varName)
			if (!expectedTypeSet.
				identicalSingleTypeInSet(
					actualTypeSet)) {
					error('''Environment variables can only be used for parameters of type '«actualTypeSet.map[qualifiedName].join(", ")»' (type expected = '«expectedTypeSet.map[qualifiedName].join(", ")»')''',
						value.eContainer, value.eContainingFeature, key, INVALID_TYPED_VAR_DEREF)
				}
			]
		}

		/**
		 * both sets hold only one type and this type is equal
		 */
		private def boolean identicalSingleTypeInSet(Set<JvmTypeReference> setA, Set<JvmTypeReference> setB) {
			setA.size == 1 && setB.size == 1 && setA.head.qualifiedName == setB.head.qualifiedName
		}

	}
	