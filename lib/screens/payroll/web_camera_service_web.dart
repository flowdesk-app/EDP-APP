// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraService {
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _active = false;
  String? lastError;

  bool get isSupported => true;
  bool get isCameraActive => _active;

  void registerView(String viewId) {
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)';

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => _videoElement!,
    );
  }

  String _formatCameraError(dynamic err) {
    final str = err.toString();
    if (str.contains('NotAllowedError') || str.contains('PermissionDeniedError') || str.contains('Permission denied')) {
      return 'Camera permission was blocked. Please click the lock or camera icon on the left of the website address bar (https://...) and set Camera to "Allow", then click Retry.';
    }
    if (str.contains('NotFoundError') || str.contains('DevicesNotFoundError')) {
      return 'No webcam detected on this computer. Please connect a webcam or enable your laptop camera in Windows Settings.';
    }
    if (str.contains('NotReadableError') || str.contains('TrackStartError')) {
      return 'Camera is being used by another application (e.g. WhatsApp, Teams, or Zoom). Please close other apps using the camera and click Retry.';
    }
    if (str.contains('OverconstrainedError')) {
      return 'The webcam resolution constraint was not supported by your camera hardware.';
    }
    return 'Camera access error: $str. Please allow camera permissions in your browser.';
  }

  Future<bool> startCamera() async {
    lastError = null;

    try {
      html.MediaStream stream;

      // 1. First try relaxed user-facing video constraints (compatible with most laptops)
      try {
        stream = await html.window.navigator.mediaDevices!.getUserMedia({
          'video': {
            'facingMode': 'user',
          },
          'audio': false,
        });
      } catch (err1) {
        // 2. Fallback to basic video: true for hardware with proprietary drivers or older webcams
        try {
          stream = await html.window.navigator.mediaDevices!.getUserMedia({
            'video': true,
            'audio': false,
          });
        } catch (err2) {
          lastError = _formatCameraError(err2);
          _active = false;
          return false;
        }
      }

      _mediaStream = stream;
      if (_videoElement != null) {
        _videoElement!.srcObject = stream;
        try {
          await _videoElement!.play();
        } catch (_) {}
      }
      _active = true;
      return true;
    } catch (e) {
      lastError = _formatCameraError(e);
      _active = false;
    }
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
    if (_videoElement == null || !_active) return null;
    try {
      final w = _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640;
      final h = _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480;

      final canvas = html.CanvasElement(width: w, height: h);
      final ctx = canvas.context2D;
      ctx.translate(w, 0);
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
