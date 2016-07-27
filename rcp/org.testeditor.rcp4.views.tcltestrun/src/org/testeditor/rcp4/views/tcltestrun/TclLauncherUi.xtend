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
package org.testeditor.rcp4.views.tcltestrun

import java.io.File
import java.io.FileFilter
import java.util.ArrayList
import java.util.List
import java.util.Map
import java.util.concurrent.atomic.AtomicReference
import javax.inject.Inject
import org.eclipse.core.resources.IFile
import org.eclipse.core.resources.IFolder
import org.eclipse.core.resources.IProject
import org.eclipse.core.resources.IResource
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jdt.core.IJavaElement
import org.eclipse.jdt.junit.JUnitCore
import org.eclipse.jface.viewers.IStructuredSelection
import org.eclipse.jface.viewers.LabelProvider
import org.eclipse.jface.window.Window
import org.eclipse.ui.PlatformUI
import org.eclipse.ui.dialogs.ElementListSelectionDialog
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.resource.IResourceDescriptions
import org.slf4j.LoggerFactory
import org.testeditor.dsl.common.ui.utils.ProgressMonitorRunner
import org.testeditor.rcp4.tcltestrun.TclGradleLauncher
import org.testeditor.rcp4.tcltestrun.TclInjectorProvider
import org.testeditor.rcp4.tcltestrun.TclLauncher
import org.testeditor.rcp4.tcltestrun.TclMavenLauncher
import org.testeditor.tcl.TclModel
import org.testeditor.tcl.TclPackage
import org.testeditor.tcl.TestCase
import org.testeditor.tcl.dsl.ui.testlaunch.LaunchShortcutUtil
import org.testeditor.tcl.dsl.ui.testlaunch.Launcher

class TclLauncherUi implements Launcher {
	static val logger = LoggerFactory.getLogger(TclLauncherUi)

	@Inject ProgressMonitorRunner progressRunner
	@Inject TclMavenLauncher mavenLauncher
	@Inject TclGradleLauncher gradleLauncher
	@Inject TestResultFileWriter testResultFileWriter
	@Inject TclInjectorProvider tclInjectorProvider
	LaunchShortcutUtil launchShortcutUtil // since this class itself is instanciated by e4, this attribute has to be injected manually
	Map<URI, List<TestCase>> tslIndex

	@Inject
	new(TclInjectorProvider tclInjectorProvider) {
		launchShortcutUtil = tclInjectorProvider.get.getInstance(LaunchShortcutUtil)
	}

	override boolean launch(IStructuredSelection selection, IProject project, String mode, boolean parameterize) {
		val options = newHashMap
		createTestCaseIndex(project)
		if (project.getFile("build.gradle").exists) {
			return launchTest(createGradleTestCasesList(selection), project, gradleLauncher, options)
		}
		if (project.getFile("pom.xml").exists) {
			if (parameterize) {
				val profile = selectMavenProfile(project)
				if (profile == null) {
					return true // should an option always be selected?
				}
				options.put(TclMavenLauncher.PROFILE, profile)
			}
			return launchTest(createTestCasesList(selection), project, mavenLauncher, options)
		}
		logger.warn("gradle based launching test for tcl element='{}' failed, since file='build.gradle' was not found.",
			selection.firstElement)
		return false
	}

	def createTestCaseIndex(IProject project) {
		var resourceDescriptions = tclInjectorProvider.get.getInstance(IResourceDescriptions)
		val rs = tclInjectorProvider.get.getInstance(ResourceSet)
		val modells = resourceDescriptions.getExportedObjectsByType(TclPackage.Literals.TCL_MODEL)
		val tclModells = modells.map[EObjectOrProxy].map[EcoreUtil2.resolve(it, rs) as TclModel]
		val testcases = tclModells.map[test].filterNull
		tslIndex = newHashMap
		testcases.forEach [
			if (it.specification != null) {
				val tslKey = it.specification.eContainer.eResource.URI
				if (!tslIndex.keySet.contains(tslKey)) {
					tslIndex.put(tslKey, newArrayList)
				}
				tslIndex.get(tslKey).add(it)
			}
		]
	}

	private def String selectMavenProfile(IProject project) {
		val mavenProfiles = project.collectMavenProfilesWithProgress
		val dialog = new ElementListSelectionDialog(PlatformUI.workbench.activeWorkbenchWindow.shell, new LabelProvider)
		dialog.setElements(mavenProfiles)
		dialog.setTitle("Which maven profile should be used?")
		if (dialog.open == Window.OK) {
			return dialog.result.head.toString
		} else {
			return null // cancelled
		}
	}

