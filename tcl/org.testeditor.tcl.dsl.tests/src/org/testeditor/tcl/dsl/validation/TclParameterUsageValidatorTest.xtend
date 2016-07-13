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

import com.google.inject.Provider
import java.util.UUID
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.eclipse.xtext.resource.XtextResourceSet
import org.junit.Before
import org.junit.Test
import org.testeditor.aml.AmlModel
import org.testeditor.aml.Component
import org.testeditor.aml.dsl.AmlStandaloneSetup
import org.testeditor.aml.dsl.tests.AmlModelGenerator
import org.testeditor.dsl.common.testing.DummyFixture
import org.testeditor.tcl.TclModel
import org.testeditor.tcl.dsl.tests.TclModelGenerator
import org.testeditor.tcl.dsl.tests.parser.AbstractParserTest
import org.testeditor.tml.Macro
import org.testeditor.tml.TmlModel
import org.testeditor.tml.dsl.TmlStandaloneSetup

import static org.testeditor.tml.TmlPackage.Literals.*
import org.testeditor.aml.dsl.tests.common.AmlTestModels

class TclParameterUsageValidatorTest extends AbstractParserTest {
	@Inject TclValidator tclValidator // class under test
	@Inject protected Provider<XtextResourceSet> resourceSetProvider
	@Inject protected XtextResourceSet resourceSet
	@Inject ValidationTestHelper validator

	protected ParseHelper<AmlModel> amlParseHelper
	protected ParseHelper<TmlModel> tmlParseHelper

	var Component dummyComponent

	@Inject extension TclModelGenerator
	@Inject extension AmlModelGenerator
	@Inject AmlTestModels amlTestModels

	@Before
	def void setup() {
		resourceSet = resourceSetProvider.get
		resourceSet.classpathURIContext = this
		val injector = (new AmlStandaloneSetup).createInjectorAndDoEMFRegistration
		amlParseHelper = injector.getInstance(ParseHelper)
		val tmlInjector = (new TmlStandaloneSetup).createInjectorAndDoEMFRegistration
		tmlParseHelper = tmlInjector.getInstance(ParseHelper)

		// build component "Dummy" with two interactions, "start" with a string parameter, "wait" with a long parameter
		val amlModel = amlTestModels.dummyComponent(resourceSet) => [
			interactionTypes += interactionType("wait") => [
				defaultMethod = methodReference(resourceSet, DummyFixture, "waitSeconds", "secs")
				template = template("wait").withParameter(defaultMethod.parameters.head)
			]
		]
		amlModel.componentTypes.findFirst[name == amlTestModels.COMPONENT_TYPE_NAME] => [
			interactionTypes += amlModel.interactionTypes.findFirst[name == "wait"]
		]
		amlModel.register("aml")

		dummyComponent = amlModel.components.findFirst[name == amlTestModels.COMPONENT_NAME]
	}

	@Test
	def void testDirectCallVariableTypeChecks() {
		val tmlModel = tmlModel("MacroCollection") => [
			// macro calls (directly) the aml interaction "start" (which expects the parameter to be of type String)
			macroCollection.macros += macro("MyCallMacro") => [
				template = template("mycall").withParameter("appname")
				contexts += componentTestStepContext(dummyComponent) => [
					steps += testStep("start").withVariableReference("appname")
				]
			]
			// macro calls (directly) the aml interaction "wait" (which expects the parameter to be of type long)
			macroCollection.macros += macro("OtherCallMacro") => [
				template = template("othercall").withParameter("secs")
				contexts += componentTestStepContext(dummyComponent) => [
					steps += testStep("wait").withVariableReference("secs")
				]
			]
		]
		tmlModel.register("tml")

		val tclModel = tclModel => [
			environmentVariableReferences += envVariables("envVar", "myEnvString")
			test = testCase("MyTest") => [
				// use macro "mycall" using env param (no error, since type String is provided and String is expected)
				steps += specificationStep("test", "something") => [
					contexts += macroTestStepContext(tmlModel.macroCollection) => [
						step = testStep("mycall").withVariableReference("myEnvString")
					]
				]
				// use macro "othercall" using env param (error expected, since type String is provided and long is expected)
				steps += specificationStep("test", "other") => [
					contexts += macroTestStepContext(tmlModel.macroCollection) => [
						step = testStep("othercall").withVariableReference("envVar")
					]
				]
			]
		]
		tclModel.register("tcl")

		val somethingContext = tclModel.test.steps.head.contexts.head
		val otherContext = tclModel.test.steps.last.contexts.head

		// when
		val setWithString = tclValidator.getAllTypeUsagesOfVariable(somethingContext, "myEnvString")
		val setWithLong = tclValidator.getAllTypeUsagesOfVariable(otherContext, "envVar")

		// then
		setWithString.assertSize(1)
		setWithString.head.simpleName.assertEquals(String.simpleName)

		setWithLong.assertSize(1)
		setWithLong.head.simpleName.assertEquals(long.simpleName)

		validator.assertError(tclModel, TEST_STEP, TclValidator.INVALID_TYPED_VAR_DEREF)
	}

