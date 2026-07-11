import 'package:flutter/material.dart';

class EDPSpareProductionScreen extends StatelessWidget {
  const EDPSpareProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EDP Spare Production'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            labelColor: Color(0xFF29B6F6),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF29B6F6),
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'Re-coating'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('New (To be implemented)')),
            Center(child: Text('Re-coating (To be implemented)')),
          ],
        ),
      ),
    );
  }
}
