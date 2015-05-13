/*
 * generated by Xtext
 */
package org.testeditor.xmllibrary.dsl.generator

import java.util.List
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.testeditor.xmllibrary.model.Action
import org.testeditor.xmllibrary.model.ActionGroups

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class AllActionGroupsDslGenerator implements IGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		val container = resource.contents.head as ActionGroups
		val sourceFilename = resource.URI.trimFragment.trimFileExtension.lastSegment
		val filename = '''«sourceFilename».xml'''.toString
		fsa.generateFile(filename, compile(container, URI.createURI(filename)))
	}

	def String compile(ActionGroups container, URI uri) {

		val result = '''
			<?xml version="1.0" encoding="UTF-8"?>
			<ActionGroups xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" schemaVersion="1.1">
				«FOR actionGroup : container.actionGroups»
					<ActionGroup name="«actionGroup.name»">
						«actionGroup.actions.compile»
					</ActionGroup>
				«ENDFOR»
			</ActionGroups>
		'''

		return result
	}

	protected def String compile(List<Action> actions) '''
		«FOR action : actions»
			«FOR actionName : action.actionNames»
				<action technicalBindingType="«action.technicalBindingType.id»">
					<actionName locator="«actionName.locator»">«actionName.name»</actionName>
				</action>
			«ENDFOR»
		«ENDFOR»
	'''

}
