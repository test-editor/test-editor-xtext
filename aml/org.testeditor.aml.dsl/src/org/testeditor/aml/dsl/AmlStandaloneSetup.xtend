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
package org.testeditor.aml.dsl

import org.eclipse.emf.ecore.EPackage
import org.testeditor.aml.AmlPackage

/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class AmlStandaloneSetup extends AmlStandaloneSetupGenerated {

	def static void doSetup() {
		new AmlStandaloneSetup().createInjectorAndDoEMFRegistration
	}

	override createInjectorAndDoEMFRegistration() {
		EPackage.Registry.INSTANCE.putIfAbsent(AmlPackage.eNS_URI, AmlPackage.eINSTANCE)
		return super.createInjectorAndDoEMFRegistration
	}
}
