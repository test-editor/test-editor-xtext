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
package org.testeditor.tcl.dsl.tests.parser

import org.junit.Test
import org.testeditor.tcl.StepContentElement
import org.testeditor.tcl.TclPackage
import org.testeditor.tcl.TestStepWithAssignment
import org.testeditor.tsl.StepContentVariable

import static extension org.eclipse.xtext.nodemodel.util.NodeModelUtils.*

class TclModelParserTest extends AbstractParserTest {
	
	@Test
	def void parseMinimal() {
		// given
		val input = '''
			package com.example
		'''
		
		// when
		val model = parser.parse(input)
		
		// then
		model.package.assertEquals('com.example')
	}
	
	@Test
	def void parseSimpleSpecificationStep() {
		// given
		val input = '''
			package com.example
			
			# MyTest
			* Start the famous
			greetings application.
		'''
		
		// when
		val test = parse(input)
		
		// then
		test.name.assertEquals('MyTest')
		test.steps.assertSingleElement => [
			contents.restoreString.assertEquals('Start the famous greetings application')
		]
	}
	
	@Test
	def void parseSpecificationStepWithVariable() {
		// given
		val input = '''
			package com.example
			
			# Test
			* send greetings "Hello World" to the world.
		'''
		
		// when
		val test = parse(input)
		
		// then
		test.steps.assertSingleElement => [
			contents.restoreString.assertEquals('send greetings "Hello World" to the world')
			contents.get(2).assertInstanceOf(StepContentVariable) => [
				value.assertEquals('Hello World')
			]
		]		
	}
	
	@Test
	def void parseTestContextWithSteps() {
		// given
		val input = '''
			package com.example
			
			# Test
			* Start the famous greetings application
				Mask: GreetingsApplication
				- starte Anwendung "org.testeditor.swing.exammple.Greetings"
				- gebe in <Eingabefeld> den Wert "Hello World" ein.
		'''
		
		// when
		val test = parse(input)
		
		// then
		test.steps.assertSingleElement => [
			contexts.assertSingleElement => [
				val componentNode = findNodesForFeature(TclPackage.Literals.TEST_STEP_CONTEXT__COMPONENT).assertSingleElement
				componentNode.text.assertEquals('GreetingsApplication')
				steps.assertSize(2)
				steps.get(0) => [
					contents.restoreString.assertEquals('starte Anwendung "org.testeditor.swing.exammple.Greetings"')	
				]
				steps.get(1) => [
					contents.restoreString.assertEquals('gebe in <Eingabefeld> den Wert "Hello World" ein')
				]
			]
		]
	}
	
	@Test
	def void parseEmptyComponentElementReference() {
		// given
		val input = '''
			package com.example
			
			# Test
			* Dummy step
				Mask: Demo
				- <> < 	> <
				>
		'''
		
		// when
		val test = parse(input)
		
		// then
		test.steps.assertSingleElement.contexts.assertSingleElement => [
			val emptyReferences = steps.assertSingleElement.contents.assertSize(3)
			emptyReferences.forEach[
				assertInstanceOf(StepContentElement)
				value.assertNull
			]
		]
	}
	
	@Test
	def void parseTestStepWithVariableAssignmentSteps() {
		// given
		val input = '''
			package com.example
			
			# Test
			* Start
				Mask: Demo
				- hello = Lese den Text von <Input>
		'''
		
		// when
		val test = parse(input)
		
		// then
		test.steps.assertSingleElement => [
			contexts.assertSingleElement => [
				steps.assertSingleElement.assertInstanceOf(TestStepWithAssignment) => [
					variableName.assertEquals('hello')
					contents.restoreString.assertEquals('Lese den Text von <Input>')
				]
			]
		]
	}

}