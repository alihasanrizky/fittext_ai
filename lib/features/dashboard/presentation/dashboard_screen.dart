import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_controller.dart';
import '../../chat_tracker/presentation/chat_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    const int targetKalori = 2000;

    // PERBAIKAN: Paksa refresh data setiap kali halaman dashboard aktif/dibuka kembali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardControllerProvider.notifier).fetchTodaySummary();
    });

    double progress = dashboardState.totalCaloriesToday / targetKalori;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Obsidian Black
      appBar: AppBar(
        title: const Text(
          'FITTEXT PERFORMANCE',
          style: TextStyle(color: Color(0xFFCCFF00), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(dashboardControllerProvider.notifier).fetchTodaySummary(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).fetchTodaySummary(),
        color: const Color(0xFFCCFF00),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= RINGKASAN PROGRESS PROPORSI KALORI =================
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[950],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[900]!, width: 1),
                ),
                child: Column(
                  children: [
                    const Text('KONSUMSI ENERGI HARI INI', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCCFF00)),
                            backgroundColor: Colors.grey[900],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              '${dashboardState.totalCaloriesToday}',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            Text('/ $targetKalori kkal', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= KARTU KECIL STATS LATIHAN =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[950],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Color(0xFFCCFF00), size: 32),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AKTIVITAS WORKOUT', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${dashboardState.totalWorkoutsToday} Latihan Dicatat',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ================= TOMBOL TERBANG UNTUK MEMBUKA AI CHAT =================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFCCFF00),
        foregroundColor: Colors.black,
        onPressed: () {
          // Navigasi masuk ke layar Chat Engine AI Anda kemarin
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          ).then((_) {
            // Ketika user kembali dari halaman chat, otomatis refresh angka dashboard
            ref.read(dashboardControllerProvider.notifier).fetchTodaySummary();
          });
        },
        icon: Icon(
          Icons.chat_bubble,
          weight: 700, // Mengatur ketebalan ikon
        ),
        label: const Text('LOG VIA AI', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}