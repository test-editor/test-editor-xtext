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
package org.testeditor.tcl.dsl.ui.labeling

import javax.inject.Inject
import org.eclipse.emf.edit.ui.provider.AdapterFactoryLabelProvider
import org.eclipse.xtext.xbase.ui.labeling.XbaseLabelProvider
import org.testeditor.tcl.TestStep
import org.testeditor.tcl.util.TclModelUtil
import org.testeditor.tsl.SpecificationStep
import org.testeditor.tcl.ComponentTestStepContext

class TclLabelProvider extends XbaseLabelProvider {

	@Inject
	extension TclModelUtil

	@Inject
	new(AdapterFactoryLabelProvider delegate) {
		super(delegate)
	}

	// Labels and icons can be computed like this:
	def text(ComponentTestStepContext context) {
		val component = context.component
		return "Component: " + (component.label ?: component.name)
	}

	def text(SpecificationStep specStep) {
		return specStep.contents.restoreString
	}

	def text(TestStep testStep) {
		return testStep.contents.restoreString
	}
}
