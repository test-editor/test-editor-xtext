package org.testeditor.rcp4.product

import org.eclipse.jface.action.IMenuManager
import org.eclipse.ui.IWorkbenchWindow
import org.eclipse.ui.application.ActionBarAdvisor
import org.eclipse.ui.application.IActionBarConfigurer

/** dummy class */
class ApplicationActionBarAdvisor extends ActionBarAdvisor {
	new(IActionBarConfigurer configurer) {
		super(configurer)
	}

	override makeActions(IWorkbenchWindow window) {
	}

	override fillMenuBar(IMenuManager menuBar) {
	}
}
