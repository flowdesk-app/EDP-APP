import 'package:flutter/material.dart';
import 'stock_at_edp_screen.dart';

class EDPSpareProductionScreen extends StatelessWidget {
  const EDPSpareProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Spare at EDP', style: TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
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
            StockAtEdpScreen(jobType: 'New'),
            StockAtEdpScreen(jobType: 'Re-coating'),
          ],
        ),
      ),
    );
  }
}
