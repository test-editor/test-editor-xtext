package org.testeditor.tml.dsl.tests

import javax.inject.Inject
import org.eclipse.xtext.xtype.XtypeFactory
import org.testeditor.aml.Component
import org.testeditor.aml.Template
import org.testeditor.aml.TemplateVariable
import org.testeditor.aml.impl.AmlFactoryImpl
import org.testeditor.tml.ComponentTestStepContext
import org.testeditor.tml.Macro
import org.testeditor.tml.MacroTestStepContext
import org.testeditor.tml.TestStep
import org.testeditor.tml.TmlModel
import org.testeditor.tml.impl.TmlFactoryImpl
import org.testeditor.tsl.impl.TslFactoryImpl
import org.testeditor.tml.MacroCollection

class TmlModelGenerator {
	@Inject TmlFactoryImpl tmlFactory
	@Inject protected AmlFactoryImpl amlFactory
	@Inject protected TslFactoryImpl tslFactory
	@Inject protected XtypeFactory xtypeFactory

	def TmlModel tmlModel(String macroCollectionName) {
		return tmlFactory.createTmlModel => [
			macroCollection = tmlFactory.createMacroCollection => [name = macroCollectionName]
			^package = "com.example"
		]
	}

	def TmlModel withImportNamespace(TmlModel me, String namespace) {
		if (me.importSection == null) {
			me.importSection = xtypeFactory.createXImportSection
		}
		me.importSection.importDeclarations += xtypeFactory.createXImportDeclaration => [
			it.importedNamespace = namespace
		]
		return me
	}

	def Macro macro(String macroName) {
		return tmlFactory.createMacro => [name = macroName]
	}

	def TestStep testStep(String ... texts) {
		return tmlFactory.createTestStep.withText(texts)
	}

	def TestStep withElement(TestStep me, String elementName) {
		me.contents+=tmlFactory.createStepContentElement => [
			value = elementName
		]
		return me
	}

	def TestStep withVariableReference(TestStep me, String variableReferenceName) {
		me.contents += tmlFactory.createStepContentVariableReference => [
			variable = amlFactory.createTemplateVariable => [
				name = variableReferenceName
			]
		]
		return me
	}

	def TestStep withParameter(TestStep me, String parameter) {
		me.contents += tslFactory.createStepContentVariable => [value = parameter]
		return me
	}

	def TestStep withText(TestStep me, String ... texts) {
		return me => [
			texts.forEach[text|contents += tslFactory.createStepContentText => [value = text]]
		]
	}

	def MacroTestStepContext macroTestStepContext(MacroCollection macroCollection) {
		return tmlFactory.createMacroTestStepContext => [it.macroCollection = macroCollection]
	}

	def ComponentTestStepContext componentTestStepContext(Component referencedComponent) {
		return tmlFactory.createComponentTestStepContext => [
			component = referencedComponent
		]
	}

}
