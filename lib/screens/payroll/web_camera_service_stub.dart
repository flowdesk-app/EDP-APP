import 'package:flutter/material.dart';

class WebCameraService {
  bool get isSupported => false;
  bool get isCameraActive => false;
  String? lastError;

  void registerView(String viewId) {}
  Future<bool> startCamera() async => false;
  void stopCamera() {}
  String? captureSnapshotBase64() => null;
  Future<String?> pickAndCaptureSnapshotBase64() async => null;
  Widget buildVideoView(String viewId) => const SizedBox.shrink();
  Future<String> getPermissionState() async => 'unknown';
  void listenToPermissionChange(void Function(String state) onStateChanged) {}
}
