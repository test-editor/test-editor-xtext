/*******************************************************************************
 * Copyright (c) 2012 - 2018 Signal Iduna Corporation and others.
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
package org.testeditor.rcp4.views.tcltestrun.console

import javax.inject.Inject
import org.eclipse.ui.console.IConsoleFactory

class TCLConsoleFactory implements IConsoleFactory {

	@Inject
	ConsoleManagerProvider consoleManagerProvider

	override openConsole() {
		createAndShowConsole
	}

	def TCLConsole createAndShowConsole() {
		val consoleManager = consoleManagerProvider.getConsoleManager()
		val console = new TCLConsole()
		consoleManager.addConsoles(#[console])
		consoleManager.showConsoleView(console)
		return console
	}

}
