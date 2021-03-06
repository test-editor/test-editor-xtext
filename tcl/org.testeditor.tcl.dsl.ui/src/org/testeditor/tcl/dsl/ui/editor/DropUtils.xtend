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
package org.testeditor.tcl.dsl.ui.editor

import org.eclipse.emf.ecore.EObject
import org.eclipse.jface.util.LocalSelectionTransfer
import org.eclipse.jface.viewers.ISelection
import org.eclipse.jface.viewers.TreeSelection
import org.eclipse.xtext.EcoreUtil2
import org.testeditor.aml.Component
import org.testeditor.aml.ComponentElement
import org.testeditor.aml.InteractionType
import org.testeditor.aml.TemplateText
import org.testeditor.aml.TemplateVariable
import org.testeditor.tcl.AbstractTestStep
import org.testeditor.tcl.ComponentTestStepContext
import org.testeditor.tcl.Macro
import org.testeditor.tcl.MacroTestStepContext
import org.testeditor.tcl.SpecificationStepImplementation
import org.testeditor.tcl.StepContainer
import org.testeditor.tcl.TclFactory
import org.testeditor.tcl.TclModel
import org.testeditor.tcl.TestStepContext
import org.testeditor.tcl.impl.MacroTestStepContextImpl
import org.testeditor.tcl.impl.TestStepImpl
import org.testeditor.tsl.StepContentText
import org.testeditor.tsl.TslFactory

class DropUtils {

	static val private TclFactory tclFactory = TclFactory.eINSTANCE
	static val private TslFactory tslFactory = TslFactory.eINSTANCE

	protected def <T> T getDroppedObjectAs(Class<T> clazz) {
		val ISelection sel = LocalSelectionTransfer.transfer.selection
		if (sel instanceof TreeSelection) {
			val treeSelection = sel.paths.head
			for (var index = 0; index < treeSelection.segmentCount; index++) {
				val segment = treeSelection.getSegment(index)
				if (clazz.isInstance(segment)) {
					return segment as T
				}
			}
		}
		return null
	}

	public def ComponentTestStepContext createDroppedTestStepContext() {
		return createDroppedTestStepContext(getDroppedObjectAs(Component), getDroppedObjectAs(ComponentElement),
			getDroppedObjectAs(InteractionType))
	}

	public def ComponentTestStepContext createDroppedTestStepContext(Component component,
		ComponentElement componentElement, InteractionType interactionType) {

		val componentTestStepContext = tclFactory.createComponentTestStepContext
		componentTestStepContext.component = component
		componentTestStepContext.steps.add(createDroppedTestStep(interactionType, componentElement))
		return componentTestStepContext
	}

	public def createDroppedTestStep(InteractionType interactionType, ComponentElement componentElement) {
		val newTestStep = tclFactory.createTestStep
		interactionType.template.contents.forEach [
			switch (it) {
				TemplateText: {
					val stepContentText = tslFactory.createStepContentText
					stepContentText.value = value
					newTestStep.contents.add(stepContentText)
				}
				TemplateVariable: {
					if (name != 'element') {
						val stepContentVariable = tslFactory.createStepContentVariable
						stepContentVariable.value = name
						newTestStep.contents.add(stepContentVariable)
					} else {
						val stepContentElement = tclFactory.createStepContentElement
						stepContentElement.value = componentElement.name
						newTestStep.contents.add(stepContentElement)
					}
				}
				default:
					throw new IllegalArgumentException("The class '" + it.class.getName() +
						"' is not a valid classifier")
			}
		]
		return newTestStep
	}

	protected def SpecificationStepImplementation createSpecification() {
		return tclFactory.createSpecificationStepImplementation
	}

	protected def Macro createMacro() {
		return tclFactory.createMacro
	}

	protected def createComponentTestStepContext() {
		return tclFactory.createComponentTestStepContext
	}

	protected def createMacroTestStepContext() {
		return tclFactory.createMacroTestStepContext
	}

	protected def addTestStepToModel(int insertionIndex, TestStepContext testStepContext,
		AbstractTestStep droppedTestStep) {
		if (insertionIndex < 0 || insertionIndex >= testStepContext.steps.size) {
			testStepContext.steps.add(droppedTestStep)
		} else {
			testStepContext.steps.add(insertionIndex, droppedTestStep)
		}
	}

	protected def TestStepContext searchTargetTestStepContext(TclModel tclModel, EObject dropTarget) {

		if (dropTarget === null) {
			val stepContainer = getLastStepContext(tclModel)
			if (stepContainer === null) {
				return null
			}
			return stepContainer.contexts.last as ComponentTestStepContext
		}
		if (dropTarget instanceof SpecificationStepImplementation) {
			return dropTarget.getContexts.head as ComponentTestStepContext
		}
		if (dropTarget instanceof StepContentText && dropTarget.eContainer instanceof SpecificationStepImplementation) {
			return (dropTarget.eContainer as SpecificationStepImplementation).contexts.head as ComponentTestStepContext
		}
		if (dropTarget instanceof MacroTestStepContextImpl || (dropTarget instanceof TestStepImpl &&
			dropTarget.eContainer instanceof MacroTestStepContextImpl)) {
			return EcoreUtil2.getContainerOfType(dropTarget, MacroTestStepContext)
		}
		return EcoreUtil2.getContainerOfType(dropTarget, ComponentTestStepContext)
	}

	protected def StepContainer getLastStepContext(TclModel tclModel) {
		if (tclModel.test !== null) {
			return tclModel.test.steps.last
		}
		if (tclModel.macroCollection !== null) {
			return tclModel.macroCollection.macros.last
		}
	}

	protected def int getInsertionIndex(TestStepContext testStepContext, EObject dropTarget) {
		if (dropTarget === null) {
			return testStepContext.steps.size
		}
		val selectedTestStep = EcoreUtil2.getContainerOfType(dropTarget, AbstractTestStep)
		return testStepContext.steps.indexOf(selectedTestStep) + 1
	}

}
