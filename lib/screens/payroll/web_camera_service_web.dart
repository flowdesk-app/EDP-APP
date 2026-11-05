// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraService {
  html.VideoElement? _videoElement;
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

  String _formatCameraError(String str) {
    if (str.contains('NotAllowedError') || str.contains('PermissionDeniedError') || str.contains('Permission denied')) {
      return 'Camera access is currently blocked by your browser.\n\n⚠️ Why the browser doesn\'t prompt again:\nBrowsers remember your previous "Block" choice and will NOT show the permission prompt again until you allow it in your URL bar.\n\nHow to unblock in 2 clicks:\n1. Look at your browser address bar at the very top.\n2. Click the 🎛️ Tune / Lock 🔒 icon on the left of the website URL.\n3. Change "Camera" to "Allow".\n4. On Mac: Also verify Apple Menu  -> System Settings -> Privacy & Security -> Camera.';
    }
    if (str.contains('NotFoundError') || str.contains('DevicesNotFoundError')) {
      return 'No camera hardware found. Please verify your laptop camera privacy slider/switch is open, or use Snap / Upload Photo below.';
    }
    if (str.contains('NotReadableError') || str.contains('TrackStartError')) {
      return 'Camera is being used by another application (WhatsApp, Teams, Zoom, or FaceTime). Please close other apps and click Start / Allow Camera.';
    }
    return 'Camera access error: $str';
  }

  Future<String> getPermissionState() async {
    try {
      if (js.context.hasProperty('getCameraPermissionState')) {
        final res = js.context.callMethod('getCameraPermissionState');
        return res?.toString() ?? 'unknown';
      }
    } catch (_) {}
    return 'unknown';
  }

  void listenToPermissionChange(void Function(String state) onStateChanged) {
    try {
      js.context['_onCameraPermissionChanged'] = js.JsFunction.withThis((self, [dynamic state]) {
        onStateChanged(state?.toString() ?? '');
      });
    } catch (_) {}
  }

  Future<bool> startCamera() async {
    lastError = null;

    try {
      // 1. Try native JS startWebcam with callback first
      if (js.context.hasProperty('startWebcam')) {
        final completer = Completer<bool>();
        js.context.callMethod('startWebcam', [
          js.JsFunction.withThis((self, [dynamic res]) {
            final isSuccess = res != null && res['success'] == true;
            if (isSuccess) {
              _active = true;
              if (_videoElement != null && js.context.hasProperty('attachWebcamToVideo')) {
                js.context.callMethod('attachWebcamToVideo', [_videoElement]);
              }
              completer.complete(true);
            } else {
              final errStr = res != null ? res['error']?.toString() ?? 'Webcam access denied' : 'Webcam access denied';
              lastError = _formatCameraError(errStr);
              _active = false;
              completer.complete(false);
            }
          })
        ]);
        return await completer.future;
      }

      // 2. Fallback to standard dart:html getUserMedia
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': true,
        'audio': false,
      });

      if (_videoElement != null) {
        _videoElement!.srcObject = stream;
        try {
          await _videoElement!.play();
        } catch (_) {}
      }
      _active = true;
      return true;
    } catch (e) {
      lastError = _formatCameraError(e.toString());
      _active = false;
    }
    return false;
  }

  void stopCamera() {
    try {
      if (js.context.hasProperty('stopWebcam')) {
        js.context.callMethod('stopWebcam');
      }
    } catch (_) {}
    _active = false;
  }

  String? captureSnapshotBase64() {
    try {
      if (_videoElement != null && js.context.hasProperty('captureWebcamFrame')) {
        final res = js.context.callMethod('captureWebcamFrame', [_videoElement]);
        if (res != null && res.toString().isNotEmpty) {
          return res.toString();
        }
      }

      if (_videoElement == null || !_active) return null;
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

  Future<String?> pickAndCaptureSnapshotBase64() {
    final completer = Completer<String?>();
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      input.onChange.listen((e) {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsDataUrl(files[0]);
          reader.onLoadEnd.listen((_) {
            completer.complete(reader.result?.toString());
          });
        } else {
          completer.complete(null);
        }
      });
    } catch (_) {
      completer.complete(null);
    }
    return completer.future;
  }

  Widget buildVideoView(String viewId) {
    return HtmlElementView(viewType: viewId);
  }
}
