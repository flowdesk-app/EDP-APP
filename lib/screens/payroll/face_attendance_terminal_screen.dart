import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import 'web_camera_service.dart';

class FaceAttendanceTerminalScreen extends StatefulWidget {
  const FaceAttendanceTerminalScreen({super.key});

  @override
  State<FaceAttendanceTerminalScreen> createState() => _FaceAttendanceTerminalScreenState();
}

class _FaceAttendanceTerminalScreenState extends State<FaceAttendanceTerminalScreen> {
  final ApiService _api = ApiService();
  final WebCameraService _camera = WebCameraService();

  // Mode: auto, in, out
  String _scanMode = 'auto';

  // State
  bool _cameraActive = false;
  bool _scanning = false;
  String? _errorMessage;
  String _viewId = '';

  // Real-time clock timer
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Data
  List<EnrolledEmployeeModel> _enrolledEmployees = [];
  List<AttendanceModel> _todayPunches = [];
  bool _loadingData = true;

  // Last verified punch result for overlay
  Map<String, dynamic>? _lastPunchResult;
  Timer? _overlayDismissTimer;

  @override
  void initState() {
    super.initState();
    _viewId = 'face-terminal-video-${DateTime.now().millisecondsSinceEpoch}';

    _startClock();
    _loadTerminalData();

    if (_camera.isSupported) {
      _camera.registerView(_viewId);
      _startStream();
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _loadTerminalData() async {
    setState(() => _loadingData = true);
    try {
      final employees = await _api.getEnrolledEmployees();
      final punches = await _api.getTodayAttendance();
      if (mounted) {
        setState(() {
          _enrolledEmployees = employees;
          _todayPunches = punches;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _startStream() async {
    final active = await _camera.startCamera();
    if (mounted) {
      setState(() {
        _cameraActive = active;
        if (!active) {
          _errorMessage = 'Webcam not available. You can also use the Quick Punch buttons below.';
        } else {
          _errorMessage = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _overlayDismissTimer?.cancel();
    _camera.stopCamera();
    super.dispose();
  }

  Future<void> _captureAndVerifyCameraFrame() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _lastPunchResult = null;
    });

    try {
      final snapshot = _camera.captureSnapshotBase64();
      if (snapshot == null) {
        setState(() {
          _scanning = false;
          _lastPunchResult = {
            'success': false,
            'message': 'Webcam not active. Please allow browser camera access, or click a quick employee button below.',
          };
        });
        return;
      }

      final res = await _api.verifyCameraFrame(
        imageBase64: snapshot,
        scanType: _scanMode,
      );

      if (mounted) {
        setState(() {
          _scanning = false;
          _lastPunchResult = res;
        });

        // Refresh today's punches list
        _api.getTodayAttendance().then((updated) {
          if (mounted) setState(() => _todayPunches = updated);
        });

        // Auto dismiss overlay after 8 seconds (or 5 for success)
        _overlayDismissTimer?.cancel();
        _overlayDismissTimer = Timer(Duration(seconds: res['success'] == true ? 5 : 8), () {
          if (mounted) setState(() => _lastPunchResult = null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _lastPunchResult = {'success': false, 'error': e.toString()};
        });
      }
    }
  }

  Future<void> _processScanForEmployee(String email) async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _lastPunchResult = null;
    });

    try {
      final res = await _api.recordAttendanceScan(
        email: email,
        scanType: _scanMode,
        scanMethod: 'face_recognition',
      );

      if (mounted) {
        setState(() {
          _scanning = false;
          _lastPunchResult = res;
        });

        // Refresh today's punches list
        _api.getTodayAttendance().then((updated) {
          if (mounted) setState(() => _todayPunches = updated);
        });

        // Auto dismiss overlay after 4 seconds
        _overlayDismissTimer?.cancel();
        _overlayDismissTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) setState(() => _lastPunchResult = null);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _lastPunchResult = {'success': false, 'error': e.toString()};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121820),
      body: SafeArea(
        child: Column(
          children: [
            // Top Kiosk Bar
            _buildTopKioskBar(),

            // Main Content Area (Camera Left, Punch Feed Right)
            Expanded(
              child: Row(
                children: [
                  // Left: Camera Biometric Viewport
                  Expanded(
                    flex: 6,
                    child: _buildCameraViewport(),
                  ),

                  // Vertical Separator
                  Container(width: 1, color: const Color(0xFF263238)),

                  // Right: Today's Active Punches & Summary
                  Expanded(
                    flex: 4,
                    child: _buildTodayPunchesPanel(),
                  ),
                ],
              ),
            ),

            // Bottom Quick Verification Bar
            _buildBottomQuickBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopKioskBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF1A232F),
        border: Border(bottom: BorderSide(color: Color(0xFF263238))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            tooltip: 'Back to Payroll Dashboard',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.center_focus_strong, color: Color(0xFF29B6F6), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'EXCLUSIVE DIAMOND PRODUCTS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE TERMINAL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF81C784)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Facial Biometric Attendance & Overtime Tracker System',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),

          // Real-time Clock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('hh:mm:ss a').format(_currentTime),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29B6F6),
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(_currentTime),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraViewport() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera Video Stream or Fallback
          if (_cameraActive)
            _camera.buildVideoView(_viewId)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Connecting to company camera...',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _startStream,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry Camera'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ],
              ),
            ),

          // Dark vignette overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.6),
                ],
                radius: 0.9,
              ),
            ),
          ),

          // Biometric Face Target Oval & Crosshairs
          Positioned.fill(
            child: Center(
              child: Container(
                width: 280,
                height: 360,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _scanning ? const Color(0xFF00E676) : const Color(0xFF29B6F6).withValues(alpha: 0.8),
                    width: 2.5,
                  ),
                  borderRadius: const BorderRadius.all(Radius.elliptical(280, 360)),
                  boxShadow: [
                    BoxShadow(
                      color: (_scanning ? const Color(0xFF00E676) : const Color(0xFF29B6F6)).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner targeting brackets
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _scanning ? 'MATCHING BIOMETRIC...' : 'ALIGN FACE IN FRAME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _scanning ? const Color(0xFF00E676) : const Color(0xFF29B6F6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mode Selector (Top Left of camera)
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2836).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF37474F)),
              ),
              child: Row(
                children: [
                  _modeButton('auto', 'Smart Auto', Icons.auto_mode),
                  const SizedBox(width: 4),
                  _modeButton('in', 'Shift Entry (In)', Icons.login),
                  const SizedBox(width: 4),
                  _modeButton('out', 'Shift Exit (Out)', Icons.logout),
                ],
              ),
            ),
          ),

