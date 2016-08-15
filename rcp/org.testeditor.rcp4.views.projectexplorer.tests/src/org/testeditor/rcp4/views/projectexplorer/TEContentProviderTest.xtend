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
import org.eclipse.jdt.core.JavaCore
import org.junit.Test
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.dsl.common.testing.AbstractTest

import static org.mockito.Mockito.*
import org.eclipse.jdt.core.IJavaProject
import org.eclipse.jdt.core.IClasspathEntry
import org.eclipse.core.resources.IWorkspaceRoot
import org.eclipse.core.resources.IFolder
import org.eclipse.core.resources.IResource

class TEContentProviderTest extends AbstractTest {

	@InjectMocks TEContentProvider contentProvider
	@Mock WorkspaceRootHelper workspaceHelper
	@Mock JavaCoreHelper javaCoreHelper
	@Mock IClasspathEntry classpathSource
	@Mock IWorkspaceRoot root
	@Mock IProject project
	@Mock IFolder folder

	@Test
	def void testGetChildrenOfProject() {
		// given
		val classPathOther = mock(IClasspathEntry)
		val javaProject = mock(IJavaProject)
		when(javaCoreHelper.create(any)).thenReturn(javaProject)
		when(project.hasNature(JavaCore.NATURE_ID)).thenReturn(true)
		when(classpathSource.entryKind).thenReturn(IClasspathEntry.CPE_SOURCE)
		when(classPathOther.entryKind).thenReturn(IClasspathEntry.CPE_LIBRARY)
		when(javaProject.rawClasspath).thenReturn(#[classpathSource, classPathOther])

		// when
		val cpEntries = contentProvider.getChildren(project)

		// then
		assertNotNull(cpEntries)
		assertEquals(1, cpEntries.size)
	}

	@Test
	def void testGetChildrenOfClasspathEntry() {
		// given
		val resource = mock(IResource)
		when(workspaceHelper.root).thenReturn(root)
		when(root.getFolder(any)).thenReturn(folder)
		when(folder.members).thenReturn(#[resource])
		
		// when
		val childs = contentProvider.getChildren(classpathSource)

		// then
		assertTrue(childs.contains(resource))
	}

	@Test
	def void testGetParentOfResource() {
		// given
		val resource = mock(IResource)
		val javaProject = mock(IJavaProject)
		when(javaCoreHelper.create(any)).thenReturn(javaProject)
		when(project.hasNature(JavaCore.NATURE_ID)).thenReturn(true)
		when(classpathSource.entryKind).thenReturn(IClasspathEntry.CPE_SOURCE)
		when(javaProject.rawClasspath).thenReturn(#[classpathSource])
		when(resource.project).thenReturn(project)
		when(workspaceHelper.root).thenReturn(root)
		when(root.getFolder(any)).thenReturn(folder)
		when(folder.members).thenReturn(#[resource])
		
		// when
		val parent = contentProvider.getParent(resource)

		// then
		assertEquals(classpathSource, parent)
	}

	@Test
	def void testGetParentOfClasspathEntry() {
		// given
		when(workspaceHelper.root).thenReturn(root)
		when(root.getFolder(any)).thenReturn(folder)
		when(folder.project).thenReturn(project)
		
		// when
		val parent = contentProvider.getParent(classpathSource)

		// then
		assertEquals(project, parent)
	}

}