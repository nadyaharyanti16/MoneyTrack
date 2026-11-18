
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'main_navigation.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      tampilkanPesan('Email dan password wajib diisi');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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
        case 'user-not-found':
        case 'invalid-credential':
          pesan = 'Email atau password salah';
          break;
        case 'wrong-password':
          pesan = 'Password yang kamu masukkan salah';
          break;
        case 'invalid-email':
          pesan = 'Format email tidak valid';
          break;
        case 'user-disabled':
          pesan = 'Akun ini telah dinonaktifkan';
          break;
        case 'too-many-requests':
          pesan = 'Terlalu banyak percobaan. Coba lagi nanti';
          break;
        case 'network-request-failed':
          pesan = 'Periksa koneksi internet kamu';
          break;
        default:
          pesan = e.message ?? 'Login gagal';
      }

      if (mounted) {
        tampilkanPesan(pesan);
      }
    } catch (e) {
      if (mounted) {
        tampilkanPesan('Terjadi kesalahan saat login');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 70,
                    color: primary,
                  ),
                ),

                const SizedBox(height: 25),

                const Center(
                  child: Text(
                    'Login Akun',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Masuk ke akun MoneyTrack kamu',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 9),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Masukkan email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Password',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 9),

                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Masukkan password',
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
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
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Daftar',
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
      ),
    );
  }
}