          // Instant Punch Result Banner
          if (_lastPunchResult != null)
            Positioned(
              bottom: 30,
              left: 40,
              right: 40,
              child: _buildPunchResultBanner(),
            )
          else if (!_scanning)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _captureAndVerifyCameraFrame,
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: Text(
                    _scanMode == 'in'
                        ? 'SCAN ENTRY (CLOCK-IN)'
                        : (_scanMode == 'out' ? 'SCAN EXIT (CLOCK-OUT)' : 'SCAN FACE ATTENDANCE'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.8),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scanMode == 'in'
                        ? const Color(0xFF00E676)
                        : (_scanMode == 'out' ? const Color(0xFF0288D1) : const Color(0xFF00E676)),
                    foregroundColor: const Color(0xFF0D1B2A),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                  ),
                ),
              ),
            ),

          if (_scanning)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF29B6F6)),
                    SizedBox(height: 16),
                    Text(
                      'Analyzing facial landmarks...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeButton(String modeKey, String label, IconData icon) {
    final isSelected = _scanMode == modeKey;
    return InkWell(
      onTap: () => setState(() => _scanMode = modeKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0288D1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceAvatar({
    String? photoUrl,
    String? email,
    String? name,
    double radius = 24,
  }) {
    ImageProvider? provider;
    if (email == 'employee1@flowdesk.com' || (photoUrl != null && photoUrl.contains('user_face'))) {
      provider = const AssetImage('assets/images/faces/user_face.jpg');
    } else if (email == 'employee2@flowdesk.com' || (photoUrl != null && photoUrl.contains('friend_face'))) {
      provider = const AssetImage('assets/images/faces/friend_face.png');
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        provider = NetworkImage(photoUrl);
      } else {
        provider = NetworkImage('${_api.baseUrl.replaceAll('/api', '')}$photoUrl');
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0288D1).withValues(alpha: 0.2),
      backgroundImage: provider,
      child: provider == null
          ? Text(
              (name != null && name.isNotEmpty) ? name.substring(0, 1).toUpperCase() : 'E',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF29B6F6),
              ),
            )
          : null,
    );
  }

  Widget _buildPunchResultBanner() {
    final res = _lastPunchResult!;
    final isSuccess = res['success'] == true;
    final isClockIn = res['actionTaken'] == 'in';
    final isClockOut = res['actionTaken'] == 'out';
    final record = res['record'] != null ? AttendanceModel.fromJson(res['record']) : null;
    final empData = res['employee'] is Map ? res['employee'] as Map : null;
    final photoUrl = empData != null ? empData['photoUrl']?.toString() : null;
    final empEmail = empData != null ? empData['email']?.toString() : (record?.employeeEmail);
    final empName = empData != null ? empData['name']?.toString() : (record?.employeeName);

    final bgColor = isSuccess
        ? (isClockIn ? const Color(0xFF1B5E20) : const Color(0xFF0D47A1))
        : const Color(0xFFB71C1C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isSuccess && (empEmail != null || photoUrl != null)) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isClockIn ? const Color(0xFF00E676) : const Color(0xFF40C4FF),
                  width: 2.5,
                ),
              ),
              child: _buildFaceAvatar(
                photoUrl: photoUrl,
                email: empEmail,
                name: empName,
                radius: 26,
              ),
            ),
            const SizedBox(width: 14),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? (isClockIn ? Icons.login : Icons.logout) : Icons.error_outline,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      isSuccess
                          ? (isClockIn ? 'SHIFT ENTRY VERIFIED' : 'SHIFT EXIT VERIFIED')
                          : 'SCAN NOTICE',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white70,
                      ),
                    ),
                    if (res['score'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Match: ${((res['score'] as num).toDouble() * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  res['message'] ?? res['error'] ?? (isSuccess ? 'Biometric scan verified' : 'Scan failed'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (record != null && isClockOut) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Standard Shift: ${record.regularHours} hrs',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: record.overtimeHours > 0 ? const Color(0xFFFFA000) : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          record.overtimeHours > 0 ? '+${record.overtimeHours} hrs Overtime' : '0 OT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: record.overtimeHours > 0 ? Colors.black87 : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => setState(() => _lastPunchResult = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPunchesPanel() {
    final activeInShift = _todayPunches.where((p) => p.clockInTime != null && p.clockOutTime == null).length;
    final completedShifts = _todayPunches.where((p) => p.status == 'Completed').length;
    final totalOtHours = _todayPunches.fold<double>(0.0, (sum, p) => sum + p.overtimeHours);

    return Container(
      color: const Color(0xFF161E28),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: Color(0xFF29B6F6), size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's Attendance Feed",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                tooltip: 'Refresh Punches',
                onPressed: _loadTerminalData,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Counters Bar
          Row(
            children: [
              _metricChip('On Shift', '$activeInShift', const Color(0xFF0288D1), const Color(0xFFE1F5FE)),
              const SizedBox(width: 8),
              _metricChip('Completed', '$completedShifts', const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
              const SizedBox(width: 8),
              _metricChip('Total OT', '${totalOtHours.toStringAsFixed(1)}h', const Color(0xFFF57C00), const Color(0xFFFFF3E0)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFF263238)),

          // Punches List
          Expanded(
            child: _loadingData
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF29B6F6)))
                : _todayPunches.isEmpty
                    ? const Center(
                        child: Text(
                          'No attendance punches recorded yet today.\nAlign your face in the camera frame to scan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _todayPunches.length,
                        itemBuilder: (ctx, index) {
                          final p = _todayPunches[index];
                          final isCompleted = p.status == 'Completed';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2836),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCompleted ? const Color(0xFF2E7D32).withValues(alpha: 0.5) : const Color(0xFF0288D1).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildFaceAvatar(
                                      email: p.employeeEmail,
                                      name: p.employeeName,
                                      radius: 15,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.employeeName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                          ),
                                          Text(
                                            p.department ?? 'Production',
                                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isCompleted ? const Color(0xFF2E7D32).withValues(alpha: 0.2) : const Color(0xFF0288D1).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isCompleted ? 'Completed' : 'On Shift',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isCompleted ? const Color(0xFF81C784) : const Color(0xFF4FC3F7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.login, size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.clockInTime != null ? DateFormat('hh:mm a').format(p.clockInTime!) : '--',
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.logout, size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.clockOutTime != null ? DateFormat('hh:mm a').format(p.clockOutTime!) : 'Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: p.clockOutTime != null ? Colors.white70 : const Color(0xFF4FC3F7),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isCompleted) ...[
                                      Text(
                                        '${p.regularHours}h Basic',
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                      if (p.overtimeHours > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFA000).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '+${p.overtimeHours}h OT',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2836),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF263238)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomQuickBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A232F),
        border: Border(top: BorderSide(color: Color(0xFF263238))),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_outlined, size: 16, color: Color(0xFF29B6F6)),
          const SizedBox(width: 8),
          const Text(
            'Enrolled Faces:',
            style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _enrolledEmployees.map((emp) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF263238),
                      avatar: _buildFaceAvatar(
                        photoUrl: emp.facePhotoUrl,
                        email: emp.email,
                        name: emp.name,
                        radius: 12,
                      ),
                      label: Text(
                        emp.name,
                        style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => _processScanForEmployee(emp.email),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
