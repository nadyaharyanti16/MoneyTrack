
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/transaction_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color primary = Color(0xFF5267D8);

  bool notificationEnabled = true;
  bool vibrationEnabled = true;

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> showAccountInfo() async {
    final user = FirebaseAuth.instance.currentUser;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Akun'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Nama', user?.displayName ?? 'Belum diatur'),
            const Divider(),
            _infoRow('Email', user?.email ?? '-'),
            const Divider(),
            _infoRow('UID', user?.uid ?? '-'),
            const Divider(),
            _infoRow('Status', user?.emailVerified == true
                ? 'Terverifikasi'
                : 'Belum terverifikasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showSecurity() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool loading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ganti Password'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Password saat ini',
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Password baru',
                        helperText: 'Minimal 6 karakter',
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi password baru',
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final current = currentController.text.trim();
                          final newPassword = newController.text.trim();
                          final confirm = confirmController.text.trim();

                          if (current.isEmpty ||
                              newPassword.isEmpty ||
                              confirm.isEmpty) {
                            showMessage('Semua kolom harus diisi.');
                            return;
                          }

                          if (newPassword.length < 6) {
                            showMessage(
                              'Password baru minimal 6 karakter.',
                            );
                            return;
                          }

                          if (newPassword != confirm) {
                            showMessage(
                              'Konfirmasi password tidak cocok.',
                            );
                            return;
                          }

                          setDialogState(() {
                            loading = true;
                          });

                          try {
                            final user =
                                FirebaseAuth.instance.currentUser;

                            if (user == null || user.email == null) {
                              throw Exception('Akun tidak ditemukan.');
                            }

                            final credential =
                                EmailAuthProvider.credential(
                              email: user.email!,
                              password: current,
                            );

                            await user.reauthenticateWithCredential(
                              credential,
                            );

                            await user.updatePassword(newPassword);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              showMessage(
                                'Password berhasil diperbarui.',
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            String message;

                            if (e.code == 'wrong-password' ||
                                e.code == 'invalid-credential') {
                              message = 'Password saat ini salah.';
                            } else if (e.code == 'weak-password') {
                              message = 'Password baru terlalu lemah.';
                            } else if (e.code ==
                                'requires-recent-login') {
                              message =
                                  'Silakan login ulang sebelum mengganti password.';
                            } else {
                              message =
                                  e.message ?? 'Gagal mengganti password.';
                            }

                            if (mounted) showMessage(message);

                            setDialogState(() {
                              loading = false;
                            });
                          } catch (e) {
                            if (mounted) {
                              showMessage('Gagal mengganti password.');
                            }

                            setDialogState(() {
                              loading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
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

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
  }

  Future<void> showNotifications() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pengaturan Notifikasi'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: primary,
                    title: const Text(
                      'Notifikasi',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Aktifkan pemberitahuan aplikasi',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: notificationEnabled,
                    onChanged: (value) {
                      setDialogState(() {
                        notificationEnabled = value;
                        if (!value) vibrationEnabled = false;
                      });
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: primary,
                    title: const Text(
                      'Getaran',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Aktifkan getaran notifikasi',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: vibrationEnabled,
                    onChanged: notificationEnabled
                        ? (value) {
                            setDialogState(() {
                              vibrationEnabled = value;
                            });
                            setState(() {});
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pengaturan ini masih berupa preferensi aplikasi. '
                    'Pengiriman push notification memerlukan integrasi Firebase Cloud Messaging.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showHelpCenter() async {
    final questions = [
      {
        'question': 'Bagaimana cara menambahkan transaksi?',
        'answer':
            'Buka halaman Dashboard atau Transaksi, kemudian tekan tombol tambah (+). Isi informasi transaksi dan simpan.'
      },
      {
        'question': 'Bagaimana cara mengedit transaksi?',
        'answer':
            'Buka halaman Transaksi, pilih transaksi yang ingin diubah, lalu tekan tombol edit.'
      },
      {
        'question': 'Bagaimana melihat statistik keuangan?',
        'answer':
            'Buka menu Statistik untuk melihat ringkasan pemasukan, pengeluaran, dan grafik keuangan.'
      },
      {
        'question': 'Apakah data tersimpan?',
        'answer':
            'Data transaksi disimpan menggunakan Firebase Firestore dan dikaitkan dengan akun pengguna.'
      },
      {
        'question': 'Bagaimana cara mengganti password?',
        'answer':
            'Buka menu Profil, pilih Keamanan, lalu masukkan password lama dan password baru.'
      },
    ];

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pusat Bantuan'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  color: primary,
                  size: 55,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ada yang bisa kami bantu?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...questions.map(
                  (item) => ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      item['question']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 12,
                        ),
                        child: Text(
                          item['answer']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> showAbout() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'MoneyTrack',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi pencatatan keuangan pribadi mahasiswa untuk membantu mengelola pemasukan dan pengeluaran.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Versi 1.0.0',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    try {
      await TransactionStore.dispose();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        showMessage('Gagal keluar dari akun. Coba lagi.');
      }
    }
  }

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun MoneyTrack?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                logout();
              },
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final nama = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Pengguna MoneyTrack';

    final email = user?.email ?? 'Email tidak tersedia';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pengguna MoneyTrack',
                      style: TextStyle(
                        color: primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            _sectionTitle('Akun'),
            _menuCard([
              _menuItem(
                icon: Icons.person_outline_rounded,
                title: 'Informasi Akun',
                subtitle: 'Lihat informasi akun',
                onTap: showAccountInfo,
              ),
              _divider(),
              _menuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Keamanan',
                subtitle: 'Ganti password akun',
                onTap: showSecurity,
              ),
            ]),

            const SizedBox(height: 23),
            _sectionTitle('Preferensi'),
            _menuCard([
              _menuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                subtitle: notificationEnabled
                    ? 'Notifikasi aktif'
                    : 'Notifikasi nonaktif',
                onTap: showNotifications,
              ),
            ]),

            const SizedBox(height: 23),
            _sectionTitle('Informasi'),
            _menuCard([
              _menuItem(
                icon: Icons.help_outline_rounded,
                title: 'Pusat Bantuan',
                subtitle: 'Panduan dan pertanyaan umum',
                onTap: showHelpCenter,
              ),
              _divider(),
              _menuItem(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi tentang MoneyTrack',
                onTap: showAbout,
              ),
            ]),

            const SizedBox(height: 23),
            _menuCard([
              _menuItem(
                icon: Icons.logout_rounded,
                title: 'Keluar Akun',
                subtitle: 'Keluar dari aplikasi',
                color: Colors.red,
                showArrow: false,
                onTap: showLogoutDialog,
              ),
            ]),

            const SizedBox(height: 25),
            const Text(
              'MoneyTrack v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 5),
            const Text(
              'Kelola keuangan, raih tujuanmu.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = primary,
    bool showArrow = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            )
          : null,
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 70,
      endIndent: 15,
    );
  }
}
