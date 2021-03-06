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
package org.testeditor.dsl.common.ui.wizards

import java.io.InputStream
import java.lang.reflect.InvocationTargetException
import javax.inject.Inject
import org.eclipse.core.resources.IContainer
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.core.runtime.IStatus
import org.eclipse.core.runtime.Path
import org.eclipse.core.runtime.Status
import org.eclipse.jdt.core.JavaCore
import org.eclipse.jface.operation.IRunnableWithProgress
import org.eclipse.jface.viewers.ISelection
import org.eclipse.jface.viewers.IStructuredSelection
import org.eclipse.jface.wizard.Wizard
import org.eclipse.ui.INewWizard
import org.eclipse.ui.IWorkbench
import org.eclipse.ui.IWorkbenchWizard
import org.eclipse.ui.PartInitException
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.ide.IDE
import org.eclipse.xtext.util.StringInputStream
import org.slf4j.LoggerFactory
import org.testeditor.dsl.common.util.classpath.ClasspathUtil

import static extension org.eclipse.jface.dialogs.MessageDialog.*

abstract class NewFileWizard extends Wizard implements INewWizard {

	static val logger = LoggerFactory.getLogger(NewFileWizard)

	@Inject ClasspathUtil classpathUtil

	protected ISelection selection

	new() {
		super()
		needsProgressMonitor = true
	}

	abstract def String getContainerName()

	abstract def String getFileName()

	/** 
	 * This method is called when 'Finish' button is pressed in
	 * the wizard. We will create an operation and run it
	 * using wizard as execution context.
	 */
	override boolean performFinish() {
		var IRunnableWithProgress op = [ IProgressMonitor monitor |
			try {
				doFinish(containerName, fileName, monitor)
			} catch (CoreException e) {
				throw new InvocationTargetException(e)
			} finally {
				monitor.done
			}
		]
		try {
			container.run(false, false, op) // needs to be sync, else this runs into a Invalid Thread Access violation
		} catch (InterruptedException e) {
			return false
		} catch (InvocationTargetException e) {
			logger.error("error on executing new file wizard", e)
			val realException = e.targetException
			shell.openError("Error", realException.message)
			return false
		}
		return true
	}

	/** 
	 * The worker method. It will find the container, create the
	 * file if missing or just replace its contents, and open
	 * the editor on the newly created file.
	 */
	def private void doFinish(String containerName, String fileName, IProgressMonitor monitor) throws CoreException {
		// create a sample file
		monitor.beginTask('''Creating «fileName»''', 2)
		val root = ResourcesPlugin.workspace.root
		val resource = root.findMember(new Path(containerName))
		if (!resource.exists || !(resource instanceof IContainer)) {
			throwCoreException('''Container "«containerName»" does not exist.''')
		}
		val container = resource as IContainer
		val file = container.getFile(new Path(fileName))
		val stream = openContentStream(container, fileName)
		if (file.exists) {
			throw new IllegalStateException("File already exists: " + file)
		}
		file.create(stream, true, monitor)
		stream.close
		monitor.worked(1)
		monitor.taskName = "Opening file for editing..."
		shell.display.asyncExec [
			val page = PlatformUI.workbench.activeWorkbenchWindow.activePage
			try {
				IDE.openEditor(page, file, true)
			} catch (PartInitException e) {
			}
		]
		monitor.worked(1)
	}

	def private InputStream openContentStream(IContainer container, String fileName) {
		val javaElement = JavaCore.create(container)
		val thePackage = classpathUtil.inferPackage(javaElement)
		return new StringInputStream(contentString(thePackage, fileName))
	}

	/** 
	 * default implementation, please override
	 */
	def protected String contentString(String thePackage, String fileName) {
		return ''
	}

	def private void throwCoreException(String message) throws CoreException {
		val status = new Status(IStatus.ERROR, "com.deleteme", IStatus.OK, message, null)
		throw new CoreException(status)
	}

	/** 
	 * We will accept the selection in the workbench to see if
	 * we can initialize from it.
	 * @see IWorkbenchWizard#init(IWorkbench, IStructuredSelection)
	 */
	override void init(IWorkbench workbench, IStructuredSelection selection) {
		this.selection = selection
	}

}
