package com.arin.arin

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings

/**
 * Xiaomi / Huawei / Honor / Oppo / Vivo / Samsung gibi OEM'lerde kilit ekranı
 * bildirimlerinin arka planda öldürülmemesi için cihaz ailesini tespit eder ve
 * mümkünse autostart / pil ayar sayfalarını açar.
 */
object ArinOemSettings {
    const val CHANNEL = "com.arin.arin/oem_settings"

    enum class Family(val id: String, val displayName: String) {
        XIAOMI("xiaomi", "Xiaomi"),
        HUAWEI("huawei", "Huawei"),
        HONOR("honor", "Honor"),
        OPPO("oppo", "OPPO"),
        VIVO("vivo", "vivo"),
        SAMSUNG("samsung", "Samsung"),
        OTHER("other", "Android"),
    }

    fun detectFamily(
        manufacturer: String = Build.MANUFACTURER.orEmpty(),
        brand: String = Build.BRAND.orEmpty(),
    ): Family {
        val blob = "${manufacturer.lowercase()} ${brand.lowercase()}"
        return when {
            blob.contains("honor") -> Family.HONOR
            blob.contains("xiaomi") ||
                blob.contains("redmi") ||
                blob.contains("poco") ||
                blob.contains("blackshark") -> Family.XIAOMI
            blob.contains("huawei") ||
                blob.contains("harmony") -> Family.HUAWEI
            blob.contains("oppo") ||
                blob.contains("realme") ||
                blob.contains("oneplus") ||
                blob.contains("coloros") -> Family.OPPO
            blob.contains("vivo") ||
                blob.contains("iqoo") -> Family.VIVO
            blob.contains("samsung") -> Family.SAMSUNG
            else -> Family.OTHER
        }
    }

    fun info(context: Context): Map<String, Any?> {
        val family = detectFamily()
        val brand = Build.BRAND.orEmpty().lowercase()
        val manufacturer = Build.MANUFACTURER.orEmpty().lowercase()
        val displayName = when (family) {
            Family.XIAOMI -> when {
                brand.contains("poco") || manufacturer.contains("poco") -> "POCO"
                brand.contains("redmi") || manufacturer.contains("redmi") -> "Redmi"
                else -> "Xiaomi"
            }
            Family.OPPO -> when {
                brand.contains("oneplus") || manufacturer.contains("oneplus") -> "OnePlus"
                brand.contains("realme") || manufacturer.contains("realme") -> "realme"
                else -> "OPPO"
            }
            Family.VIVO -> when {
                brand.contains("iqoo") || manufacturer.contains("iqoo") -> "iQOO"
                else -> "vivo"
            }
            else -> family.displayName
        }
        return mapOf(
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "brand" to (Build.BRAND ?: ""),
            "model" to (Build.MODEL ?: ""),
            "family" to family.id,
            "displayName" to displayName,
            "restricted" to (family != Family.OTHER),
            "batteryOptimizationsIgnored" to isIgnoringBatteryOptimizations(context),
            "canOpenAutoStart" to canOpenAny(context, autoStartCandidates(family)),
            "canOpenOemBattery" to canOpenAny(context, oemBatteryCandidates(context, family)),
        )
    }

    /** @return "oem" | "fallback" | "failed" */
    fun openAutoStart(context: Context): String {
        val family = detectFamily()
        if (tryOpenFirst(context, autoStartCandidates(family))) return "oem"
        if (openAppDetails(context)) return "fallback"
        return "failed"
    }

    /** @return "oem" | "fallback" | "failed" */
    fun openOemBattery(context: Context): String {
        val family = detectFamily()
        if (tryOpenFirst(context, oemBatteryCandidates(context, family))) return "oem"
        if (openRequestIgnoreBattery(context)) return "fallback"
        if (openAppDetails(context)) return "fallback"
        return "failed"
    }

