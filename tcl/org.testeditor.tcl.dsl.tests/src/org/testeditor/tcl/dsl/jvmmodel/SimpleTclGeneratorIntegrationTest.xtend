package org.testeditor.tcl.dsl.jvmmodel

import org.junit.Test

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

			interaction type getList {
				template = "Lese Liste von" ${element}
				method = «DummyFixture.simpleName».getList(element)
			}
			
			element type Label{
				interactions = getList
			}
						
			component GreetingApplication is Application {
				element bar is Label {
					label = "Label"
					locator = "label.greet"
				}
			}
		'''
		val tcl = '''
			package com.example
			
			# SimpleTest
			* Start the famous greetings application
				Mask: GreetingApplication
				- Starte Anwendung "org.testeditor.swing.exammple.Greetings"
				- foo = Lese Liste von <bar>
				- Stoppe Anwendung
			
			* Do something different
		'''
		val amlModel = amlParseHelper.parse(aml, resourceSet)
		val tclModel = tclParseHelper.parse(tcl, 'SimpleTest.tcl'.createFileURI, resourceSet)
		amlModel.assertNoErrors
		tclModel.assertNoErrors

		// when
		val obj = generate(tclModel)

		// then
		println(obj)
	}

}