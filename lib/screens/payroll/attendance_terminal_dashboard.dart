// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../services/api_service.dart';
import '../../widgets/global_logout_button.dart';
import '../../widgets/payroll_auth_dialog.dart';
import 'camera_permission_guide_dialog.dart';
import 'face_enrollment_dialog.dart';
import 'web_camera_service.dart';

class AttendanceTerminalDashboard extends StatefulWidget {
  final bool showLogout;

  const AttendanceTerminalDashboard({super.key, this.showLogout = true});

  @override
  State<AttendanceTerminalDashboard> createState() => _AttendanceTerminalDashboardState();
}

class _AttendanceTerminalDashboardState extends State<AttendanceTerminalDashboard> {
  final ApiService _api = ApiService();
  final WebCameraService _camera = WebCameraService();

  // Mode: in (Shift Entry), out (Shift Exit)
  String _scanMode = 'in';

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
    _viewId = 'face-terminal-view-${DateTime.now().millisecondsSinceEpoch}';

    _startClock();
    _loadTerminalData();

    if (_camera.isSupported) {
      _camera.registerView(_viewId);
      _camera.listenToPermissionChange((state) {
        if (state == 'granted' && mounted && !_cameraActive) {
          _startStream(userTriggered: false);
        }
      });
      _startStream(userTriggered: false);
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
  }

