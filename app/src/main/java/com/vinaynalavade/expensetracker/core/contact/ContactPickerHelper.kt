package com.vinaynalavade.expensetracker.core.contact

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract

/**
 * Representation of selected contact details.
 */
data class SelectedContactInfo(
    val name: String,
    val phoneNumber: String?
)

/**
 * Utility helper to safely resolve contact information from standard Android contact picker results.
 */
object ContactPickerHelper {

    /**
     * Extracts display name and phone number from contact [Uri] picked via standard system picker.
     */
    fun extractContact(context: Context, contactUri: Uri): SelectedContactInfo? {
        return try {
            val cursor = context.contentResolver.query(
                contactUri,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                ),
                null,
                null,
                null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val nameIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
                    val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                    val name = if (nameIndex >= 0) it.getString(nameIndex) ?: "" else ""
                    val rawNumber = if (numberIndex >= 0) it.getString(numberIndex) else null
                    val cleanNumber = rawNumber?.trim()?.ifBlank { null }

                    if (name.isNotBlank() || cleanNumber != null) {
                        SelectedContactInfo(
                            name = name.ifBlank { cleanNumber ?: "Participant" }.trim(),
                            phoneNumber = cleanNumber
                        )
                    } else null
                } else null
            }
        } catch (_: Exception) {
            null
        }
    }
}
