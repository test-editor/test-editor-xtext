/*******************************************************************************
 * Copyright (c) 2012 - 2015 Signal Iduna Corporation and others.
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
package org.testeditor.tsl.dsl.naming

import javax.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.DefaultDeclarativeQualifiedNameProvider
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.testeditor.tsl.TslModel
import org.testeditor.tsl.util.TslModelUtil

class TslQualifiedNameProvider extends DefaultDeclarativeQualifiedNameProvider {
	
	@Inject extension IQualifiedNameConverter
	@Inject extension TslModelUtil
	
	override getFullyQualifiedName(EObject obj) {
		if (obj instanceof TslModel) {
			if (obj.package.nullOrEmpty) {
				return obj.name.toQualifiedName
			} else {
				return '''«obj.package».«obj.name»'''.toString.toQualifiedName
			}
		}
		return super.getFullyQualifiedName(obj)
	}
	
}