  Future<void> _loadTerminalData() async {
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

  Future<void> _startStream({bool userTriggered = false}) async {
    setState(() {
      _errorMessage = null;
    });

    final success = await _camera.startCamera();
    if (mounted) {
      setState(() {
        _cameraActive = success;
        _errorMessage = _camera.lastError;
      });
      if (!success && userTriggered) {
        showCameraPermissionGuideDialog(
          context,
          onRetry: () => _startStream(userTriggered: true),
          onUseFallback: () => _captureAndVerifyCameraFrame(forcePicker: true),
        );
      }
    }
  }

  Future<void> _captureAndVerifyCameraFrame({bool forcePicker = false}) async {
    if (_scanning) return;

    try {
      String? snapshot;
      if (forcePicker) {
        snapshot = await _camera.pickAndCaptureSnapshotBase64();
        if (snapshot == null) return;
        setState(() {
          _scanning = true;
          _lastPunchResult = null;
        });
      } else if (!_cameraActive) {
        final started = await _camera.startCamera();
        if (mounted) {
          setState(() {
            _cameraActive = started;
            _errorMessage = _camera.lastError;
          });
        }
        if (!started) {
          return;
        }
        // Small delay to let video stream warm up
        await Future.delayed(const Duration(milliseconds: 300));
        snapshot = _camera.captureSnapshotBase64();
        if (snapshot == null) return;
        setState(() {
          _scanning = true;
          _lastPunchResult = null;
        });
      } else {
        snapshot = _camera.captureSnapshotBase64();
        if (snapshot == null) {
          setState(() {
            _errorMessage = 'Failed to capture frame from webcam. Please try again.';
          });
          return;
        }
        setState(() {
          _scanning = true;
          _lastPunchResult = null;
        });
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

        _api.getTodayAttendance().then((updated) {
          if (mounted) setState(() => _todayPunches = updated);
        });

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

  void _openEnrollmentDialog(EnrolledEmployeeModel employee) async {
    final auth = await PayrollAuthService.ensureAuthorized(context, targetSection: 'Biometrics');
    if (!auth) return;

    if (!mounted) return;
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => FaceEnrollmentDialog(employee: employee),
    );
    if (updated == true) {
      _loadTerminalData();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _overlayDismissTimer?.cancel();
    _camera.stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgSlate = Color(0xFFF8FAFC);
    const navySlate = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: Column(
          children: [
            // Top Executive Header & Real-time Clock
            _buildTopHeader(navySlate),

            // Live Attendance KPI Ribbon
            _buildAttendanceKpiBar(),

            // Main Content Area: Camera Terminal Left (60%), Today's Roster Right (40%)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left 60%: Live Camera Biometric Viewport
                    Expanded(
                      flex: 6,
                      child: _buildCameraTerminalCard(),
                    ),
                    const SizedBox(width: 16),

                    // Right 40%: Today's Live Attendance Feed
                    Expanded(
                      flex: 4,
                      child: _buildTodayPunchesCard(),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Quick Verification Bar for Testing & Enrolled Employees
            _buildBottomQuickBar(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP EXECUTIVE HEADER
  // ============================================================
  Widget _buildTopHeader(Color navySlate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Company Seal / Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.co_present, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),

          // Title & Factory Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'EXCLUSIVE DIAMOND PRODUCTS',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: navySlate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'LIVE TERMINAL ACTIVE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Facial Biometric Attendance & Overtime Tracker • Porur, Chennai Plant',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Real-time Digital Clock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm:ss a').format(_currentTime),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4338CA),
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_currentTime),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          if (widget.showLogout) const GlobalLogoutButton(),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE STATS RIBBON
  // ============================================================
  Widget _buildAttendanceKpiBar() {
    final totalStaff = _enrolledEmployees.isNotEmpty ? _enrolledEmployees.length : 16;
    final totalPresent = _todayPunches.length;
    final activeWorking = _todayPunches.where((p) => p.status == 'Clocked In').length;
    final completedShifts = _todayPunches.where((p) => p.status == 'Completed').length;
    final totalOtHours = _todayPunches.fold<double>(0.0, (s, p) => s + p.overtimeHours);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildMiniStat(Icons.people_outline, 'Total Roster', '$totalStaff Staff', const Color(0xFF475569)),
          const SizedBox(width: 16),
          _buildMiniStat(Icons.check_circle_outline, 'Present Today', '$totalPresent / $totalStaff', const Color(0xFF059669)),
          const SizedBox(width: 16),
          _buildMiniStat(Icons.timelapse, 'Currently On Shift', '$activeWorking Staff', const Color(0xFF2563EB)),
          const SizedBox(width: 16),
          _buildMiniStat(Icons.done_all, 'Shifts Completed', '$completedShifts Shifts', const Color(0xFF0D9488)),
          const SizedBox(width: 16),
          _buildMiniStat(Icons.more_time, 'Overtime Active', '${totalOtHours.toStringAsFixed(1)} hrs', const Color(0xFFD97706)),
          const Spacer(),

          // Shift Action Mode Toggle (Strict Dual Mode: Entry In vs Exit Out)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeTab('in', 'Shift Entry (In)', Icons.login),
                const SizedBox(width: 4),
                _buildModeTab('out', 'Shift Exit (Out)', Icons.logout),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildModeTab(String modeKey, String label, IconData icon) {
    final isSelected = _scanMode == modeKey;
    final activeBg = modeKey == 'in' ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return InkWell(
      onTap: () => setState(() => _scanMode = modeKey),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: activeBg.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAMERA TERMINAL CARD (LEFT 60%)
  // ============================================================
  Widget _buildCameraTerminalCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D), // Dark high-tech camera container
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Live Video Element
          Positioned.fill(
            child: Opacity(
              opacity: _cameraActive ? 1.0 : 0.0,
              child: _camera.buildVideoView(_viewId),
            ),
          ),

          // Fallback UI when camera permissions are needed
          if (!_cameraActive)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined, size: 50, color: Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    const Text(
                      'Camera Permission or Start Needed',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Text(
                        _errorMessage ??
                            'If the browser didn\'t prompt you for permission, click the 🎛️ Tune icon on the left of the URL bar (localhost:5001) and switch Camera to "Allow".',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _startStream(userTriggered: true),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Start / Allow Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4338CA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showCameraPermissionGuideDialog(
                            context,
                            onRetry: () => _startStream(userTriggered: true),
                            onUseFallback: () => _captureAndVerifyCameraFrame(forcePicker: true),
                          ),
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: const Text('How to Allow (Guide)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF93C5FD),
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _captureAndVerifyCameraFrame(forcePicker: true),
                          icon: const Icon(Icons.photo_camera, size: 18),
                          label: const Text('Snap / Upload Photo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Face Targeting Reticle & Oval (when camera active)
          if (_cameraActive)
            Center(
              child: Container(
                width: 260,
                height: 340,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _scanning ? const Color(0xFF10B981) : const Color(0xFF6366F1).withValues(alpha: 0.8),
                    width: 2.5,
                  ),
                  borderRadius: const BorderRadius.all(Radius.elliptical(260, 340)),
                  boxShadow: [
                    BoxShadow(
                      color: (_scanning ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _scanning ? 'MATCHING BIOMETRIC EMBEDDING...' : 'ALIGN FACE IN OVAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: _scanning ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Shift Mode Switcher on Top of Camera Viewport
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _scanMode = 'in'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _scanMode == 'in' ? const Color(0xFF059669) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.login, size: 14, color: _scanMode == 'in' ? Colors.white : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Shift Entry (In)',
                            style: TextStyle(
                              color: _scanMode == 'in' ? Colors.white : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: _scanMode == 'in' ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => setState(() => _scanMode = 'out'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _scanMode == 'out' ? const Color(0xFFDC2626) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 14, color: _scanMode == 'out' ? Colors.white : Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Shift Exit (Out)',
                            style: TextStyle(
                              color: _scanMode == 'out' ? Colors.white : Colors.white70,
                              fontSize: 11.5,
                              fontWeight: _scanMode == 'out' ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan Face Button at Bottom
          if (_lastPunchResult == null)
            Positioned(
              bottom: 24,
              child: ElevatedButton.icon(
                onPressed: _scanning ? null : () => _captureAndVerifyCameraFrame(),
                icon: _scanning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_scanMode == 'out' ? Icons.logout : Icons.face, size: 22),
                label: Text(
                  _scanning
                      ? 'Analyzing Biometrics...'
                      : _scanMode == 'in'
                          ? 'Scan Face & Mark Attendance'
                          : 'Scan Face & Exit',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _scanMode == 'out' ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                ),
              ),
            ),

          // Instant Result Overlay Banner
          if (_lastPunchResult != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildPunchResultBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildPunchResultBanner() {
    final success = _lastPunchResult?['success'] == true;
    final name = _lastPunchResult?['employeeName'] ?? 'Employee';
    final type = _lastPunchResult?['scanType'] ?? _scanMode;
    final timeStr = _lastPunchResult?['time'] ?? DateFormat('hh:mm a').format(DateTime.now());
    final regularHrs = _lastPunchResult?['regularHours'] ?? 0.0;
    final otHrs = _lastPunchResult?['overtimeHours'] ?? 0.0;
    final duration = _lastPunchResult?['totalDurationMinutes'] ?? 0;
    final error = _lastPunchResult?['error'] ?? 'Face not recognized';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: success ? const Color(0xFF064E3B).withValues(alpha: 0.95) : const Color(0xFF7F1D1D).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: success ? const Color(0xFF10B981) : const Color(0xFFEF4444), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(success ? Icons.check_circle : Icons.error, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  success ? 'ATTENDANCE RECORDED: $name' : 'UNREGISTERED PERSON • NOT ENROLLED',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  success
                      ? '${type == 'clock_out' || type == 'out' ? 'Shift Exit (Clock Out)' : 'Shift Entry (Clock In)'} at $timeStr • Duration: ${duration ~/ 60}h ${duration % 60}m (Reg: ${regularHrs}h, OT: ${otHrs}h)'
                      : '$error • Attendance was NOT recorded.',
                  style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => setState(() => _lastPunchResult = null),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY'S LIVE ATTENDANCE ROSTER (RIGHT 40%)
  // ============================================================
  Widget _buildTodayPunchesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, size: 20, color: Color(0xFF4338CA)),
                const SizedBox(width: 8),
                const Text(
                  "Today's Live Punch Feed",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_todayPunches.length} Logs',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Punches List
          Expanded(
            child: _loadingData
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _todayPunches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 42, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            const Text('No Attendance Marked Today Yet', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('Employees will appear here when they scan at the terminal.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _todayPunches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final p = _todayPunches[i];
                          final isClockedIn = p.status == 'Clocked In';
                          final inTime = p.clockInTime != null ? DateFormat('hh:mm a').format(p.clockInTime!) : '--';
                          final outTime = p.clockOutTime != null ? DateFormat('hh:mm a').format(p.clockOutTime!) : (isClockedIn ? 'Active Now' : '--');

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isClockedIn ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isClockedIn ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isClockedIn ? const Color(0xFF10B981) : const Color(0xFF4338CA),
                                  child: Text(
                                    p.employeeName.isNotEmpty ? p.employeeName[0] : 'E',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.employeeName,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'In: $inTime  •  Out: $outTime',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isClockedIn ? const Color(0xFFDCFCE7) : const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isClockedIn ? 'On Shift' : 'Completed',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isClockedIn ? const Color(0xFF15803D) : const Color(0xFF4338CA),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.overtimeHours > 0 ? '+${p.overtimeHours}h OT' : '${p.regularHours}h Reg',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: p.overtimeHours > 0 ? const Color(0xFFD97706) : const Color(0xFF64748B),
                                      ),
                                    ),
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

  // ============================================================
  // BOTTOM QUICK VERIFICATION BAR (TESTING / ENROLLED STAFF)
  // ============================================================
  Widget _buildBottomQuickBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, size: 18, color: _scanMode == 'out' ? const Color(0xFFDC2626) : const Color(0xFF059669)),
          const SizedBox(width: 8),
          Text(
            '16 Staff Roster (${_scanMode == 'out' ? 'Shift Exit' : 'Shift Entry'}):',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _enrolledEmployees.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: '${e.empNo} - ${e.name} (${e.department})\n${e.isFaceEnrolled ? 'Face Registered in Biometrics' : 'Face NOT Registered in Biometrics'}',
                      child: ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: e.isFaceEnrolled ? const Color(0xFF10B981) : Colors.grey.shade400,
                          radius: 9,
                          child: Icon(
                            e.isFaceEnrolled ? Icons.check : Icons.face,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                        label: Text(
                          '${e.empNo} ${e.name}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: e.isFaceEnrolled ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                        backgroundColor: e.isFaceEnrolled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                        side: BorderSide(color: e.isFaceEnrolled ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
                        onPressed: () {
                          if (e.isFaceEnrolled) {
                            _processScanForEmployee(e.email);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${e.name} (${e.empNo}) is not registered in the Biometric Section yet. Please enroll their face in Biometrics first.'),
                                backgroundColor: const Color(0xFFDC2626),
                                action: SnackBarAction(
                                  label: 'Enroll Face',
                                  textColor: Colors.white,
                                  onPressed: () => _openEnrollmentDialog(e),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              if (_enrolledEmployees.isNotEmpty) {
                final pending = _enrolledEmployees.firstWhere((e) => !e.isFaceEnrolled, orElse: () => _enrolledEmployees.first);
                _openEnrollmentDialog(pending);
              }
            },
            icon: const Icon(Icons.person_add, size: 14),
            label: const Text('Enroll Face'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4338CA),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
