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
package org.testeditor.tml.dsl.ui.quickfix

import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.jface.viewers.Viewer
import org.eclipse.jface.viewers.ViewerFilter
import org.eclipse.jface.window.Window
import org.eclipse.swt.widgets.Display
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.dialogs.ElementTreeSelectionDialog
import org.eclipse.ui.model.BaseWorkbenchContentProvider
import org.eclipse.ui.model.WorkbenchLabelProvider
import org.eclipse.ui.part.FileEditorInput
import org.eclipse.xtext.nodemodel.ICompositeNode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.XtextEditor
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue
import org.eclipse.xtext.xbase.ui.quickfix.XbaseQuickfixProvider
import org.testeditor.aml.AmlModel
import org.testeditor.tml.ComponentTestStepContext
import org.testeditor.tml.TestStepContext
import org.testeditor.tml.dsl.validation.TmlValidator

/**
 * Custom quickfixes.
 * 
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#quick-fixes
 */
class TmlQuickfixProvider extends XbaseQuickfixProvider {

	@Fix(TmlValidator.UNKNOWN_NAME)
	def createAMLMask(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, "Create AML Mask", "Creates a new AML Mask", 'upcase.png') [ element, context |
			if (element instanceof ComponentTestStepContext) {
				if (element.component.eIsProxy) {
					val maskName = getMaskName(element)
					var amlFile = getTargetFile(context.xtextDocument.getAdapter(IFile))
					if (amlFile != null) {
						var editor = openEditorFor(amlFile)
						var amlModel = editor.document.readOnly() [ ressource |
							return ressource.contents.head as AmlModel
						]
						var ICompositeNode lastNode = null
						if (amlModel.components.empty) {
							lastNode = NodeModelUtils.findActualNodeFor(amlModel)
						} else {
							lastNode = NodeModelUtils.findActualNodeFor(amlModel.components.last)
						}
						editor.document.replace(lastNode.offset + lastNode.length, 0, getComponentDSLFragment(maskName))
					}
				}
			}
		]
	}

	def getTargetFile(IFile currentSelection) {
		val dialog = new ElementTreeSelectionDialog(Display.getDefault().getActiveShell(), new WorkbenchLabelProvider(),
			new BaseWorkbenchContentProvider())
		dialog.input = ResourcesPlugin.getWorkspace().getRoot()
		dialog.allowMultiple = true
		dialog.title = "Select AML file"
		dialog.initialSelection = currentSelection.parent
		dialog.addFilter(new ViewerFilter() {

			override select(Viewer viewer, Object parentElement, Object element) {
				if (element instanceof IFile) {
					return element.toString().endsWith("aml")
				} else
					return true
			}

		})
		if (dialog.open == Window.OK) {
			return dialog.firstResult as IFile
		}
		return null
	}

	def String getComponentDSLFragment(String maskName) '''
		component «maskName» is <TYPE> {
		
		}
	'''

	def openEditorFor(IFile file) {
		var fei = new FileEditorInput(file)
		var id = PlatformUI.getWorkbench().getEditorRegistry().getDefaultEditor(file.getName()).id
		var editor = PlatformUI.workbench.activeWorkbenchWindow.activePage.openEditor(fei, id) as XtextEditor
		return editor
	}

	def getMaskName(TestStepContext testStepContext) {
		val sub = NodeModelUtils.findActualNodeFor(testStepContext).text.split(':')
		return sub.get(1).trim
	}

}