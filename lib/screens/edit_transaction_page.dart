
import 'package:flutter/material.dart';
import '../data/transaction_store.dart';

class EditTransactionPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionPage({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionPage> createState() =>
      _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController amountController;
  late TextEditingController noteController;

  late bool isIncome;
  late String selectedCategory;
  late DateTime selectedDate;

  bool isSaving = false;

  static const Color primary = Color(0xFF5267D8);

  final List<String> incomeCategories = [
    'Uang Saku',
    'Gaji',
    'Beasiswa',
    'Freelance',
    'Hadiah',
    'Lainnya',
  ];

  final List<String> expenseCategories = [
    'Makanan',
    'Transportasi',
    'Pendidikan',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;

    titleController = TextEditingController(
      text: transaction['title']?.toString() ?? '',
    );

    amountController = TextEditingController(
      text: transaction['amount']?.toString() ?? '',
    );

    noteController = TextEditingController(
      text: transaction['note']?.toString() ?? '',
    );

    isIncome = transaction['income'] == true;

    selectedCategory =
        transaction['category']?.toString() ?? 'Lainnya';

    selectedDate = transaction['date'] is DateTime
        ? transaction['date'] as DateTime
        : DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  List<String> get categories =>
      isIncome ? incomeCategories : expenseCategories;

  String formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Uang Saku':
        return Icons.account_balance_wallet_rounded;
      case 'Gaji':
        return Icons.work_rounded;
      case 'Beasiswa':
        return Icons.school_rounded;
      case 'Freelance':
        return Icons.laptop_mac_rounded;
      case 'Hadiah':
        return Icons.card_giftcard_rounded;
      case 'Makanan':
        return Icons.restaurant_rounded;
      case 'Transportasi':
        return Icons.directions_bus_rounded;
      case 'Pendidikan':
        return Icons.menu_book_rounded;
      case 'Belanja':
        return Icons.shopping_bag_rounded;
      case 'Hiburan':
        return Icons.movie_rounded;
      case 'Kesehatan':
        return Icons.health_and_safety_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> saveTransaction() async {
    if (isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = num.tryParse(
      amountController.text
          .replaceAll('.', '')
          .replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal yang valid'),
        ),
      );
      return;
    }

    final oldTransaction = widget.transaction;

    final updatedTransaction = {
      'title': titleController.text.trim(),
      'category': selectedCategory,
      'date': selectedDate,
      'amount': amount,
      'income': isIncome,
      'note': noteController.text.trim(),
      'icon': getCategoryIcon(selectedCategory),
    };

    setState(() {
      isSaving = true;
    });

    try {
      await TransactionStore.updateTransaction(
        oldTransaction,
        updatedTransaction,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil diperbarui'),
          backgroundColor: Color(0xFF20A779),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui transaksi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: const Text(
          'Edit Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jenis Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _typeButton(
                      title: 'Pemasukan',
                      income: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _typeButton(
                      title: 'Pengeluaran',
                      income: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _label('Nama Transaksi'),
              const SizedBox(height: 9),
              TextFormField(
                controller: titleController,
                decoration: _inputDecoration(
                  'Contoh: Uang saku bulanan',
                  Icons.edit_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama transaksi wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Nominal'),
              const SizedBox(height: 9),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Masukkan nominal',
                  Icons.payments_outlined,
                ),
                validator: (value) {
                  final amount = num.tryParse(
                    (value ?? '')
                        .replaceAll('.', '')
                        .replaceAll(',', ''),
                  );

                  if (amount == null || amount <= 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _label('Kategori'),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                value: categories.contains(selectedCategory)
                    ? selectedCategory
                    : 'Lainnya',
                decoration: _inputDecoration(
                  'Pilih kategori',
                  Icons.category_outlined,
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              _label('Tanggal Transaksi'),
              const SizedBox(height: 9),
              InkWell(
                onTap: chooseDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(formatDate(selectedDate)),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Catatan (Opsional)'),
              const SizedBox(height: 9),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Tambahkan catatan transaksi...',
                  Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSaving ? null : saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        primary.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton({
    required String title,
    required bool income,
  }) {
    final selected = isIncome == income;

    final color = income
        ? const Color(0xFF20A779)
        : const Color(0xFFE65B65);

    return GestureDetector(
      onTap: () {
        setState(() {
          isIncome = income;

          if (income) {
            selectedCategory = 'Uang Saku';
          } else {
            selectedCategory = 'Makanan';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 1.5,
        ),
      ),
    );
  }
}
