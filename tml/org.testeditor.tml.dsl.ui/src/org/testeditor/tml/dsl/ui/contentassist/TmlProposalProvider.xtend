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
package org.testeditor.tml.dsl.ui.contentassist

import javax.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.testeditor.aml.ModelUtil
import org.testeditor.tml.TestStep
import org.testeditor.tml.util.TmlModelUtil

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class TmlProposalProvider extends AbstractTmlProposalProvider {
	@Inject extension ModelUtil
	@Inject extension TmlModelUtil

	override complete_TestStepContext(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		// TODO this should be done using an auto-editing feature
		acceptor.accept(createCompletionProposal('Mask: ', 'Mask:', getImage(model), context))
		acceptor.accept(createCompletionProposal('Component: ', 'Component:', getImage(model), context))
	}

	override complete_TestStep(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		acceptor.accept(createCompletionProposal('- ', '- test step', null, context))
	}

	override complete_StepContentElement(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		super.complete_StepContentElement(model, ruleCall, context, acceptor)
		if (model instanceof TestStep) {
			val interaction = model.interaction
			val component = model.componentContext?.component
			if (component != null) {
				val possibleElements = component.elements.filter [
					val interactionTypes = componentElementInteractionTypes
					return interactionTypes.contains(interaction)
				]
				// need to consider whether the completion should contain the '>' as well
				val currentNode = context.currentNode
				val includeClosingBracket = !currentNode.text.contains('>') &&
					!currentNode.nextSibling.text.contains('>')
				possibleElements.forEach [
					val displayString = '''«name»«IF !label.nullOrEmpty» - "«label»"«ENDIF» (type: «type.name»)'''
					val proposal = '''<«name»«IF includeClosingBracket»>«ENDIF»'''
					acceptor.accept(createCompletionProposal(proposal, displayString, image, context))
				]
			}
		}
	}

}