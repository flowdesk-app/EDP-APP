import 'package:flutter/material.dart';
import 'stock_at_edp_screen.dart';

class SpareAtEdpTabsScreen extends StatelessWidget {
  final String? supplierName;
  const SpareAtEdpTabsScreen({super.key, this.supplierName});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Spare at ${supplierName ?? 'EDP'}', style: const TextStyle(color: Color(0xFF202124), fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[700],
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF29B6F6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                  tabs: const [
                    Tab(text: 'New'),
                    Tab(text: 'Re-coating'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            StockAtEdpScreen(jobType: 'New', supplierName: supplierName),
            StockAtEdpScreen(jobType: 'Re-coating', supplierName: supplierName),
          ],
        ),
      ),
    );
  }
}
