
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

import '../data/transaction_store.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() =>
      _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? selectedReceiptBytes;
  String? selectedReceiptName;

  bool isIncome = true;
  bool isSaving = false;

  String selectedCategory = 'Uang Saku';
  DateTime selectedDate = DateTime.now();

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

  List<String> get categories =>
      isIncome ? incomeCategories : expenseCategories;

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

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

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // MEMILIH FOTO DARI KAMERA, GALERI, ATAU FILE EXPLORER
  Future<void> chooseReceipt() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: primary,
                ),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: primary,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.folder_open_rounded,
                  color: primary,
                ),
                title: const Text('Pilih dari File Explorer'),
                onTap: () => Navigator.pop(context, 'file'),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      Uint8List? bytes;
      String? name;

      if (source == 'file') {
  final pickedFile = await file_picker.FilePicker.pickFile(
    type: file_picker.FileType.image,
  );

  if (pickedFile == null) return;

  bytes = await pickedFile.readAsBytes();
  name = pickedFile.name;
        } else {
        final image = await _imagePicker.pickImage(
          source: source == 'camera'
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 45,
          maxWidth: 900,
          maxHeight: 900,
        );

        if (image == null) return;

        bytes = await image.readAsBytes();
        name = image.name;
      }

      if (bytes == null) {
        throw Exception('Foto tidak dapat dibaca.');
      }

      // Maksimal ukuran foto 500 KB
      if (bytes.length > 500 * 1024) {
        throw Exception(
          'Ukuran foto terlalu besar. Maksimal 500 KB. Silakan pilih foto lain.',
        );
      }

      if (!mounted) return;

      setState(() {
        selectedReceiptBytes = bytes;
        selectedReceiptName = name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih foto: $e'),
        ),
      );
    }
  }

  // MENGUBAH FOTO MENJADI BASE64
  Future<String?> convertReceiptToBase64() async {
    if (selectedReceiptBytes == null) return null;

    return base64Encode(selectedReceiptBytes!);
  }

  // MENYIMPAN TRANSAKSI KE FIRESTORE
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

    if (amount == null || amount <= 0) return;

    setState(() {
      isSaving = true;
    });

    try {
      String? receiptBase64;

      if (selectedReceiptBytes != null) {
        receiptBase64 = await convertReceiptToBase64();
      }

      final transaction = {
        'title': titleController.text.trim(),
        'category': selectedCategory,
        'date': selectedDate,
        'amount': amount,
        'income': isIncome,
        'note': noteController.text.trim(),
        'icon': getCategoryIcon(selectedCategory),
        if (receiptBase64 != null)
          'receiptBase64': receiptBase64,
      };

      await TransactionStore.addTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil disimpan ke Firebase',
          ),
          backgroundColor: Color(0xFF20A779),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan transaksi: $e'),
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

  // TAMPILAN BUKTI TRANSAKSI
  Widget receiptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Bukti Transaksi (Opsional)'),
        const SizedBox(height: 9),

        if (selectedReceiptBytes == null)
          InkWell(
            onTap: isSaving ? null : chooseReceipt,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.photo_camera_back_outlined,
                    size: 40,
                    color: primary,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tambah Foto Bukti',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Kamera, galeri, atau File Explorer',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    selectedReceiptBytes!,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedReceiptName ?? 'Foto bukti siap disimpan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () {
                              setState(() {
                                selectedReceiptBytes = null;
                                selectedReceiptName = null;
                              });
                            },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: const Text(
          'Tambah Transaksi',
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
                value: selectedCategory,
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

              const SizedBox(height: 20),

              receiptSection(),

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
                          'Simpan Transaksi',
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
          selectedCategory = income ? 'Uang Saku' : 'Makanan';
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
