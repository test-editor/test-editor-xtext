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
package org.testeditor.tcl.dsl.ui.editor

import javax.inject.Inject
import org.eclipse.jface.text.TextSelection
import org.eclipse.jface.text.source.ISourceViewer
import org.eclipse.swt.dnd.DND
import org.eclipse.swt.dnd.TextTransfer
import org.eclipse.ui.dnd.IDragAndDropService
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.ui.editor.XtextEditor
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.resource.EObjectAtOffsetHelper

class DropTargetXtextEditor extends XtextEditor {

	@Inject DropTargetXtextEditorListener dropTargetListener
	@Inject protected ContentAssistContext.Factory contentAssistFactory
	@Inject protected EObjectAtOffsetHelper eObjectAtOffsetHelper;

	override protected installTextDragAndDrop(ISourceViewer viewer) {
		if (viewer === null)
			return

		val dndService = getSite().getService(IDragAndDropService)
		if (dndService === null)
			return;

		// Install drag target
		dndService.addMergedDropTarget(viewer.getTextWidget(), DND.DROP_MOVE.bitwiseOr(DND.DROP_COPY),
			#[TextTransfer.instance], dropTargetListener);
	}

	def findDropTarget(XtextResource resource) {
		val offset = (selectionProvider.selection as TextSelection).offset
		val eObject = eObjectAtOffsetHelper.resolveElementAt(resource, offset)
		System.out.println("eObject " + eObject)
		val contentAssistContexts = contentAssistFactory.create(internalSourceViewer, offset, resource)
		return contentAssistContexts.head.currentModel
	}

}
