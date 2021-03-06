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
package org.testeditor.aml

import java.util.Set
import org.eclipse.xtext.common.types.JvmType
import org.eclipse.xtext.common.types.JvmTypeReference

class ModelUtil {

	// TODO implement hasParentsCycle and test!
	public static final String TEMPLATE_VARIABLE_ELEMENT = "element"

	/**
	 * Checks whether the {@link Component}'s parent hierarchy
	 * contains a cycle or not.
	 */
	def boolean hasParentsCycle(Component component) {
		return false
	}

	def Set<ComponentType> getTypes(Component component) {
		val result = newHashSet
		component.collectTypes(result)
		return result
	}

	private def void collectTypes(Component component, Set<ComponentType> result) {
		if (component.type !== null) {
			result += component.type
		}
		component.parents.forEach[collectTypes(result)]
	}

	/**
	 * @return all interaction types of the {@link Component} as well as its elements.
	 */
	def Set<InteractionType> getAllInteractionTypes(Component component) {
		if (component !== null) {
			return (component.componentInteractionTypes + component.componentElementsInteractionTypes).toSet
		}
		return emptySet
	}

	/**
	 * @return all interaction types of the {@link Component}.
	 */
	def Set<InteractionType> getComponentInteractionTypes(Component component) {
		return component.types.map[interactionTypes].flatten.toSet
	}

	/**
	 * @return all component elements of the {@link Component} including the elements through component inclusion.
	 */
	def Set<ComponentElement> getComponentElements(Component component) {
		return (component.elements + component.parents.map[componentElements].flatten).toSet
	}

	/**
	 * @return all interaction types of the component's elements.
	 */
	def Set<InteractionType> getComponentElementsInteractionTypes(Component component) {
		val componentElements = component.componentElements
		return componentElements.map[componentElementInteractionTypes].flatten.toSet
	}

	/**
	 * @return all interaction types of a {@link ComponentElement}.
	 */
	def Set<InteractionType> getComponentElementInteractionTypes(ComponentElement element) {
		return element.type.interactionTypes.toSet
	}

	/**
	 * @return all {@link TemplateVariable variables} that can be referenced
	 * 	from the outside, i.e. have a name that is not "element"
	 */
	def Set<TemplateVariable> getReferenceableVariables(Template template) {
		if (template !== null) {
			return template.contents.filter(TemplateVariable).filter [
				!name.nullOrEmpty && name != TEMPLATE_VARIABLE_ELEMENT
			].toSet
		} else {
			return emptySet
		}
	}

	/**
	 * @return the fixture type if the given interaction type (may be null!)
	 */
	def JvmType getFixtureType(InteractionType interactionType) {
		return interactionType?.defaultMethod?.typeReference?.type
	}

	/**
	 * @return the type of the parameter of the fixture of the given interaction at position index (if present)
	 */
	def JvmTypeReference getTypeOfFixtureParameter(InteractionType interaction, int index) {
		val jvmParameters = interaction.defaultMethod.operation.parameters
		if (jvmParameters.size > index) {
			return jvmParameters.get(index).parameterType
		} else {
			return null
		}
	}

	/**
	 * @return the type returned by the fixture of the given interaction (may be null)
	 */
	def JvmTypeReference getReturnType(InteractionType interaction) {
		interaction.defaultMethod?.operation?.returnType
	}

	def String normalize(Template template) {
		val normalizedTemplate = template.contents.map [
			switch (it) {
				TemplateVariable case name == 'element': '<>'
				TemplateVariable: '""'
				TemplateText: value.trim
			}
		].join(' ').removeWhitespaceBeforePunctuation
		return normalizedTemplate
	}

	def String removeWhitespaceBeforePunctuation(String input) {
		return input.replaceAll('''\s+(\.|\?)''', "$1")
	}


}