	private def Iterable<String> collectMavenProfilesWithProgress(IProject project) {
		val result = new AtomicReference<Iterable<String>>
		progressRunner.run([ monitor |
			monitor.beginTask("Collect maven profiles", IProgressMonitor.UNKNOWN)
			result.set(mavenLauncher.getProfiles(project))
			monitor.done
		])
		return result.get
	}

	private def boolean launchTest(List<String> testCasesCommaList, IProject project, TclLauncher launcher,
		Map<String, Object> options) {
		logger.info("Trying to launch launcherClass='{}' test execution for elementId='{}' in project='{}'",
			launcher.class.simpleName, testCasesCommaList.get(0), project)
		progressRunner.run([ monitor |
			monitor.beginTask("Test execution: " + testCasesCommaList.get(0), IProgressMonitor.UNKNOWN)

			val result = launcher.launchTest(testCasesCommaList, project, monitor, options)
			project.refreshLocal(IProject.DEPTH_INFINITE, monitor)
			if (result.expectedFileRoot == null) {
				logger.error("resulting expectedFile must not be null")
			} else {
				safeUpdateJunitTestView(result.expectedFileRoot, project.name)
			}
			monitor.done
		])
		return true
	}

	def List<String> createGradleTestCasesList(IStructuredSelection selection) {
		val result = new ArrayList<String>()
		result += selection.toList.filter(IResource).map [ resource |
			if (resource instanceof IFolder) {
				val javaElement = resource.getAdapter(IJavaElement) as IJavaElement
				if (javaElement != null) {
					return javaElement.elementName + "*"
				} else {
					logger.warn("selected element = {} is not a test exeutuable", resource.name)
					return null
				}

			} else {
				return launchShortcutUtil.getQualifiedNameForTestInTcl(resource).toString
			}
		].filterNull

		return result

	}

	def List<String> createTestCasesList(IStructuredSelection selection) {
		if (selection.size > 1) {
			return selection.toList.map[testCaseListFromSelection].flatten.toList
		} else {
			return selection.firstElement.testCaseListFromSelection.toList
		}
	}

	def Iterable<String> getTestCaseListFromSelection(Object sel) {
		if (sel instanceof IFolder) {
			sel.testCasesFromFolder
		} else {
			if (sel instanceof IResource) {
				if (sel.fileExtension.equalsIgnoreCase("tsl")) {
					val uri = URI.createPlatformResourceURI(sel.locationURI.toString, true).deresolve(
						URI.createPlatformResourceURI(sel.project.locationURI.toString, true))
					val secondURI = URI.createPlatformResourceURI(uri.toString, true)
					tslIndex.get(secondURI).map[toString]
				} else {
					#[launchShortcutUtil.getQualifiedNameForTestInTcl(sel).toString]
				}
			}
		}
	}

	def List<String> getTestCasesFromFolder(IFolder folder) {
		val result = newArrayList()
		for (IResource res : folder.members) {
			if (res instanceof IFile) {
				if (res.fileExtension.equalsIgnoreCase("tcl")) {
					result.add(launchShortcutUtil.getQualifiedNameForTestInTcl(res).toString)
				}
			}
			if (res instanceof IFolder) {
				result.addAll(res.testCasesFromFolder)
			}
		}
		return result
	}

	/** 
	 * provide test result file (either the one created by the test run, or, if absent/on error 
	 * a default error file) that is imported into junit (and thus displayed) 
	 * */
	private def void safeUpdateJunitTestView(File expectedFileRoot, String projectName) {
		logger.debug("Test result parentPir={}", expectedFileRoot)
		val xmlResults = expectedFileRoot.listFiles(new FileFilter() {

			override accept(File pathname) {
				return pathname.isFile && pathname.name.endsWith(".xml")
			}

		})
		val resultFile = new File(expectedFileRoot, "te-testCompose.xml")
		if (xmlResults.length > 0) {
			testResultFileWriter.writeTestResultFile(projectName, resultFile, xmlResults)
		} else {
			testResultFileWriter.writeErrorFile(projectName, resultFile)
		}
		JUnitCore.importTestRunSession(resultFile)
	}

}
