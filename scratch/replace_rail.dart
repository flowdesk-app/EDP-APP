  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
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
                  ),
                ),
              );
            }
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
    );
  }
