
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

import '../data/transaction_store.dart';
import 'dashboard_page.dart';
import 'transaction_page.dart';
import 'statistics_page.dart';
import 'profile_page.dart';
import 'add_transaction_page.dart';
import '../widgets/app_bottom_nav.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    TransactionStore.initialize();
  }

  @override
  void dispose() {
    TransactionStore.dispose();
    super.dispose();
  }

  void openTransactions() {
    setState(() {
      selectedIndex = 1;
    });
  }

  Future<void> openAddTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionPage(),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  // Mengambil dan menampilkan FCM Token
  Future<void> showFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Color(0xFF5267D8),
                ),
                SizedBox(width: 10),
                Text('FCM Token'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: token == null
                  ? const Text('Token belum tersedia.')
                  : SelectableText(
                      token,
                      style: const TextStyle(fontSize: 12),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Tutup'),
              ),
              if (token != null)
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: token),
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FCM Token berhasil disalin'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Salin Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5267D8),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil FCM Token: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(
  onViewAll: openTransactions,
  onNotificationTap: showFCMToken,
),
      const TransactionPage(),
      const StatisticsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      floatingActionButton:
          selectedIndex == 0 || selectedIndex == 1
              ? FloatingActionButton(
                  onPressed: openAddTransaction,
                  backgroundColor: const Color(0xFF5267D8),
                  foregroundColor: Colors.white,
                  elevation: 3,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 30,
                  ),
                )
              : null,

      bottomNavigationBar: AppBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
