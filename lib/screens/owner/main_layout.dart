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
import 'stock_at_edp_screen.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

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
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = ApiService().currentUser?.role == UserRole.admin;
    
    _screens = [
      const OwnerDashboard(), // 0. Dashboard
      CreateJobScreen(onNavigateToDashboard: () => setState(() => _currentIndex = 0)), // 1. Create Job
      const ActiveJobsScreen(), // 2. Active Jobs
      const DeliveredJobsScreen(), // 3. Delivered
      if (_isAdmin) const PartManagementScreen(), // 4. Job Names (Parts)
      if (_isAdmin) const RemovedJobsScreen(), // 5. Edit
      if (_isAdmin) const StockAtEdpScreen(), // 6. Spare at EDP
      if (_isAdmin) const ReadyForDeliveryScreen(), // 7. Ready for Delivery
    ];

    _destinations = [
      const NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
      const NavigationRailDestination(icon: Icon(Icons.add_box_outlined), selectedIcon: Icon(Icons.add_box), label: Text('Create Job')),
      const NavigationRailDestination(icon: Icon(Icons.list_alt), selectedIcon: Icon(Icons.list), label: Text('EDP Production')),
      const NavigationRailDestination(icon: Icon(Icons.check_circle_outline), selectedIcon: Icon(Icons.check_circle), label: Text('Delivered')),
      if (_isAdmin) const NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Job Master')),
      if (_isAdmin) const NavigationRailDestination(icon: Icon(Icons.edit_outlined), selectedIcon: Icon(Icons.edit), label: Text('Edit')),
      if (_isAdmin) const NavigationRailDestination(icon: Icon(Icons.inventory_outlined), selectedIcon: Icon(Icons.inventory), label: Text('Spare at EDP')),
      if (_isAdmin) const NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Ready for Delivery')),
    ];
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
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: FlowdeskLogo(fontSize: 18),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), activeIcon: Icon(Icons.list), label: 'EDP Production'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Delivered'),
        ],
      ),
    );
  }
}
