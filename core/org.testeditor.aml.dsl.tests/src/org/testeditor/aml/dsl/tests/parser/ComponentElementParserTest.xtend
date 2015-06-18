package org.testeditor.aml.dsl.tests.parser

import org.junit.Test
import org.testeditor.aml.model.ComponentElement

/**
 * Parsing tests for {@link ComponentElement}.
 */
class ComponentElementParserTest extends AbstractParserTest {

	val typeName = "Button"

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
		#[withoutBrackets, withBrackets].map[parse(ComponentElement)].forEach [
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
		val element = input.parse(ComponentElement)

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
		val element = input.parse(ComponentElement)

		// Then
		element => [
			assertNoErrors
			locator.assertEquals("label::ok")
		]
	}
	
	protected def surroundWithComponentAndElementType(CharSequence element) '''
		component type Dialog
		component MyDialog is Dialog {
			«element»
		}
		element type «typeName»
	'''

}