import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../chat_tracker/presentation/chat_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menyimak state dari authController untuk melihat status loading atau eror
    final authState = ref.watch(authControllerProvider);

    // Mendengarkan perubahan state secara real-time untuk memunculkan SnackBar jika terjadi eror
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Obsidian Black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ================= LOGO & BRANDING =================
              const Icon(
                Icons.bolt,
                size: 80,
                color: Color(0xFFCCFF00), // Electric Lime
              ),
              const SizedBox(height: 16),
              const Text(
                'FITTEXT AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log your fitness and nutrition via simple chat.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              // ================= TOMBOL UTAMA SIGN IN =================
              if (authState.isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
                  ),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCCFF00), // Electric Lime
                    foregroundColor: Colors.black, // Warna teks di dalam tombol
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    // 1. Eksekusi alur login Google via AuthController
                    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();

                    // 2. Jika login sukses dan widget masih aktif di layar
                    if (success && context.mounted) {
                      // Hancurkan halaman login dan pindah permanen ke ChatScreen
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simbol G instan (menggunakan icon bawaan demi kemudahan, bisa diganti aset SVG Google)
                      const Icon(Icons.g_mobiledata, size: 30, color: Colors.black),
                      const SizedBox(width: 4),
                      const Text(
                        'SIGN IN WITH GOOGLE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Catatan Kaki Keamanan
              const Text(
                'By signing in, you agree to our automated tracking terms.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}