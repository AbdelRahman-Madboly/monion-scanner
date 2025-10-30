// android/app/src/main/kotlin/com/vinex/monion_scanner/MainActivity.kt
package com.vinex.monion_scanner

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Method

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vinex.monion/hotspot"
    private lateinit var wifiManager: WifiManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "isHotspotSupported" -> {
                    result.success(isHotspotSupported())
                }
                "isHotspotEnabled" -> {
                    result.success(isHotspotEnabled())
                }
                "enableHotspot" -> {
                    val ssid = call.argument<String>("ssid") ?: "Monion_Camera"
                    val password = call.argument<String>("password") ?: "monion2025"
                    val success = enableHotspot(ssid, password)
                    result.success(success)
                }
                "disableHotspot" -> {
                    val success = disableHotspot()
                    result.success(success)
                }
                "getHotspotConfig" -> {
                    val config = getHotspotConfig()
                    result.success(config)
                }
                "getConnectedDevicesCount" -> {
                    val count = getConnectedDevicesCount()
                    result.success(count)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isHotspotSupported(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+ supports hotspot
                true
            } else {
                // Check if the method exists for older versions
                val method = wifiManager.javaClass.getMethod("isWifiApEnabled")
                method != null
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun isHotspotEnabled(): Boolean {
        return try {
            val method: Method = wifiManager.javaClass.getMethod("isWifiApEnabled")
            method.invoke(wifiManager) as Boolean
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun enableHotspot(ssid: String, password: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+: User must manually enable hotspot
                // We can only open settings
                openHotspotSettings()
                false // Return false as we can't enable programmatically
            } else {
                // Older Android versions (requires reflection)
                val wifiConfigClass = Class.forName("android.net.wifi.WifiConfiguration")
                val wifiConfig = wifiConfigClass.newInstance()
                
                // Set SSID
                val ssidField = wifiConfigClass.getField("SSID")
                ssidField.set(wifiConfig, ssid)
                
                // Set password
                val preSharedKeyField = wifiConfigClass.getField("preSharedKey")
                preSharedKeyField.set(wifiConfig, password)
                
                // Enable hotspot
                val setWifiApMethod = wifiManager.javaClass.getMethod(
                    "setWifiApEnabled",
                    wifiConfigClass,
                    Boolean::class.javaPrimitiveType
                )
                setWifiApMethod.invoke(wifiManager, wifiConfig, true) as Boolean
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun disableHotspot(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+: User must manually disable
                openHotspotSettings()
                false
            } else {
                val setWifiApMethod = wifiManager.javaClass.getMethod(
                    "setWifiApEnabled",
                    Class.forName("android.net.wifi.WifiConfiguration"),
                    Boolean::class.javaPrimitiveType
                )
                setWifiApMethod.invoke(wifiManager, null, false) as Boolean
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun openHotspotSettings() {
        try {
            val intent = android.content.Intent(android.provider.Settings.ACTION_WIRELESS_SETTINGS)
            intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getHotspotConfig(): Map<String, String> {
        return try {
            val method = wifiManager.javaClass.getMethod("getWifiApConfiguration")
            val config = method.invoke(wifiManager)
            
            if (config != null) {
                val ssidField = config.javaClass.getDeclaredField("SSID")
                val preSharedKeyField = config.javaClass.getDeclaredField("preSharedKey")
                
                ssidField.isAccessible = true
                preSharedKeyField.isAccessible = true
                
                mapOf(
                    "ssid" to (ssidField.get(config) as? String ?: "Monion_Camera"),
                    "password" to (preSharedKeyField.get(config) as? String ?: "monion2025")
                )
            } else {
                mapOf("ssid" to "Monion_Camera", "password" to "monion2025")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            mapOf("ssid" to "Monion_Camera", "password" to "monion2025")
        }
    }

    private fun getConnectedDevicesCount(): Int {
        return try {
            // This is a simplified version
            // In production, you'd need to parse /proc/net/arp or use WifiManager APIs
            val runtime = Runtime.getRuntime()
            val process = runtime.exec("cat /proc/net/arp")
            val reader = process.inputStream.bufferedReader()
            val lines = reader.readLines()
            
            // Count valid ARP entries (excluding header and invalid entries)
            var count = 0
            for (i in 1 until lines.size) {
                val line = lines[i]
                if (line.contains("0x2")) { // 0x2 means reachable
                    count++
                }
            }
            count
        } catch (e: Exception) {
            e.printStackTrace()
            0
        }
    }
}