package org.testeditor.dsl.common.util

import org.junit.Test

import static org.junit.Assert.*

import static extension org.testeditor.dsl.common.util.CollectionUtils.*

class CollectionUtilsTest {

	@Test
	def void testNoAddIfExisting() {
		// given
		val map = newHashMap("existing" -> "value")

		// when
		map.putIfAbsent("existing", "othervalue")

		// then
		assertEquals("value", map.get("existing"))
		assertEquals(1, map.size)
	}

	@Test
	def void testAddIfNotExisting() {
		// given
		val map = newHashMap

		// when
		map.putIfAbsent("notexisting", "othervalue")

		// then
		assertEquals("othervalue", map.get("notexisting"))
		assertEquals(1, map.size)
	}

}