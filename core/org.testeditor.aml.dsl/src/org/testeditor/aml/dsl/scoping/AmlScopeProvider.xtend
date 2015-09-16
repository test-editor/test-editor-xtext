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
package org.testeditor.aml.dsl.scoping

import javax.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.xbase.scoping.batch.XbaseBatchScopeProvider
import org.testeditor.aml.model.ElementTypeWithInteractions
import org.testeditor.aml.model.ElementWithInteractions
import org.testeditor.aml.model.InteractionType
import org.testeditor.aml.model.MethodReference
import org.testeditor.aml.model.ModelUtil
import org.testeditor.aml.model.TemplateVariable
import org.testeditor.aml.model.ValueSpaceAssignment

import static org.testeditor.aml.model.ModelPackage.Literals.*

class AmlScopeProvider extends XbaseBatchScopeProvider {
	
	@Inject extension ModelUtil
	@Inject extension IQualifiedNameConverter
	
	@Inject MethodReferenceScopes methodReferenceScopes
	
	override getScope(EObject context, EReference reference) {
		if (reference == VALUE_SPACE_ASSIGNMENT__VARIABLE) {
			if (context instanceof ElementWithInteractions<?>) {
				return context.interactionsScope
			}
			if (context instanceof ValueSpaceAssignment) {
				return context.element.interactionsScope
			}
		}
		if (context instanceof MethodReference) {
			if (reference == METHOD_REFERENCE__OPERATION) {
				return methodReferenceScopes.getMethodReferenceScope(context, reference)
			} // else: TODO provide scope only for imported element
		}
		super.getScope(context, reference)
	}
	
	/**
	 * Provides the proper scope for template variables.
	 */
	def IScope getInteractionsScope(ElementWithInteractions<?> element) {
		if (element?.type === null) {
			return IScope.NULLSCOPE
		}
		val variables = element.type.templateVariablesInScope
		// Calculate a "partially qualified name" here to reference as InteractionType.variable
		return Scopes.scopeFor(variables, [ variable |
			val interactionType = variable.eContainer?.eContainer
			if (interactionType instanceof InteractionType) {
				return '''«interactionType.name».«variable.name»'''.toString.toQualifiedName
			}
			return null
		], IScope.NULLSCOPE)
	}
	
	/**
	 * @return the {@link TemplateVariable variables} that can be referenced from the passed type
	 */
	protected def Iterable<TemplateVariable> getTemplateVariablesInScope(ElementTypeWithInteractions type) {
		val templates = type.interactionTypes.map[template].filterNull
		val variables = templates.map[referenceableVariables].flatten
		return variables
	}
	
}