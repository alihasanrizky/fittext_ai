import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_controller.dart';
import 'chat_preview_model.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  // ================= FITUR POP-UP EDIT MANUAL =================
  void _showEditDialog(BuildContext context, WidgetRef ref, ChatPreviewData data) {
    final nameController = TextEditingController(text: data.intent == 'FOOD_LOG' ? data.foodName : data.exerciseName);
    final primaryController = TextEditingController(text: data.intent == 'FOOD_LOG' ? data.calories?.toString() : data.weightKg?.toString());
    final secondaryController = TextEditingController(text: data.intent == 'FOOD_LOG' ? data.quantity?.toString() : data.sets?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[950],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFCCFF00)),
        ),
        title: Text(
          data.intent == 'FOOD_LOG' ? 'EDIT LOG MAKANAN' : 'EDIT LOG WORKOUT',
          style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Aktivitas / Item',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCFF00))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: primaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: data.intent == 'FOOD_LOG' ? 'Estimasi Energi (kkal)' : 'Beban Latihan (kg)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCFF00))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secondaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: data.intent == 'FOOD_LOG' ? 'Jumlah Porsi' : 'Total Sets',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFCCFF00))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCCFF00)),
            onPressed: () async {
              try {
                if (data.intent == 'FOOD_LOG') {
                  final updatedData = ChatPreviewData(
                    intent: 'FOOD_LOG',
                    foodName: nameController.text,
                    calories: int.tryParse(primaryController.text) ?? 0,
                    quantity: double.tryParse(secondaryController.text) ?? 1.0,
                    rawPrompt: data.rawPrompt,
                  );
                  await ref.read(chatControllerProvider.notifier).saveLog(updatedData);
                } else {
                  final updatedData = ChatPreviewData(
                    intent: 'WORKOUT_LOG',
                    exerciseName: nameController.text,
                    weightKg: double.tryParse(primaryController.text) ?? 0.0,
                    sets: int.tryParse(secondaryController.text) ?? 0,
                    reps: data.reps,
                    rawPrompt: data.rawPrompt,
                  );
                  await ref.read(chatControllerProvider.notifier).saveLog(updatedData);
                }

                if (context.mounted) {
                  Navigator.pop(context); // 1. Tutup Pop-up Dialog Edit
                  Navigator.of(context).pop(); // 2. KUNCI: Otomatis tutup halaman Chat & balik ke Dashboard

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil direvisi & disimpan!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan revisi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Simpan ✔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatMessages = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Obsidian Black
      appBar: AppBar(
        title: const Text(
          'FITTEXT LOG ENGINE',
          style: TextStyle(
            color: Color(0xFFCCFF00), // Electric Lime
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================= AREA UTAMA LIST CHAT =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final message = chatMessages[index];
                return Column(
                  crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Balon Chat Konvensional
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: message.isUser ? const Color(0xFFCCFF00) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                          bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                        ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          color: message.isUser ? Colors.black : Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),

                    // ================= RENDERING PREVIEW CARD (KOTAK HIJAU) =================
                    if (!message.isUser && message.previewData != null && message.previewData!.intent != 'CLARIFICATION')
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[950],
                          border: Border.all(color: const Color(0xFFCCFF00), width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Color(0xFFCCFF00), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  message.previewData!.intent,
                                  style: const TextStyle(
                                      color: Color(0xFFCCFF00),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.grey),

                            // Kondisi 1: Tampilan data makanan
                            if (message.previewData!.intent == 'FOOD_LOG') ...[
                              Text('Makanan: ${message.previewData!.foodName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              Text('Porsi: ${message.previewData!.quantity} porsi', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('Estimasi Energi: 🔥 ${message.previewData!.calories} kkal', style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],

                            // Kondisi 2: Tampilan data olahraga / gym
                            if (message.previewData!.intent == 'WORKOUT_LOG') ...[
                              Text('Latihan: ${message.previewData!.exerciseName?.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              Text('Skema: ${message.previewData!.sets} Set x ${message.previewData!.reps} Reps', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text('Beban: 🏋️ ${message.previewData!.weightKg} kg', style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 13, fontWeight: FontWeight.bold)),
                            ],

                            const SizedBox(height: 16),

                            // Barisan Tombol Manajemen Data
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Memicu kemunculan Pop-up Revisi Manual
                                    _showEditDialog(context, ref, message.previewData!);
                                  },
                                  child: const Text('Edit Manual', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCCFF00)),
                                  onPressed: () async {
                                    try {
                                      // Di sini menggunakan message.previewData karena berada di dalam ListView
                                      final success = await ref.read(chatControllerProvider.notifier)
                                          .saveLog(message.previewData!);

                                      if (context.mounted && success) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Data berhasil disimpan ke database!'), backgroundColor: Colors.green),
                                        );

                                        // KUNCI: Otomatis balik ke Dashboard setelah sukses simpan tanpa edit
                                        Navigator.of(context).pop();
                                      }
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('$error'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Simpan ✔', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Baris loading penanda server/AI sedang berpikir
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFCCFF00)),
                backgroundColor: Colors.black,
              ),
            ),

          // ================= AREA DOCK BOTTOM INPUT TEXT =================
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[950],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ketik makanan atau latihan Anda...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      fillColor: Colors.grey[900],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFFCCFF00)),
                  onPressed: () {
                    final txt = textController.text;
                    if (txt.isNotEmpty) {
                      controller.sendMessage(txt);
                      textController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}