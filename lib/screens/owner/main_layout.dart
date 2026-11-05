import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/flowdesk_logo.dart';
import 'owner_dashboard.dart';
import 'create_job_screen.dart';
import 'active_jobs_screen.dart';
import 'ready_for_delivery_screen.dart';
import 'delivered_jobs_screen.dart';

import 'removed_jobs_screen.dart';
import 'part_management_screen.dart';
import 'sales_order_screen.dart';
import 'tax_invoice_screen.dart';
import 'invoice_screen.dart';
import 'spare_production_dashboard_screen.dart';
import 'recoating_dashboard_screen.dart';
import 'raw_materials_screen.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';
import 'storage_screen.dart';
import 'job_approval_screen.dart';
import 'estimates_screen.dart';
import 'delivery_challans_screen.dart';
import '../../widgets/estimate_auth_dialog.dart';
import '../../widgets/payroll_auth_dialog.dart';
import '../payroll/attendance_terminal_dashboard.dart';
import '../payroll/executive_overview_screen.dart';
import '../payroll/salary_statement_screen.dart';
import '../payroll/payslips_screen.dart';
import '../payroll/bank_transfers_screen.dart';
import '../payroll/leave_register_screen.dart';
import '../payroll/personal_loans_screen.dart';
import '../payroll/biometric_registry_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<OwnerDashboardState> _dashboardKey = GlobalKey<OwnerDashboardState>();

  late List<Widget> _screens;
  late List<NavigationRailDestination> _destinations;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = ApiService().currentUser?.role ?? UserRole.employee;
    _buildDestinationsAndScreens();
    _initRole();
  }

  Future<void> _initRole() async {
    await ApiService().ensureInitialized();
    final updatedRole = ApiService().currentUser?.role ?? UserRole.employee;
    if (updatedRole != _role && mounted) {
      setState(() {
        _role = updatedRole;
        _buildDestinationsAndScreens();
      });
    }
  }

  void _buildDestinationsAndScreens() {
    if (_role == UserRole.admin || _role == UserRole.owner) {
      _screens = [
        OwnerDashboard(key: _dashboardKey), // 0. Dashboard
        CreateJobScreen(onNavigateToDashboard: () {
          _dashboardKey.currentState?.reload();
          setState(() => _currentIndex = 0);
        }), // 1. Create Job
        const ActiveJobsScreen(), // 2. EDP Production
        const DeliveredJobsScreen(), // 3. Delivered
        const PartManagementScreen(), // 4. Job Master
        const RemovedJobsScreen(), // 5. Edit
        const SalesOrderScreen(), // 6. Sale Order
        const TaxInvoiceScreen(), // 7. Invoices
        const SpareProductionDashboardScreen(), // 8. Spare at EDP
        const RawMaterialsScreen(), // 9. Raw Materials
        const ReadyForDeliveryScreen(), // 10. Ready for Delivery
        const StorageScreen(), // 11. Database
        const DeliveryChallansScreen(), // 12. Delivery Challan (DC)
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        const NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Create Job')),
        const NavigationRailDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: Text('EDP Production')),
        const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
        const NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Job Master')),
        const NavigationRailDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: Text('Edit')),
        const NavigationRailDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: Text('Sale Order')),
        const NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Invoices')),
        const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('Spare at EDP')),
        const NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: Text('Raw Materials')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
        const NavigationRailDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage), label: Text('Database')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping), selectedIcon: Icon(Icons.local_shipping), label: Text('Delivery Challan')),
      ];

      if (_role == UserRole.owner) {
        _screens.add(
          const JobApprovalScreen(), // 12. Approvals
        );
        _destinations.add(
          const NavigationRailDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: Text('Approvals'),
          ),
        );
        _screens.add(
          const EstimatesScreen(), // 13. Estimates
        );
        _destinations.add(
          const NavigationRailDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: Text('Estimates'),
          ),
        );
      }
    } else if (_role == UserRole.employee1) {
      _screens = [
        const SpareProductionDashboardScreen(),
        const RawMaterialsScreen(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('Spare at EDP')),
        const NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: Text('Raw Materials')),
      ];
    } else if (_role == UserRole.employee2) {
      _screens = [
        const ActiveJobsScreen(),
        const SpareProductionDashboardScreen(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: Text('EDP Production')),
        const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('EDP Spare Prod')),
      ];
    } else if (_role == UserRole.employee3) {
      _screens = [
        const RecoatingDashboardScreen(recoatingJobs: []),
        const ReadyForDeliveryScreen(),
        const DeliveredJobsScreen(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: Text('Re-coating')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
        const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
      ];
    } else if (_role == UserRole.payroll) {
      _screens = [
        const AttendanceTerminalDashboard(), // 0. Live Attendance & Face Terminal (In Payroll Section)
        const ExecutiveOverviewScreen(), // 1. Executive Overview & KPIs
        const SalaryStatementScreen(), // 2. Salary Statement (24 Col)
        const PaySlipsScreen(), // 3. Employee Pay Slips
        const BankTransfersScreen(), // 4. Online Bank Transfers
        const LeaveRegisterScreen(), // 5. Leave & Attendance Register
        const PersonalLoansScreen(), // 6. Staff Personal Loans
        const BiometricRegistryScreen(), // 7. Staff Biometric Registry
      ];
      _destinations = [
        const NavigationRailDestination(
          icon: Icon(Icons.co_present_outlined),
          selectedIcon: Icon(Icons.co_present),
          label: Text('Attendance'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights),
          label: Text('Overview'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.table_chart_outlined),
          selectedIcon: Icon(Icons.table_chart),
          label: Text('Statement'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Pay Slips'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.account_balance_outlined),
          selectedIcon: Icon(Icons.account_balance),
          label: Text('Bank Transfer'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.beach_access_outlined),
          selectedIcon: Icon(Icons.beach_access),
          label: Text('Leave Register'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.request_quote_outlined),
          selectedIcon: Icon(Icons.request_quote),
          label: Text('Staff Loans'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge),
          label: Text('Biometrics'),
        ),
      ];
    } else {
      _screens = [
        const RecoatingDashboardScreen(recoatingJobs: []),
        const ReadyForDeliveryScreen(),
        const DeliveredJobsScreen(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: Text('Re-coating')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
        const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
      ];
    }
  }

  // Mobile Bottom Navigation limits to 4 or 5 typically. We can use a Drawer or "More" tab for mobile.
  // For now, let's show Dashboard, Create, Active, and a Menu to open Drawer.

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: _buildDesktopLayout(),
      mobile: _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          LayoutBuilder(
            builder: (_, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (int index) async {
                        if (index < _screens.length && _screens[index] is EstimatesScreen) {
                          final auth = await EstimateAuthService.ensureAuthorized(context);
                          if (!auth || !mounted) return;
                        }
                        if (_role == UserRole.payroll && index >= 1) {
                          final targetName = index < _destinations.length && _destinations[index].label is Text
                              ? (_destinations[index].label as Text).data
                              : 'Overview';
                          final auth = await PayrollAuthService.ensureAuthorized(context, targetSection: targetName);
                          if (!auth || !mounted) return;
                        }
                        if (index < _screens.length && _screens[index] is OwnerDashboard) {
                          _dashboardKey.currentState?.reload();
                        }
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.white,
                      selectedIconTheme: const IconThemeData(color: Color(0xFF29B6F6)),
                      selectedLabelTextStyle: const TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.bold),
                      trailing: _role == UserRole.payroll
                          ? Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 12),
                              child: IconButton(
                                tooltip: PayrollAuthService.isUnlocked
                                    ? 'Lock Admin Sections (Requires 1212)'
                                    : 'Admin Sections Locked (Click to Unlock)',
                                icon: Icon(
                                  PayrollAuthService.isUnlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                                  color: PayrollAuthService.isUnlocked ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  size: 22,
                                ),
                                onPressed: () async {
                                  if (PayrollAuthService.isUnlocked) {
                                    PayrollAuthService.lock();
                                    setState(() {
                                      _currentIndex = 0; // Return to Attendance
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Payroll admin sections locked. Password (1212) required to re-open.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    final ok = await PayrollAuthService.ensureAuthorized(context, targetSection: 'Overview');
                                    if (ok && mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                            )
                          : null,
                      destinations: _destinations,
                    ),
                  ),
                ),
              );
            }
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _buildCurrentScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentIndex >= _screens.length) return const SizedBox();
    if (_role == UserRole.payroll && _currentIndex >= 1 && !PayrollAuthService.isUnlocked) {
      final targetName = _currentIndex < _destinations.length && _destinations[_currentIndex].label is Text
          ? (_destinations[_currentIndex].label as Text).data ?? 'Overview'
          : 'Overview';
      return PayrollLockedPlaceholder(
        sectionTitle: targetName,
        onUnlocked: () => setState(() {}),
      );
    }
    return _screens[_currentIndex];
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFFF8F9FA)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FlowdeskLogo(fontSize: 32),
              ),
            ),
            ...List.generate(_destinations.length, (index) {
              return ListTile(
                leading: _currentIndex == index ? _destinations[index].selectedIcon : _destinations[index].icon,
                title: _destinations[index].label,
                trailing: (_role == UserRole.payroll && index >= 1 && !PayrollAuthService.isUnlocked)
                    ? const Icon(Icons.lock_outline, size: 16, color: Color(0xFF94A3B8))
                    : null,
                selected: _currentIndex == index,
                selectedColor: const Color(0xFF29B6F6),
                onTap: () async {
                  if (index < _screens.length && _screens[index] is EstimatesScreen) {
                    final auth = await EstimateAuthService.ensureAuthorized(context);
                    if (!auth || !mounted) return;
                  }
                  if (_role == UserRole.payroll && index >= 1) {
                    final targetName = index < _destinations.length && _destinations[index].label is Text
                        ? (_destinations[index].label as Text).data
                        : 'Overview';
                    final auth = await PayrollAuthService.ensureAuthorized(context, targetSection: targetName);
                    if (!auth || !mounted) return;
                  }
                  if (index == 0) {
                    _dashboardKey.currentState?.reload();
                  }
                  setState(() => _currentIndex = index);
                  if (!mounted) return;
                  Navigator.pop(context); // Close drawer
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                PayrollAuthService.lock();
                EstimateAuthService.lock();
                await ApiService().logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: _destinations.length >= 2
          ? BottomNavigationBar(
              currentIndex: _currentIndex >= _destinations.take(4).length ? 0 : _currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) async {
                if (index < _screens.length && _screens[index] is EstimatesScreen) {
                  final auth = await EstimateAuthService.ensureAuthorized(context);
                  if (!auth || !mounted) return;
                }
                if (_role == UserRole.payroll && index >= 1) {
                  final targetName = index < _destinations.length && _destinations[index].label is Text
                      ? (_destinations[index].label as Text).data
                      : 'Overview';
                  final auth = await PayrollAuthService.ensureAuthorized(context, targetSection: targetName);
                  if (!auth || !mounted) return;
                }
                if (index == 0 && (_role == UserRole.admin || _role == UserRole.owner)) {
                  _dashboardKey.currentState?.reload();
                }
                setState(() => _currentIndex = index);
              },
              selectedItemColor: _currentIndex >= _destinations.take(4).length ? const Color(0xFF5F6368) : const Color(0xFF29B6F6),
              unselectedItemColor: const Color(0xFF5F6368),
              items: _destinations.take(4).map((d) {
                return BottomNavigationBarItem(
                  icon: d.icon,
                  activeIcon: d.selectedIcon,
                  label: (d.label as Text).data,
                );
              }).toList(),
            )
          : null,
    );
  }
}
