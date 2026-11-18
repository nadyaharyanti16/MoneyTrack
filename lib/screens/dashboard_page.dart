
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/transaction_store.dart';

class DashboardPage extends StatelessWidget {
  final VoidCallback onViewAll;
  final VoidCallback onNotificationTap;

  const DashboardPage({
    super.key,
    required this.onViewAll,
    required this.onNotificationTap,
  });

  static const Color primary = Color(0xFF5267D8);
  static const Color background = Color(0xFFF5F6FA);

  String formatRupiah(num amount) {
    final value = amount.toInt().toString();
    final result = value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $result';
  }

  DateTime parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: TransactionStore.transactions,
      builder: (context, transactions, child) {
        double income = 0;
        double expense = 0;

        for (final item in transactions) {
          final amount = (item['amount'] as num?)?.toDouble() ?? 0;

          if (item['income'] == true) {
            income += amount;
          } else {
            expense += amount;
          }
        }

        final balance = income - expense;

        final latestTransactions = [...transactions]
          ..sort((a, b) {
            final dateA = parseDate(a['date']);
            final dateB = parseDate(b['date']);
            return dateB.compareTo(dateA);
          });

        final displayedTransactions =
            latestTransactions.take(3).toList();

        return Scaffold(
          backgroundColor: background,
          appBar: AppBar(
            backgroundColor: background,
            elevation: 0,
            title: const Text(
              'MoneyTrack',
              style: TextStyle(
                color: primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: onNotificationTap,
                tooltip: 'Lihat FCM Token',
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo, Nadya! 👋',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Yuk, pantau kondisi keuanganmu hari ini.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                // BALANCE CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5267D8),
                        Color(0xFF7486ED),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white70,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Total Saldo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 13),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Divider(color: Colors.white30),
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Keuangan pribadimu',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // SUMMARY
                const Text(
                  'Ringkasan Keuangan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 13),

                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        title: 'Pemasukan',
                        amount: income,
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFF20A779),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        title: 'Pengeluaran',
                        amount: expense,
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFE65B65),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // UANG SAKU AMAN
                AllowanceCard(
                  transactions: transactions,
                ),

                const SizedBox(height: 27),

                // TRANSAKSI TERBARU
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terbaru',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                if (displayedTransactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 45,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Tekan tombol + untuk mencatat transaksi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...displayedTransactions.map((item) {
                    final isIncome = item['income'] == true;
                    final amount =
                        (item['amount'] as num?) ?? 0;
                    final date = parseDate(item['date']);

                    final icon = item['icon'] is IconData
                        ? item['icon'] as IconData
                        : Icons.category_rounded;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 11),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withValues(alpha: 0.10)
                                  : Colors.red.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              icon,
                              color: isIncome
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${item['category']} • ${formatDate(date)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${isIncome ? '+' : '-'}${formatRupiah(amount)}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: isIncome
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// WIDGET UANG SAKU AMAN
// =====================================================

class AllowanceCard extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const AllowanceCard({
    super.key,
    required this.transactions,
  });

  static const Color primary = Color(0xFF5267D8);

  String formatRupiah(num amount) {
    final value = amount.toInt().toString();
    final result = value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $result';
  }

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }

  // EDIT UANG SAKU
  Future<void> editAllowance(BuildContext pageContext) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('allowance');

    final controller = TextEditingController();

    DateTime nextDate = DateTime.now().add(
      const Duration(days: 30),
    );

    try {
      final current = await doc.get();

      if (current.exists) {
        final data = current.data()!;

        controller.text =
            (data['allowanceAmount'] ?? '').toString();

        final savedDate = data['nextDate'];

        if (savedDate is Timestamp) {
          nextDate = savedDate.toDate();
        }
      }

      if (!pageContext.mounted) return;

      await showDialog(
        context: pageContext,
        builder: (dialogContext) {
          bool saving = false;

          return StatefulBuilder(
            builder: (dialogBuildContext, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Atur Uang Saku',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah uang saku yang kamu miliki saat ini',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Contoh: 1000000',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Tanggal menerima uang saku berikutnya',
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final today = DateTime.now();

                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: nextDate.isBefore(today)
                                ? today
                                : nextDate,
                            firstDate: DateTime(
                              today.year,
                              today.month,
                              today.day,
                            ),
                            lastDate: today.add(
                              const Duration(days: 365 * 3),
                            ),
                          );

                          if (picked != null &&
                              dialogContext.mounted) {
                            setDialogState(() {
                              nextDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${nextDate.day}/${nextDate.month}/${nextDate.year}',
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                          },
                    child: const Text('Batal'),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final amount = num.tryParse(
                              controller.text
                                  .replaceAll('.', '')
                                  .replaceAll(',', '')
                                  .trim(),
                            );

                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(pageContext)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Masukkan jumlah uang saku yang valid.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              saving = true;
                            });

                            try {
                              await doc.set({
                                'allowanceAmount': amount,
                                'startDate': Timestamp.fromDate(
                                  DateTime.now(),
                                ),
                                'nextDate': Timestamp.fromDate(
                                  nextDate,
                                ),
                                'updatedAt':
                                    FieldValue.serverTimestamp(),
                              });

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              if (pageContext.mounted) {
                                ScaffoldMessenger.of(pageContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pengaturan uang saku berhasil disimpan.',
                                    ),
                                    backgroundColor: Color(0xFF20A779),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  saving = false;
                                });
                              }

                              if (pageContext.mounted) {
                                ScaffoldMessenger.of(pageContext)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Gagal menyimpan pengaturan: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Simpan'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka pengaturan: $e'),
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  // TAMPILAN UANG SAKU AMAN
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('allowance');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Gagal memuat pengaturan uang saku. Periksa koneksi dan Firestore Rules.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: primary,
            ),
          );
        }

        final data = snapshot.data?.data();

        if (data == null) {
          return _setupCard(context);
        }

        final allowance =
            (data['allowanceAmount'] as num?)?.toDouble() ?? 0;

        final startValue = data['startDate'];
        final nextValue = data['nextDate'];

        final startDate = parseDate(startValue);
        final nextDate = parseDate(nextValue);

        final today = dateOnly(DateTime.now());
        final start = dateOnly(startDate);
        final next = dateOnly(nextDate);

        double spent = 0;

        for (final item in transactions) {
          if (item['income'] == true) continue;

          final amount =
              (item['amount'] as num?)?.toDouble() ?? 0;

          final transactionDate = dateOnly(
            parseDate(item['date']),
          );

          if (!transactionDate.isBefore(start) &&
              !transactionDate.isAfter(today)) {
            spent += amount;
          }
        }

        final remaining = (allowance - spent)
            .clamp(0, allowance)
            .toDouble();

        final daysRemaining = next.difference(today).inDays;

        final dailyLimit = daysRemaining > 0
            ? remaining / daysRemaining
            : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE6E9F5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.savings_rounded,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uang Saku Aman',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Atur pengeluaran harianmu',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => editAllowance(context),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: primary,
                    ),
                    tooltip: 'Ubah uang saku',
                  ),
                ],
              ),

              const SizedBox(height: 18),

              const Text(
                'Sisa uang saku',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),

              Text(
                formatRupiah(remaining),
                style: const TextStyle(
                  color: primary,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      'Uang saku awal',
                      formatRupiah(allowance),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoItem(
                      'Sudah digunakan',
                      formatRupiah(spent),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 10),

              if (daysRemaining > 0) ...[
                const Text(
                  'Rekomendasi batas pengeluaran per hari',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatRupiah(dailyLimit),
                  style: const TextStyle(
                    color: Color(0xFF20A779),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$daysRemaining hari lagi sampai ${nextDate.day}/${nextDate.month}/${nextDate.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  'Tanggal uang saku berikutnya sudah tiba. Perbarui pengaturan uang sakumu.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // KARTU PENGATURAN AWAL
  Widget _setupCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE6E9F5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.savings_rounded,
                color: primary,
                size: 25,
              ),
              SizedBox(width: 10),
              Text(
                'Uang Saku Aman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Atur uang saku dan tanggal penerimaan berikutnya untuk mendapatkan rekomendasi batas pengeluaran harian.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => editAllowance(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Atur Uang Saku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // INFORMASI UANG SAKU
  Widget _infoItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
