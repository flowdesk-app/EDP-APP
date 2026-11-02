import 'package:flutter/material.dart';

class WebCameraService {
  String? lastError;
  bool get isSupported => false;
  bool get isCameraActive => false;

  void registerView(String viewId) {}

  Future<bool> startCamera() async {
    return false;
  }

  void stopCamera() {}

  String? captureSnapshotBase64() {
    return null;
  }

  Future<String?> pickAndCaptureSnapshotBase64() async {
    return null;
  }

  Widget buildVideoView(String viewId) {
    return const SizedBox();
  }
}
