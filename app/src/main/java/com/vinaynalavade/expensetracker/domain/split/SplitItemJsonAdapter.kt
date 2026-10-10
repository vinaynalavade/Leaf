package com.vinaynalavade.expensetracker.domain.split

import com.vinaynalavade.expensetracker.core.model.Amount
import com.vinaynalavade.expensetracker.core.util.SimpleJsonParser
import com.vinaynalavade.expensetracker.domain.model.ItemizedSplitData
import com.vinaynalavade.expensetracker.domain.model.SplitItem

/**
 * Pure Kotlin, dependency-free precision-safe JSON serializer and parser for itemized split bill breakdowns.
 *
 * Uses SimpleJsonParser for 100% deterministic operation across Android runtime and JVM unit test environments,
 * persisting items, item consumers, custom allocations, and shared unallocated distribution.
 */
object SplitItemJsonAdapter {

    fun toJson(data: ItemizedSplitData): String {
        val sb = StringBuilder()
        sb.append("{")
        sb.append("\"items\":[")
        data.items.forEachIndexed { iIndex, item ->
            if (iIndex > 0) sb.append(",")
            sb.append("{")
            sb.append("\"id\":\"").append(escapeString(item.id)).append("\",")
            sb.append("\"name\":\"").append(escapeString(item.name)).append("\",")
            sb.append("\"amountSubunits\":").append(item.amount.subunits).append(",")
            sb.append("\"amountInput\":\"").append(escapeString(item.amountInput)).append("\",")

            sb.append("\"participantNames\":[")
            item.participantNames.forEachIndexed { pIndex, pName ->
                if (pIndex > 0) sb.append(",")
                sb.append("\"").append(escapeString(pName)).append("\"")
            }
            sb.append("],")

            sb.append("\"isCustomAllocation\":").append(item.isCustomAllocation).append(",")

            sb.append("\"customAllocations\":{")
            item.customAllocations.entries.forEachIndexed { cIndex, (pName, amt) ->
                if (cIndex > 0) sb.append(",")
                sb.append("\"").append(escapeString(pName)).append("\":").append(amt.subunits)
            }
            sb.append("},")

            sb.append("\"customAllocationInputs\":{")
            item.customAllocationInputs.entries.forEachIndexed { ciIndex, (pName, input) ->
                if (ciIndex > 0) sb.append(",")
                sb.append("\"").append(escapeString(pName)).append("\":\"").append(escapeString(input)).append("\"")
            }
            sb.append("}")

            sb.append("}")
        }
        sb.append("],")

        sb.append("\"sharedRemainingParticipantNames\":[")
        data.sharedRemainingParticipantNames.forEachIndexed { sIndex, name ->
            if (sIndex > 0) sb.append(",")
            sb.append("\"").append(escapeString(name)).append("\"")
        }
        sb.append("],")

        sb.append("\"isSharedRemainingDistributed\":").append(data.isSharedRemainingDistributed)
        sb.append("}")

        return sb.toString()
    }

    fun fromJson(jsonStr: String?): ItemizedSplitData? {
        if (jsonStr.isNullOrBlank()) return null
        return try {
            val root = SimpleJsonParser.parse(jsonStr.trim()) as? SimpleJsonParser.JsonObject ?: return null
            val itemsList = mutableListOf<SplitItem>()

            val itemsArray = root.getArray("items")
            if (itemsArray != null) {
                for (elem in itemsArray) {
                    val itemObj = elem as? SimpleJsonParser.JsonObject ?: continue
                    val id = itemObj.getString("id").orEmpty()
                    val name = itemObj.getString("name").orEmpty()
                    val amountSubunits = itemObj.getLong("amountSubunits") ?: 0L
                    val amountInput = itemObj.getString("amountInput").orEmpty()

                    val pNames = mutableListOf<String>()
                    val pArray = itemObj.getArray("participantNames")
                    if (pArray != null) {
                        for (pElem in pArray) {
                            val p = (pElem as? SimpleJsonParser.JsonPrimitive)?.value
                            if (!p.isNullOrBlank()) {
                                pNames.add(p)
                            }
                        }
                    }

                    val isCustomAllocation = itemObj.getBoolean("isCustomAllocation") ?: false

                    val customAllocations = mutableMapOf<String, Amount>()
                    val customAllocObj = itemObj.getObject("customAllocations")
                    if (customAllocObj != null) {
                        for ((key, vElem) in customAllocObj.map) {
                            val sub = (vElem as? SimpleJsonParser.JsonPrimitive)?.value?.toLongOrNull()
                            if (sub != null) {
                                customAllocations[key] = Amount.fromSubunits(sub)
                            }
                        }
                    }

                    val customAllocationInputs = mutableMapOf<String, String>()
                    val customInputsObj = itemObj.getObject("customAllocationInputs")
                    if (customInputsObj != null) {
                        for ((key, vElem) in customInputsObj.map) {
                            val str = (vElem as? SimpleJsonParser.JsonPrimitive)?.value
                            if (str != null) {
                                customAllocationInputs[key] = str
                            }
                        }
                    }

                    itemsList.add(
                        SplitItem(
                            id = if (id.isNotBlank()) id else java.util.UUID.randomUUID().toString(),
                            name = name,
                            amount = Amount.fromSubunits(amountSubunits),
                            amountInput = amountInput,
                            participantNames = pNames,
                            isCustomAllocation = isCustomAllocation,
                            customAllocations = customAllocations,
                            customAllocationInputs = customAllocationInputs
                        )
                    )
                }
            }

            val sharedList = mutableListOf<String>()
            val sharedArray = root.getArray("sharedRemainingParticipantNames")
            if (sharedArray != null) {
                for (sElem in sharedArray) {
                    val name = (sElem as? SimpleJsonParser.JsonPrimitive)?.value
                    if (!name.isNullOrBlank()) {
                        sharedList.add(name)
                    }
                }
            }

            val isDistributed = root.getBoolean("isSharedRemainingDistributed") ?: false

            ItemizedSplitData(
                items = itemsList,
                sharedRemainingParticipantNames = sharedList,
                isSharedRemainingDistributed = isDistributed
            )
        } catch (_: Exception) {
            null
        }
    }

    private fun escapeString(s: String): String {
        val sb = StringBuilder()
        for (c in s) {
            when (c) {
                '\\' -> sb.append("\\\\")
                '"' -> sb.append("\\\"")
                '\b' -> sb.append("\\b")
                '\u000c' -> sb.append("\\f")
                '\n' -> sb.append("\\n")
                '\r' -> sb.append("\\r")
                '\t' -> sb.append("\\t")
                else -> {
                    if (c.code in 0x00..0x1F) {
                        sb.append(String.format("\\u%04x", c.code))
                    } else {
                        sb.append(c)
                    }
                }
            }
        }
        return sb.toString()
    }
}

