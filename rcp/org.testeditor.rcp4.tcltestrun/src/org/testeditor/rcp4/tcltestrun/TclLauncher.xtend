package org.testeditor.rcp4.tcltestrun

import java.io.File
import javax.inject.Inject
import org.eclipse.core.resources.IProject
import org.eclipse.jdt.junit.JUnitCore
import org.eclipse.jface.viewers.IStructuredSelection
import org.gradle.tooling.GradleConnectionException
import org.gradle.tooling.GradleConnector
import org.gradle.tooling.ProjectConnection
import org.gradle.tooling.ResultHandler
import org.gradle.tooling.events.ProgressEvent
import org.gradle.tooling.events.ProgressListener
import org.slf4j.LoggerFactory
import org.testeditor.dsl.common.ui.utils.ProjectUtils
import org.testeditor.tcl.dsl.ui.testlaunch.Launcher

class TclLauncher implements Launcher {
	static val logger = LoggerFactory.getLogger(TclLauncher)

	static val String TEST_RESULT_FOLDER = "build/test-results"

	@Inject extension ProjectUtils

	def void showTestResult(File testResult) {
		JUnitCore.importTestRunSession(testResult)
	}

	private def String elementIdToFileName(String elementId) {
		'''TEST-«elementId».xml'''
	}

	override boolean launch(IStructuredSelection selection, IProject project, String elementId, String mode) {
		if (!project.getFile("build.gradle").exists) {
			return false
		}

		val testResultFile = project.createOrGetDeepFolder(TEST_RESULT_FOLDER).getFile(elementId.elementIdToFileName).
			location.toFile
		val GradleConnector connector = GradleConnector.newConnector
		var ProjectConnection connection = null
		val projectFolder = project.getFile("some-virtual-file").location.removeLastSegments(1).toFile
		try {
			connection = connector.forProjectDirectory(projectFolder).connect();
			// val BuildEnvironment environment = connection.model(BuildEnvironment).get();
			connection.newBuild.addProgressListener(new ProgressListener {

				override statusChanged(ProgressEvent event) {
					logger.info(event.displayName)
				}

			}) // .forTasks("test") // does not work, see issue below
			.withArguments("test", "--tests", elementId) // https://issues.gradle.org/browse/GRADLE-2972
			// .setStandardOutput(System.out) // alternatively get a separate console output stream (see http://wiki.eclipse.org/FAQ_How_do_I_write_to_the_console_from_a_plug-in%3F)
			.run(
				new ResultHandler {

					override onComplete(Object obj) {
						testResultFile.showTestResult
					}

					override onFailure(GradleConnectionException exception) {
						logger.
							error('''Caught error during gradle task "test" of element "«elementId»": «exception.toString»''',
								exception)
						testResultFile.showTestResult
					}

				})
		} finally {
			if (connection != null) {
				connection.close
			}
		}
		return true
	}

}
