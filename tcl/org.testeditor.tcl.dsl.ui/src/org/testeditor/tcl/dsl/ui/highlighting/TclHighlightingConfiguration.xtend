package org.testeditor.tcl.dsl.ui.highlighting

import org.eclipse.swt.SWT
import org.eclipse.swt.graphics.FontData
import org.eclipse.swt.graphics.RGB
import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultHighlightingConfiguration
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfigurationAcceptor
import org.eclipse.xtext.ui.editor.utils.TextStyle

import static org.testeditor.tcl.dsl.ide.highlighting.TclSemanticHighlightingCalculator.*

class TclHighlightingConfiguration extends DefaultHighlightingConfiguration {

	override configure(IHighlightingConfigurationAcceptor acceptor) {
		super.configure(acceptor)
		acceptor.acceptDefaultHighlighting(TEST_CASE_NAME, "TestCase Name", testCaseName)
		acceptor.acceptDefaultHighlighting(COMPONENT_ELEMENT_REFERENCE, "Component Element Reference",
			componentElementReference)
	}

	def TextStyle testCaseName() {
		return defaultTextStyle.copy => [
			color = new RGB(87, 195, 192)
			fontData = #[new FontData('Arial', 18, SWT.BOLD)]
		]
	}

	def TextStyle componentElementReference() {
		return commentTextStyle.copy
	}

}