package org.testeditor.tcl.dsl.jvmmodel

import org.junit.Test
import org.testeditor.fixture.dummy.DummyFixture

import static extension org.eclipse.emf.common.util.URI.createFileURI

class SimpleTclGeneratorIntegrationTest extends AbstractTclGeneratorIntegrationTest {

	@Test
	def void test() {
		// given
		val aml = '''
			package com.example
			
			import «DummyFixture.name»
			
			component type Application {
				interactions = start, stop
			}
			 
			interaction type start {
				template = "Starte Anwendung" ${path}
				method = «DummyFixture.simpleName».startApplication(path)
			}
			interaction type stop {
				template = "Stoppe Anwendung"
				method = «DummyFixture.simpleName».stopApplication
			}
			 
			interaction type getValue {
				template = "Lese Wert von" ${element}
				method = «DummyFixture.simpleName».getValue(element)
			}
			 
			interaction type setValue {
				template = "Setze Wert von" ${element} "auf" ${value} "."
				method = «DummyFixture.simpleName».setValue(element, value)
			}
			component GreetingApplication is Application
		'''
		val tcl = '''
			package com.example
			
			* Start the famous greetings application
				Mask: GreetingApplication
				- Starte Anwendung "org.testeditor.swing.exammple.Greetings"
				- Stoppe Anwendung
			
			* Do something different
		'''
		val amlModel = amlParseHelper.parse(aml, resourceSet)
		val tclModel = tclParseHelper.parse(tcl, 'SimpleTest.tcl'.createFileURI, resourceSet)
		validationHelper.assertNoErrors(amlModel)
		validationHelper.assertNoErrors(tclModel)

		// when
		val obj = generate(tclModel)

		// then
		println(obj)
	}

}