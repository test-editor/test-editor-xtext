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
package org.testeditor.dsl.common.ui.wizards

import javax.inject.Inject

class NewTslFileWizard extends NewFileWizard {

	@Inject NewFileWizardPage tslPage

	override String getContainerName() {
		tslPage.containerName
	}

	override String getFileName() {
		tslPage.fileName
	}

	override void addPages() {
		tslPage.init(selection, "New Tsl File", "This wizard creates a new file with *.tsl extension.", "tsl")
		addPage(tslPage)
	}

	override String contentString(String thePackage, String fileName) {
		return '''
			package «thePackage ?: "com.example"»
			
			# «fileName.replace(".tsl","").toFirstUpper»
		'''
	}
}
