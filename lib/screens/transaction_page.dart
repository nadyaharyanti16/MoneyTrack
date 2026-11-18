
import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/transaction_store.dart';
import 'edit_transaction_page.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedFilter = 'Semua';

  static const Color primary = Color(0xFF5267D8);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatRupiah(num amount) {
    final number = amount.toInt().toString();
    final formatted = number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> editTransaction(
    Map<String, dynamic> transaction,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(
          transaction: transaction,
        ),
      ),
    );
  }

  // MENAMPILKAN FOTO BUKTI BASE64
  void showReceipt(String base64Image) {
    try {
      final imageBytes = base64Decode(base64Image);

      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bukti Transaksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Foto tidak dapat ditampilkan'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto bukti tidak dapat dibuka'),
        ),
      );
    }
  }

  Future<void> deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: Text(
            'Transaksi "${transaction['title']}" akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await TransactionStore.deleteTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: Color(0xFF20A779),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<
        List<Map<String, dynamic>>>(
      valueListenable: TransactionStore.transactions,
      builder: (context, transactions, child) {
        double totalIncome = 0;
        double totalExpense = 0;

        for (final item in transactions) {
          final amount =
              (item['amount'] as num?)?.toDouble() ?? 0;

          if (item['income'] == true) {
            totalIncome += amount;
          } else {
            totalExpense += amount;
          }
        }

        final keyword = searchController.text.toLowerCase();

        final filteredTransactions = transactions.where((item) {
          final title =
              (item['title'] ?? '').toString().toLowerCase();
          final category =
              (item['category'] ?? '').toString().toLowerCase();

          final matchesSearch =
              title.contains(keyword) ||
              category.contains(keyword);

          final matchesFilter =
              selectedFilter == 'Semua' ||
              (selectedFilter == 'Pemasukan' &&
                  item['income'] == true) ||
              (selectedFilter == 'Pengeluaran' &&
                  item['income'] != true);

          return matchesSearch && matchesFilter;
        }).toList();

        filteredTransactions.sort((a, b) {
          final dateA = a['date'] is DateTime
              ? a['date'] as DateTime
              : DateTime.now();

          final dateB = b['date'] is DateTime
              ? b['date'] as DateTime
              : DateTime.now();

          return dateB.compareTo(dateA);
        });

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F6FA),
            elevation: 0,
            title: const Text(
              'Riwayat Transaksi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _totalCard(
                            'Pemasukan',
                            totalIncome,
                            const Color(0xFF20A779),
                            Icons.south_west_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _totalCard(
                            'Pengeluaran',
                            totalExpense,
                            const Color(0xFFE65B65),
                            Icons.north_east_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _filterButton('Semua'),
                        const SizedBox(width: 8),
                        _filterButton('Pemasukan'),
                        const SizedBox(width: 8),
                        _filterButton('Pengeluaran'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Transaksi tidak ditemukan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Coba kata kunci atau filter lainnya.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 100,
                        ),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final item = filteredTransactions[index];

                          final isIncome = item['income'] == true;

                          final amount =
                              (item['amount'] as num?) ?? 0;

                          final date = item['date'] is DateTime
                              ? item['date'] as DateTime
                              : DateTime.now();

                          final icon = item['icon'] is IconData
                              ? item['icon'] as IconData
                              : Icons.category_rounded;

                          final receiptBase64 =
                              item['receiptBase64']?.toString();

                          final hasReceipt =
                              receiptBase64 != null &&
                              receiptBase64.isNotEmpty;

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
                                        ? Colors.green.withOpacity(0.10)
                                        : Colors.red.withOpacity(0.10),
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
                                        (item['title'] ?? '').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${item['category'] ?? 'Lainnya'} • ${formatDate(date)}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${isIncome ? '+' : '-'}${formatRupiah(amount)}',
                                        style: TextStyle(
                                          color: isIncome
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (hasReceipt)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 7,
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              showReceipt(receiptBase64);
                                            },
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.image_outlined,
                                                  size: 15,
                                                  color: primary,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Lihat bukti transaksi',
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      editTransaction(item);
                                    } else if (value == 'delete') {
                                      deleteTransaction(item);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Hapus',
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterButton(String title) {
    final selected = selectedFilter == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _totalCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 9),
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
              style: TextStyle(
                color: color,
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
