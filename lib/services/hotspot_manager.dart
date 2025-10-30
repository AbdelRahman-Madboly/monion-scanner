// lib/services/hotspot_manager.dart
// Purpose: Manage WiFi Hotspot for camera connection

import 'package:flutter/services.dart';

class HotspotManager {
  static const platform = MethodChannel('com.vinex.monion/hotspot');
  
  // Hotspot configuration
  static const String defaultSSID = 'Monion_Camera';
  static const String defaultPassword = 'monion2025';
  
  // Check if hotspot is supported on this device
  Future<bool> isHotspotSupported() async {
    try {
      final bool isSupported = await platform.invokeMethod('isHotspotSupported');
      return isSupported;
    } catch (e) {
      print('Error checking hotspot support: $e');
      return false;
    }
  }
  
  // Check if hotspot is currently enabled
  Future<bool> isHotspotEnabled() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isHotspotEnabled');
      return isEnabled;
    } catch (e) {
      print('Error checking hotspot status: $e');
      return false;
    }
  }
  
  // Enable hotspot with custom SSID and password
  Future<bool> enableHotspot({
    String? ssid,
    String? password,
  }) async {
    try {
      final bool success = await platform.invokeMethod('enableHotspot', {
        'ssid': ssid ?? defaultSSID,
        'password': password ?? defaultPassword,
      });
      return success;
    } catch (e) {
      print('Error enabling hotspot: $e');
      return false;
    }
  }
  
  // Disable hotspot
  Future<bool> disableHotspot() async {
    try {
      final bool success = await platform.invokeMethod('disableHotspot');
      return success;
    } catch (e) {
      print('Error disabling hotspot: $e');
      return false;
    }
  }
  
  // Get hotspot configuration
  Future<Map<String, String>?> getHotspotConfig() async {
    try {
      final Map<dynamic, dynamic> config = 
          await platform.invokeMethod('getHotspotConfig');
      return {
        'ssid': config['ssid'] as String,
        'password': config['password'] as String,
      };
    } catch (e) {
      print('Error getting hotspot config: $e');
      return null;
    }
  }
  
  // Get connected devices count
  Future<int> getConnectedDevicesCount() async {
    try {
      final int count = await platform.invokeMethod('getConnectedDevicesCount');
      return count;
    } catch (e) {
      print('Error getting connected devices: $e');
      return 0;
    }
  }
}