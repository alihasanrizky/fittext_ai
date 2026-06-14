import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- Pastikan ini diimport
import 'core/network/supabase_client.dart';
import 'features/chat_tracker/presentation/chat_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  // 1. Wajib ada agar inisialisasi async bisa berjalan sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. KUNCI UTAMA: Inisialisasi Supabase wajib selesai (await) sebelum masuk ke UI
  await Supabase.initialize(
    url: 'https://moctyjfgmuxpceyzxprl.supabase.co', // <--- Ganti dengan URL Supabase Anda
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vY3R5amZnbXV4cGNleXp4cHJsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzOTUzMzQsImV4cCI6MjA5Njk3MTMzNH0.uF2Q7rq-0Z3lhrC0iA0jTiknpY7Xq-v2Ns1Vgr4x0Ow',             // <--- Ganti dengan Anon Key Supabase Anda
  );

  // 3. Jalankan aplikasi setelah Supabase benar-benar siap
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseClientProvider);
    final currentSession = supabase.auth.currentSession;

    return MaterialApp(
      title: 'FitText AI',
      theme: ThemeData.dark(),
      // PERBAIKAN RUTAN: Jika sudah login, lempar ke Dashboard terlebih dahulu
      home: currentSession != null
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}