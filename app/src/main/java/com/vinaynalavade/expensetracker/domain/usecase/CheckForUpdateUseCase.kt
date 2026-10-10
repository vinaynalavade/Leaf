package com.vinaynalavade.expensetracker.domain.usecase

import com.vinaynalavade.expensetracker.core.result.AppResult
import com.vinaynalavade.expensetracker.domain.model.RemoteReleaseInfo
import com.vinaynalavade.expensetracker.domain.model.UpdateCheckResult
import com.vinaynalavade.expensetracker.domain.repository.UpdateRepository

/**
 * Use case to check for available updates comparing local version against remote release metadata.
 * Prioritizes versionCode when explicitly available from remote release metadata; otherwise
 * utilizes robust semantic version comparison (major.minor.patch).
 * Rejects equal, older, and downgrade versions.
 */
class CheckForUpdateUseCase(
    private val updateRepository: UpdateRepository
) {

    suspend operator fun invoke(
        localVersionCode: Long,
        localVersionName: String
    ): AppResult<UpdateCheckResult> {
        return when (val releaseResult = updateRepository.fetchLatestRelease()) {
            is AppResult.Success -> {
                val releaseInfo = releaseResult.data
                val isUpdateAvailable = isNewerVersion(
                    remoteVersionCode = releaseInfo.latestVersionCode,
                    remoteVersionName = releaseInfo.latestVersionName,
                    localVersionCode = localVersionCode,
                    localVersionName = localVersionName
                )
                if (isUpdateAvailable) {
                    AppResult.Success(
                        UpdateCheckResult.UpdateAvailable(
                            releaseInfo = releaseInfo,
                            currentVersionName = localVersionName,
                            currentVersionCode = localVersionCode
                        )
                    )
                } else {
                    AppResult.Success(
                        UpdateCheckResult.UpToDate(
                            currentVersionName = localVersionName,
                            currentVersionCode = localVersionCode
                        )
                    )
                }
            }
            is AppResult.Error -> {
                AppResult.Error(releaseResult.error)
            }
        }
    }

    companion object {
        /**
         * Determines whether a remote release represents a newer version than currently installed.
         * If the remote release specifies a versionCode > 0, versionCode comparison is prioritized.
         * Otherwise (or when versionCodes are equal), semantic version comparison is performed.
         * Downgrades and equal versions are rejected.
         */
        fun isNewerVersion(
            remoteVersionCode: Long,
            remoteVersionName: String,
            localVersionCode: Long,
            localVersionName: String
        ): Boolean {
            if (remoteVersionCode > 0L && localVersionCode > 0L) {
                if (remoteVersionCode > localVersionCode) return true
                if (remoteVersionCode < localVersionCode) return false
                return compareSemanticVersions(remoteVersionName, localVersionName) > 0
            }
            return compareSemanticVersions(remoteVersionName, localVersionName) > 0
        }

        /**
         * Compares two semantic version strings (e.g. "1.1.2" vs "1.1.1").
         * Returns > 0 if v1 > v2, < 0 if v1 < v2, and 0 if equal.
         */
        fun compareSemanticVersions(v1: String, v2: String): Int {
            val clean1 = v1.trim().removePrefix("v").removePrefix("V").substringBefore("-")
            val clean2 = v2.trim().removePrefix("v").removePrefix("V").substringBefore("-")

            val parts1 = clean1.split(".").mapNotNull { it.trim().toIntOrNull() }
            val parts2 = clean2.split(".").mapNotNull { it.trim().toIntOrNull() }

            val maxLength = maxOf(parts1.size, parts2.size)
            for (i in 0 until maxLength) {
                val num1 = parts1.getOrElse(i) { 0 }
                val num2 = parts2.getOrElse(i) { 0 }
                if (num1 != num2) {
                    return num1.compareTo(num2)
                }
            }
            return 0
        }
    }
}
