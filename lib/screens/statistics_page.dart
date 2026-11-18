
import 'package:flutter/material.dart';
import '../data/transaction_store.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  static const Color primary = Color(0xFF5267D8);
  static const Color green = Color(0xFF20A779);
  static const Color red = Color(0xFFE65B65);

  String formatRupiah(num amount) {
    final number = amount.toInt().toString();

    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: TransactionStore.transactions,
      builder: (context, transactions, child) {
        double income = 0;
        double expense = 0;

        final Map<String, double> categoryExpenses = {};

        for (final item in transactions) {
          final amount = (item['amount'] as num).toDouble();

          if (item['income'] == true) {
            income += amount;
          } else {
            expense += amount;

            final category = item['category'].toString();

            categoryExpenses[category] =
                (categoryExpenses[category] ?? 0) + amount;
          }
        }

        final balance = income - expense;
        final total = income + expense;

        final sortedCategories = categoryExpenses.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            title: const Text(
              'Statistik Keuangan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOTAL SALDO
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        primary,
                        Color(0xFF7486ED),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Saldo',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatRupiah(balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${transactions.length} transaksi tercatat',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // RINGKASAN
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
                        'Pemasukan',
                        income,
                        green,
                        Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Pengeluaran',
                        expense,
                        red,
                        Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 27),

                // PERBANDINGAN
                const Text(
                  'Perbandingan Keuangan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _comparisonRow(
                        'Pemasukan',
                        income,
                        total == 0 ? 0 : income / total,
                        green,
                      ),
                      const SizedBox(height: 20),
                      _comparisonRow(
                        'Pengeluaran',
                        expense,
                        total == 0 ? 0 : expense / total,
                        red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 27),

                // KATEGORI PENGELUARAN
                const Text(
                  'Pengeluaran per Kategori',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 13),

                if (sortedCategories.isEmpty)
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
                          Icons.pie_chart_outline_rounded,
                          size: 42,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Belum ada pengeluaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Data pengeluaran akan muncul di sini.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: sortedCategories.map((entry) {
                        final percentage = expense == 0
                            ? 0.0
                            : entry.value / expense;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 19),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(entry.value),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 9),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 9,
                                  backgroundColor:
                                      const Color(0xFFF0F1F5),
                                  valueColor:
                                      const AlwaysStoppedAnimation(
                                    primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 27),

                // INSIGHT
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFFF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: primary,
                        size: 25,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Insight Keuangan',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              transactions.isEmpty
                                  ? 'Mulai catat transaksi agar kamu bisa melihat kondisi keuanganmu.'
                                  : income > expense
                                      ? 'Pemasukanmu lebih besar daripada pengeluaran. Pertahankan kebiasaan mencatat keuangan!'
                                      : income == expense
                                          ? 'Pemasukan dan pengeluaranmu saat ini seimbang.'
                                          : 'Pengeluaranmu lebih besar daripada pemasukan. Coba evaluasi pengeluaranmu.',
                              style: const TextStyle(
                                color: Color(0xFF555B72),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(amount),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(
    String title,
    double amount,
    double percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 9,
            backgroundColor: const Color(0xFFF0F1F5),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
