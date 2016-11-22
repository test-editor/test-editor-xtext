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
package org.testeditor.rcp4.views.tcltestrun.rest

import com.google.gson.Gson
import java.nio.file.Files
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.PathParam
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.eclipse.xtend.lib.annotations.Accessors
import org.testeditor.rcp4.views.tcltestrun.model.Link
import org.testeditor.rcp4.views.tcltestrun.model.TestExecutionManager
import org.testeditor.rcp4.views.tcltestrun.model.TestLogGroupBuilder

@Path(TestExecutionLogService.SERVICE_PATH)
class TestExecutionLogService {

	@Accessors
	TestExecutionManager testExecutionManager

	val public static String SERVICE_PATH = "/testruns"

	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def Response getTestLogExeutionsList() {
		val result = testExecutionManager.testExecutionLogs
		result.entries.forEach [
			it.links = createLinks(it.filename)
		]
		val gson = new Gson
		return Response.ok(gson.toJson(result)).build
	}

	def Link[] createLinks(String fileName) {
		val links = #[
			new Link('''«SERVICE_PATH»/«fileName»/fullLogs''', "fullLogs"),
			new Link('''«SERVICE_PATH»/«fileName»/logGroups''', "logGroups"),
			new Link('''«SERVICE_PATH»/«fileName»/logGroups''', "self")
		]
		return links
	}

	@Path("/{filename}/fullLogs")
	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def Response getTestLogExeutionContent(@PathParam("filename") String filename) {
		val log = testExecutionManager.gettestExecutionLogFor(filename)
		log.links = createLinks(filename)
		val gson = new Gson
		return Response.ok(gson.toJson(log)).build
	}

	@Path("/{filename}/logGroups")
	@GET
	@Produces(MediaType.APPLICATION_JSON)
	def Response getTestLogExeutionTestStepTree(@PathParam("filename") String filename) {
		val log = testExecutionManager.testExecutionLogs.entries.filter[logFile.name == filename].head
		log.logGroups = new TestLogGroupBuilder().build(Files.readAllLines(log.logFile.toPath))
		log.links = createLinks(filename)
		val gson = new Gson
		return Response.ok(gson.toJson(log)).build
	}

}