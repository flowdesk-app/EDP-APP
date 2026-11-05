import 'package:flutter/material.dart';

/// Shows an informative, interactive modal dialog explaining why modern browsers
/// do not show the camera permission prompt again once dismissed/blocked, and
/// providing exact 2-step instructions to unblock it in Chrome / Safari on macOS.
Future<void> showCameraPermissionGuideDialog(
  BuildContext context, {
  VoidCallback? onRetry,
  VoidCallback? onUseFallback,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFFF59E0B),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Camera Permission Blocked',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Why the browser won\'t show the popup again',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Explanation notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'By web browser security policy, once camera access is dismissed or blocked once, Google Chrome and Safari permanently suppress the popup prompt on this site so you aren\'t spammed. You can re-enable it in 2 clicks below.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Step 1: In the Browser Address Bar
              _buildStepCard(
                stepNumber: '1',
                title: 'Allow in Browser Address Bar (Instant)',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Look at the top of your browser window at the website address bar (URL):',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF475569)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tune, color: Color(0xFF60A5FA), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'localhost:5001',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.videocam_off, color: Color(0xFFF87171), size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Click the 🎛️ Tune icon (or 🔒 Lock icon) on the left of the address bar.\n• Find "Camera" and change it from Block to "Allow".\n• As soon as you flip it, this page auto-detects it immediately!',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Step 2: macOS System Permissions (For Mac)
              _buildStepCard(
                stepNumber: '2',
                title: 'Verify Mac System Settings (macOS)',
                content: const Text(
                  'On your Mac, check that macOS has granted Chrome / Safari camera access:\n'
                  '• Click the Apple menu  -> System Settings\n'
                  '• Go to Privacy & Security -> Camera\n'
                  '• Ensure Google Chrome (or Safari) is toggled ON.',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick alternative
              if (onUseFallback != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4338CA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.photo_camera_back, color: Color(0xFFA5B4FC), size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No webcam? You can also use Snap / Upload Photo anytime.',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 11.5),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onUseFallback();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Snap Photo', style: TextStyle(color: Color(0xFF818CF8), fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    ),
  );
}

Widget _buildStepCard({
  required String stepNumber,
  required String title,
  required Widget content,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF334155)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF4338CA),
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              content,
            ],
          ),
        ),
      ],
    ),
  );
}