    fun openAppDetails(context: Context): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return startSafe(context, intent)
    }

    fun openRequestIgnoreBattery(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        if (isIgnoringBatteryOptimizations(context)) {
            val list = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (startSafe(context, list)) return true
        }
        val request = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return startSafe(context, request)
    }

    private fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
        return pm?.isIgnoringBatteryOptimizations(context.packageName) == true
    }

    private fun appLabel(context: Context): String {
        return try {
            val appInfo = context.applicationInfo
            context.packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            context.getString(R.string.app_name)
        }
    }

    private fun autoStartCandidates(family: Family): List<Intent> = when (family) {
        Family.XIAOMI -> listOf(
            component(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            ),
            action("miui.intent.action.OP_AUTO_START"),
        )
        Family.HUAWEI -> listOf(
            component(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            component(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
            ),
            component(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.optimize.process.ProtectActivity",
            ),
        )
        Family.HONOR -> listOf(
            component(
                "com.hihonor.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
            component(
                "com.hihonor.systemmanager",
                "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
            ),
            component(
                "com.huawei.systemmanager",
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            ),
        )
        Family.OPPO -> listOf(
            component(
                "com.coloros.safecenter",
                "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            ),
            component(
                "com.oppo.safe",
                "com.oppo.safe.permission.startup.StartupAppListActivity",
            ),
            component(
                "com.coloros.safecenter",
                "com.coloros.safecenter.startupapp.StartupAppListActivity",
            ),
        )
        Family.VIVO -> listOf(
            component(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            ),
            component(
                "com.vivo.permissionmanager",
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            ),
            component(
                "com.iqoo.secure",
                "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
            ),
        )
        Family.SAMSUNG, Family.OTHER -> emptyList()
    }

    private fun oemBatteryCandidates(context: Context, family: Family): List<Intent> =
        when (family) {
            Family.XIAOMI -> listOf(
                component(
                    "com.miui.powerkeeper",
                    "com.miui.powerkeeper.ui.HiddenAppsConfigActivity",
                ).apply {
                    putExtra("package_name", context.packageName)
                    putExtra("package_label", appLabel(context))
                },
                action("miui.intent.action.POWER_HIDE_MODE_APP_LIST"),
                component(
                    "com.miui.securitycenter",
                    "com.miui.powercenter.PowerSettings",
                ),
            )
            Family.HUAWEI -> listOf(
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity",
                ),
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                ),
            )
            Family.HONOR -> listOf(
                component(
                    "com.hihonor.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity",
                ),
                component(
                    "com.hihonor.systemmanager",
                    "com.huawei.systemmanager.optimize.process.ProtectActivity",
                ),
                component(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.power.ui.HwPowerManagerActivity",
                ),
            )
            Family.OPPO -> listOf(
                component(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerUsageModelActivity",
                ),
                component(
                    "com.coloros.oppoguardelf",
                    "com.coloros.powermanager.fuelgaue.PowerConsumptionActivity",
                ),
            )
            Family.VIVO -> listOf(
                component(
                    "com.vivo.abe",
                    "com.vivo.applicationbehaviorengine.ui.ExcessivePowerManagerActivity",
                ),
            )
            Family.SAMSUNG -> listOf(
                component(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                ),
                component(
                    "com.samsung.android.sm",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                ),
            )
            Family.OTHER -> emptyList()
        }

    private fun component(pkg: String, cls: String): Intent =
        Intent().setComponent(ComponentName(pkg, cls))

    private fun action(action: String): Intent =
        Intent(action).addCategory(Intent.CATEGORY_DEFAULT)

    private fun canOpenAny(context: Context, intents: List<Intent>): Boolean {
        val pm = context.packageManager
        return intents.any { resolve(pm, it) != null }
    }

    private fun tryOpenFirst(context: Context, intents: List<Intent>): Boolean {
        for (intent in intents) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (startSafe(context, intent)) return true
        }
        return false
    }

    private fun startSafe(context: Context, intent: Intent): Boolean {
        return try {
            if (resolve(context.packageManager, intent) == null) return false
            context.startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun resolve(pm: PackageManager, intent: Intent) =
        pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
}
