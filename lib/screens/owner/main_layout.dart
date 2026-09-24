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
import 'invoice_screen.dart';
import 'spare_production_dashboard_screen.dart';
import 'recoating_dashboard_screen.dart';
import 'raw_materials_screen.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../login_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Widget> _screens;
  late List<NavigationRailDestination> _destinations;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    _role = ApiService().currentUser?.role ?? UserRole.employee;
    _buildDestinationsAndScreens();
  }

  void _buildDestinationsAndScreens() {
    _screens = [];
    _destinations = [];
    
    if (_role == UserRole.admin) {
      _screens = [
        const OwnerDashboard(), // 0. Dashboard
        CreateJobScreen(onNavigateToDashboard: () => setState(() => _currentIndex = 0)), // 1. Create Job
        const ActiveJobsScreen(), // 2. Active Jobs
        const DeliveredJobsScreen(), // 3. Delivered
        const PartManagementScreen(), // 4. Job Names (Parts)
        const RemovedJobsScreen(), // 5. Edit
        const InvoiceScreen(), // 6. Invoices
        const SpareProductionDashboardScreen(), // 7. Spare at EDP
        const RawMaterialsScreen(), // 8. Raw Materials
        const ReadyForDeliveryScreen(), // 9. Ready for Delivery
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        const NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Create Job')),
        const NavigationRailDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: Text('EDP Production')),
        const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
        const NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Job Master')),
        const NavigationRailDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: Text('Edit')),
        const NavigationRailDestination(icon: Icon(Icons.receipt_outlined), selectedIcon: Icon(Icons.receipt), label: Text('Invoices')),
        const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('Spare at EDP')),
        const NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: Text('Raw Materials')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
      ];
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
        RecoatingDashboardScreen(recoatingJobs: []),
        const ReadyForDeliveryScreen(),
        const DeliveredJobsScreen(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.build_circle_outlined), selectedIcon: Icon(Icons.build_circle), label: Text('Re-coating')),
        const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
        const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
      ];
    } else {
      _screens = [
        const OwnerDashboard(),
      ];
      _destinations = [
        const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
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
          NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: Color(0xFF29B6F6)),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.bold),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FlowdeskLogo(fontSize: 18),
                  const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await ApiService().logout();
                      if (context.mounted) {
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
            destinations: _destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
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
                selected: _currentIndex == index,
                selectedColor: const Color(0xFF29B6F6),
                onTap: () {
                  setState(() => _currentIndex = index);
                  Navigator.pop(context); // Close drawer
                },
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                await ApiService().logout();
                if (context.mounted) {
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
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: _currentIndex > 3 ? const Color(0xFF5F6368) : const Color(0xFF29B6F6),
        unselectedItemColor: const Color(0xFF5F6368),
        items: _destinations.take(4).map((d) {
          return BottomNavigationBarItem(
            icon: d.icon,
            activeIcon: d.selectedIcon,
            label: (d.label as Text).data,
          );
        }).toList(),
      ),
    );
  }
}
