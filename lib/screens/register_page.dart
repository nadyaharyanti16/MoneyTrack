
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool obscurePassword = true;
  bool obscureKonfirmasi = true;
  bool isLoading = false;

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> daftar() async {
    if (isLoading) return;

    final nama = namaController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final konfirmasi = konfirmasiController.text;

    if (nama.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        konfirmasi.isEmpty) {
      tampilkanPesan('Semua kolom wajib diisi');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      tampilkanPesan('Format email tidak valid');
      return;
    }

    if (password.length < 6) {
      tampilkanPesan('Password minimal 6 karakter');
      return;
    }

    if (password != konfirmasi) {
      tampilkanPesan('Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(nama);
      await credential.user?.reload();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String pesan;

      switch (e.code) {
        case 'email-already-in-use':
          pesan = 'Email sudah terdaftar';
          break;
        case 'invalid-email':
          pesan = 'Format email tidak valid';
          break;
        case 'weak-password':
          pesan = 'Password terlalu lemah';
          break;
        case 'operation-not-allowed':
          pesan = 'Login Email/Password belum diaktifkan di Firebase';
          break;
        case 'network-request-failed':
          pesan = 'Periksa koneksi internet kamu';
          break;
        default:
          pesan = e.message ?? 'Registrasi gagal';
      }

      if (mounted) {
        tampilkanPesan(pesan);
      }
    } catch (e) {
      if (mounted) {
        tampilkanPesan('Terjadi kesalahan: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5267D8);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 25,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: primary,
                  size: 65,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Buat Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Daftar untuk mulai mengelola keuanganmu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),

              const Text(
                'Nama Lengkap',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: namaController,
                textCapitalization: TextCapitalization.words,
                decoration: inputDecoration(
                  'Masukkan nama lengkap',
                  Icons.person_outline,
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration(
                  'Masukkan email',
                  Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: inputDecoration(
                  'Minimal 6 karakter',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                'Konfirmasi Password',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: konfirmasiController,
                obscureText: obscureKonfirmasi,
                decoration: inputDecoration(
                  'Masukkan ulang password',
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureKonfirmasi = !obscureKonfirmasi;
                      });
                    },
                    icon: Icon(
                      obscureKonfirmasi
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : daftar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Sudah punya akun?',
                    style: TextStyle(color: Colors.grey),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
