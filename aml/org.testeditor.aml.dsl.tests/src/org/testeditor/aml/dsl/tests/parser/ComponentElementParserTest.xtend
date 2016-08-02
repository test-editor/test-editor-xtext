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
package org.testeditor.aml.dsl.tests.parser

import javax.inject.Inject
import org.junit.Before
import org.junit.Test
import org.testeditor.aml.ComponentElement
import org.testeditor.dsl.common.testing.ResourceSetHelper

/**
 * Parsing tests for {@link ComponentElement}.
 */
class ComponentElementParserTest extends AbstractParserTest {

	val typeName = "Button"

	@Inject extension ResourceSetHelper
	
	@Before
	def void setUp() {
		setUpResourceSet
	}

	@Test
	def void parseMinimal() {
		// Given
		val withoutBrackets = '''
			element MyButton is «typeName»
		'''.surroundWithComponentAndElementType
		val withBrackets = '''
			element MyButton is «typeName» {
			}
		'''.surroundWithComponentAndElementType

		// When + Then
		#[withoutBrackets, withBrackets].map[parse(ComponentElement,resourceSet)].forEach [
			assertNoErrors
			name.assertEquals("MyButton")
			type.assertNotNull.name.assertEquals(typeName)
		]
	}

	@Test
	def void parseWithLabel() {
		// Given
		val input = '''
			element MyButton is «typeName» {
				label = "OK"
			}
		'''.surroundWithComponentAndElementType

		// When
		val element = input.parse(ComponentElement, resourceSet)

		// Then
		element => [
			assertNoErrors
			label.assertEquals("OK")
		]
	}
	
	@Test
	def void parseWithLocator() {
		// Given
		val input = '''
			element MyButton is «typeName» {
				locator = "label::ok"
			}
		'''.surroundWithComponentAndElementType

		// When
		val element = input.parse(ComponentElement, resourceSet)

		// Then
		element => [
			assertNoErrors
			locator.assertEquals("label::ok")
		]
	}

	@Test
	def void parseWithLocatorStrategy() {
		// Given
		val input = '''
			element MyButton is «typeName» {
				locator = "OK_ID"
				locatorStrategy = ID
			}
		'''.surroundWithComponentAndElementType

		// When
		val element = input.parse(ComponentElement, resourceSet)

		// Then
		element => [
			assertNoErrors
			locator.assertEquals("OK_ID")
			locatorStrategy.simpleName.assertEquals("ID")
		]
	}

	protected def surroundWithComponentAndElementType(CharSequence element) '''
		import org.testeditor.dsl.common.testing.DummyLocatorStrategy

		component type Dialog
		component MyDialog is Dialog {
			«element»
		}
		element type «typeName»
	'''

}
