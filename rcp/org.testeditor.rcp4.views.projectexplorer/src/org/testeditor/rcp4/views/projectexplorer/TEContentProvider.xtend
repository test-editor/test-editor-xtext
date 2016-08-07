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
package org.testeditor.rcp4.views.projectexplorer

import org.eclipse.core.resources.IProject
import org.eclipse.core.resources.IResource
import org.eclipse.jdt.core.IClasspathEntry
import org.eclipse.jdt.core.JavaCore
import org.eclipse.jface.viewers.ITreeContentProvider
import org.eclipse.jface.viewers.Viewer
import org.eclipse.xtend.lib.annotations.Accessors

/**
 * Content Provider to extend the cnf navigator with the TE specific elements. The provider replaces folders of the classpath entry with one entry.
 */
class TEContentProvider implements ITreeContentProvider {

	@Accessors WorkspaceRootHelper workspaceRootHelper = new WorkspaceRootHelper
	@Accessors JavaCoreHelper javaCoreHelper = new JavaCoreHelper

	override getChildren(Object parentElement) {
		if (parentElement instanceof IProject) {
			if (parentElement.hasNature(JavaCore.NATURE_ID)) {
				val javaProject = javaCoreHelper.create(parentElement);
				return javaProject.rawClasspath.filter[entryKind == IClasspathEntry.CPE_SOURCE]
			}
		}
		if (parentElement instanceof IClasspathEntry) {
			return workspaceRootHelper.getRoot.getFolder(parentElement.path).members
		}
		return null;
	}

	override getElements(Object inputElement) {
		return null
	}

	override getParent(Object element) {
		if (element instanceof IResource) {
			if (element.project != null) {
				val list = getChildren(element.project).filter(IClasspathEntry).filter [
					workspaceRootHelper.getRoot.getFolder(it.path).members.contains(element)
				]
				if (!list.empty) {
					return list.head
				}
			}
		}
		if (element instanceof IClasspathEntry) {
			return workspaceRootHelper.getRoot.getFolder(element.path).project
		}
		return null
	}

	override hasChildren(Object element) {
		if (element instanceof IClasspathEntry) {
			return workspaceRootHelper.getRoot.getFolder(element.path).members.length > 0
		}
		return false
	}

	override dispose() {
	}

	override inputChanged(Viewer viewer, Object oldInput, Object newInput) {
	}

}