	@Test
	def void testIndirectCallVariableTypeChecks() {
		// given
		val tmlModel = tmlModel("MacroCollection")
		tmlModel => [
			// calls macro "othercall" with one parameter "unknown" (which is expected to be of type long)
			macroCollection.macros += macro("MyCallMacro") => [
				template = template("mycall").withParameter("unknown")
				contexts += macroTestStepContext(tmlModel.macroCollection) => [
					step = testStep("othercall").withVariableReference("unknown")
				]
			]
			macroCollection.macros += macro("OtherCallMacro") => [
				template = template("othercall").withParameter("secs")
				contexts += componentTestStepContext(dummyComponent) => [
					steps += testStep("wait").withVariableReference("secs") // secs are expected to be of type long in aml fixture
				]
			]
		]
		tmlModel.register("tml")

		// call "mycall" with env parameter (which is of type String, transitively expected is type long) ...
		val tclModel = tclCallingMyCallMacroWithOneEnvParam("myEnvString", tmlModel)

		val myCallContext = tclModel.test.steps.head.contexts.head

		// when
		val setWithLong = tclValidator.getAllTypeUsagesOfVariable(myCallContext, "myEnvString")

		// then
		setWithLong.assertSize(1)
		setWithLong.head.simpleName.assertEquals(long.simpleName)
		validator.assertError(tclModel, TEST_STEP, TclValidator.INVALID_TYPED_VAR_DEREF)
	}

	@Test
	def void testIndirectCallVariableWithMultipleUsageTypeChecks() {
		// given
		val tmlModel = tmlModel("MacroCollection")
		tmlModel => [
			macroCollection.macros += otherCallMacroWithTwoParamsWithTypeLongAndStringRespectively
			// calls macro "othercall" with parameter "unknown" as first and second parameter (which are expected to be of type long and String)
			macroCollection.macros += macro("MyCallMacro") => [
				template = template("mycall").withParameter("unknown")
				contexts += macroTestStepContext(tmlModel.macroCollection) => [
					step = testStep("othercall").withVariableReference("unknown").withText("with").
											withVariableReference("unknown")
				]
			]
		]
		tmlModel.register("tml")

		// since tcl calls mycall Macro with environment variable (which always has type String)
		// and this parameter is transitively used for calls in the aml expecting long and String ...
		val tclModel = tclCallingMyCallMacroWithOneEnvParam("myEnvString", tmlModel)

		val myCallContext = tclModel.test.steps.head.contexts.head

		// when
		val setWithLong = tclValidator.getAllTypeUsagesOfVariable(myCallContext, "myEnvString")

		// then
		setWithLong.assertSize(2)
		setWithLong.map[simpleName].toList => [
			contains(long.simpleName) // one usage expects type long
			contains(String.simpleName) // one usage expects type String
		]
		validator.assertError(tclModel, TEST_STEP, TclValidator.INVALID_TYPED_VAR_DEREF) // since environment variables are of type String, report invalid usage
	}

	@Test
	def void testIndirectCallValidation() {
		// given + when
		val tmlModel = tmlModel("MacroCollection")
		tmlModel => [
			macroCollection.macros += otherCallMacroWithTwoParamsWithTypeLongAndStringRespectively
			// calls macro "othercall" with parameter "3" and "unknown" (which will satisfy the expected types long and String)
			macroCollection.macros += macro("MyCallMacro") => [
				template = template("mycall").withParameter("unknown")
				contexts += macroTestStepContext(tmlModel.macroCollection) => [
					step = testStep("othercall").withParameter("3").withText("with").withVariableReference("unknown")
				]
			]
		]
		tmlModel.register("tml")
		// since tcl calls mycall Macro with environment variable (which always has type String)
		// and this parameter is transitively used for calls expecting type String ... (no errors expected)
		val tclModel = tclCallingMyCallMacroWithOneEnvParam("myEnvString", tmlModel)

		// then
		validator.assertNoError(tclModel, TclValidator.INVALID_TYPED_VAR_DEREF)
		validator.assertNoError(tclModel, TclValidator.INVALID_VAR_DEREF)
	}

	private def Macro otherCallMacroWithTwoParamsWithTypeLongAndStringRespectively() {
		return macro("OtherCallMacro") => [
			template = template("othercall").withParameter("secs").withText("with").withParameter("strParam")
			contexts += componentTestStepContext(dummyComponent) => [
				steps += testStep("wait").withVariableReference("secs")
				steps += testStep("start").withVariableReference("strParam")
			]
		]
	}

	private def TclModel tclCallingMyCallMacroWithOneEnvParam(String envVar, TmlModel tmlModel) {
		val tclModel = tclModel => [
			environmentVariableReferences += envVariables(envVar)
			test = testCase("MyTest") => [
				steps += specificationStep("test", "something") => [
					contexts += macroTestStepContext(tmlModel.macroCollection) => [
						step = testStep("mycall").withVariableReference(envVar)
					]
				]
			]
		]
		tclModel.register("tcl")
		return tclModel
	}

	/** 
	 * register the given model with the resource set (for cross linking)
	 */
	private def <T extends EObject> T register(T model, String fileExtension) {
		val uri = URI.createURI(UUID.randomUUID.toString + "." + fileExtension)

		val newResource = resourceSet.createResource(uri)
		newResource.getContents().add(model)
		return model
	}

}
