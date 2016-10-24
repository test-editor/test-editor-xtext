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

import javax.json.Json
import javax.ws.rs.GET
import javax.ws.rs.Path
import javax.ws.rs.Produces
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.eclipse.xtend.lib.annotations.Accessors
import org.testeditor.rcp4.views.tcltestrun.model.TestExecutionManager
import java.util.Date
import java.text.SimpleDateFormat

@Path("/testexeclog")
class TestExecutionLogService {
	
	@Accessors
	TestExecutionManager testExecutionManager
	
	@Path("/metadata") 	
	@GET 
	@Produces(MediaType::APPLICATION_JSON) 
	def Response getTestLogExeutionMetaData() {
		val json = Json.createObjectBuilder
		json.add("value", "Foo")		
		return Response.ok(json.build.toString).build
	}
	
	@Path("/list") 	
	@GET 
	@Produces(MediaType::APPLICATION_JSON) 
	def Response getTestLogExeutionList() {
		val result = Json.createObjectBuilder
		val array = Json.createArrayBuilder
		testExecutionManager.testExecutionLogs.forEach[
			val execLog = Json.createObjectBuilder
			execLog.add("filename",it)
			execLog.add("name",getTestExecutionLogName(it))
			array.add(execLog)
		]
		result.add("entries",array)
		return Response.ok(result.build.toString).build
	}
	
	def private String getTestExecutionLogName(String teLogFileName) {
		val date = new Date(Long.parseLong(teLogFileName.substring(3,teLogFileName.lastIndexOf("."))))
		val sdf = new SimpleDateFormat("dd.MM.yy HH:mm")
		return sdf.format(date)
	}
	
}