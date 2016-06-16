package org.testeditor.tml.dsl.tests.formatter

import org.junit.Test

class MacroFormatterTest extends AbstractTmlFormatterTest {

	val prefix = '''
		package com.example
		
		import a.b.c
		import c.d.e
		
		# MacroCollection
		
	'''

	@Test
	def void formatLineBreaks() {
		formatterTester.assertFormatted [
			expectation = prefix + '''
				## SomeMacro
				template = "do this" ${element} "and that" ${var}
				Component: some
				
				## OtherMacro
				template = "ok" ${element}
				Macro: MacroCollection
				- dos this @element and "some" that @element
			'''

			toBeFormatted = prefix + '''
				##
				SomeMacro
				template
				=
				"do this"
				${element}
				"and that"
				${var}
				Component
				:
				some
				##
				OtherMacro
				template
				=
				"ok"
				${element}
				Macro
				:
				MacroCollection
				-
				dos
				this
				@
				element
				and
				"some"
				that
				@
				element
			'''
		]
	}

	@Test
	def void formatWhitespaces() {
		formatterTester.assertFormatted [
			expectation = prefix + '''
				## SomeMacro
				template = "do this" ${element} "and that" ${var}
				Component: some
				
				## OtherMacro
				template = "ok" ${element}
				Macro: MacroCollection
				- dos this @element and "some" that @element
			'''

			toBeFormatted = prefix + '''
					  ##    SomeMacro   template 	= 	  "do this" 
				 ${element} 	  "and that" 	  ${var}	  	Component      :     some    
				  	 ##OtherMacro		template = "ok" ${element}    Macro   
				  	   :   MacroCollection  	- dos
				this    @    element     and    "some"    that    @element
			'''
		]
	}
}
