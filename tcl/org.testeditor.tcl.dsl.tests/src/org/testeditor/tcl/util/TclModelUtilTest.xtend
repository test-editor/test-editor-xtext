package org.testeditor.tcl.util

import javax.inject.Inject
import org.junit.Test
import org.testeditor.aml.Template
import org.testeditor.tcl.dsl.tests.parser.AbstractParserTest
import org.testeditor.tcl.MacroTestStepContext
import org.testeditor.tcl.StepContentVariableReference
import org.testeditor.tcl.TestStep
import org.testeditor.tsl.StepContentVariable

class TclModelUtilTest extends AbstractParserTest {

	@Inject var TclModelUtil tclModelUtil // class under test

	@Test
	def void testRestoreString() {
		// given
		val testStep = parse('-  <hello>     world "ohoh"   @xyz', grammarAccess.testStepRule, TestStep)
		testStep.contents.get(3).assertInstanceOf(StepContentVariableReference)

		// when
		val result = tclModelUtil.restoreString(testStep.contents)

		// then
		result.assertMatches('<hello> world "ohoh" @') // empty variable reference name, since the reference is null
	}

	@Test
	def void testFindMacroDefinition() {
		// given
		val tmlModel = parse( '''
			package com.example
			
			# MyMacroCollection
			
			## MacroStartWith
			template = "start with" ${startparam}
			Component: MyComponent
			- put @startparam into <other>
			
			## MacroUseWith
			template = "use macro with" ${useparam}
			Macro: MyMacroCollection
			- start with @useparam
		''')
		val macroCalled = tmlModel.macroCollection.macros.head
		val macroCall = tmlModel.macroCollection.macros.last
		val macroTestStepContext = macroCall.contexts.head as MacroTestStepContext

		// when
		val macro = tclModelUtil.findMacroDefinition(macroTestStepContext)

		// then
		macro.assertSame(macroCalled)
	}

	@Test
	def void testNormalizeTemplate() {
		// given
		val template = parse('''
			"start with" ${somevar} "and more" ${othervar}
		''', grammarAccess.templateRule, Template)

		// when
		val normalizedTemplate = tclModelUtil.normalize(template)

		// then
		normalizedTemplate.assertEquals('start with "" and more ""')
	}

	@Test
	def void testNormalizeTestStep() {
		// given
		val testStep = parse('''
			- start with "some" and more @other
		''', grammarAccess.testStepRule, TestStep)

		// when
		val normalizedTestStep = tclModelUtil.normalize(testStep)

		// then
		normalizedTestStep.assertEquals('start with "" and more ""')
	}

	@Test
	def void testVariableToValueMapping() {
		// given
		val testStep = parse('''
			- start with "some" and more @other
		''', grammarAccess.testStepRule, TestStep)

		val template = parse('''
			"start with" ${somevar} "and more" ${othervar}
		''', grammarAccess.templateRule, Template)
		val somevar = template.contents.get(1)
		val othervar = template.contents.get(3)

		// when
		val varValueMap = tclModelUtil.getVariableToValueMapping(testStep, template)

		// then
		varValueMap.keySet.assertSize(2)
		varValueMap.get(somevar).assertInstanceOf(StepContentVariable).value.assertEquals("some")
		varValueMap.get(othervar).assertInstanceOf(StepContentVariableReference)
	}

}
