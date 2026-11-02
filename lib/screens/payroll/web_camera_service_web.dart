// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraService {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _active = false;

  bool get isSupported => true;
  bool get isCameraActive => _active;

  void registerView(String viewId) {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)';

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => _videoElement!,
    );
  }

  Future<bool> startCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      if (stream != null) {
        _mediaStream = stream;
        _videoElement?.srcObject = stream;
        _active = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  void stopCamera() {
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
      _mediaStream = null;
    }
    _active = false;
  }

  String? captureSnapshotBase64() {
    if (_videoElement == null) return null;
    try {
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640,
        height: _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480,
      );
      final ctx = canvas.context2D;
      ctx.translate(canvas.width!, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(_videoElement!, 0, 0);

      return canvas.toDataUrl('image/jpeg', 0.85);
    } catch (_) {
      return null;
    }
  }

  Widget buildVideoView(String viewId) {
    return HtmlElementView(viewType: viewId);
  }
}
