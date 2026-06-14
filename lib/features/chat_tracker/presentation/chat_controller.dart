import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';
import 'chat_preview_model.dart';

// Struktur pesan sederhana untuk rendering komponen balon chat UI
class ChatMessage {
  final String text;
  final bool isUser;
  final ChatPreviewData? previewData;

  ChatMessage({required this.text, required this.isUser, this.previewData});
}

// Provider utama yang dipanggil oleh ChatScreen
final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatController(supabase);
});

class ChatController extends StateNotifier<List<ChatMessage>> {
  final _supabase;
  bool isLoading = false;

  ChatController(this._supabase) : super([]);

  /// Fungsi untuk mengirim teks bebas dari Flutter ke Supabase Edge Function (AI Engine)
  /// Fungsi mengirim pesan teks bebas
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = [...state, ChatMessage(text: text, isUser: true)];
    isLoading = true;
    state = [...state];

    try {
      final response = await _supabase.functions.invoke(
        'parser-chat',
        body: {'message': text},
      );

      final dynamic rawData = response.data;
      late final Map<String, dynamic> jsonResponse;

      if (rawData is String) {
        jsonResponse = jsonDecode(rawData) as Map<String, dynamic>;
      } else {
        jsonResponse = rawData as Map<String, dynamic>;
      }

      final preview = ChatPreviewData.fromJson(jsonResponse);
      preview.rawPrompt = text; // 🔥 KUNCI 1: Titipkan teks asli user ke dalam model preview

      String botReply = "Aktivitas fitness Anda berhasil diidentifikasi!";
      if (preview.intent == 'CLARIFICATION') {
        botReply = preview.clarificationMessage ?? "Bisa tolong perjelas pesan Anda?";
      }

      state = [...state, ChatMessage(text: botReply, isUser: false, previewData: preview)];
    } catch (e) {
      state = [...state, ChatMessage(text: "Error memproses AI: $e", isUser: false)];
    } finally {
      isLoading = false;
      state = [...state];
    }
  }

  /// Fungsi menyimpan ke database Supabase
  Future<bool> saveLog(ChatPreviewData data) async {
    try {
      final session = _supabase.auth.currentSession;
      final user = session?.user;

      if (user == null) {
        throw 'Sesi login tidak ditemukan. Silakan login ulang terlebih dahulu.';
      }

      if (data.intent == 'FOOD_LOG') {
        await _supabase.from('food_logs').insert({
          'user_id': user.id,
          'food_name': data.foodName ?? 'Makanan Tidak Diketahui',
          'quantity': data.quantity ?? 1.0,
          // 🔥 PERBAIKAN UTAMA: Jika data.calories null, otomatis isi dengan angka 0
          'calories': data.calories ?? 0,
          'raw_prompt': data.rawPrompt ?? 'Input via Chat',
        });
      } else if (data.intent == 'WORKOUT_LOG') {
        await _supabase.from('workout_logs').insert({
          'user_id': user.id,
          'exercise_name': data.exerciseName,
          'sets': data.sets,
          'reps': data.reps,
          'weight_kg': data.weightKg,
          'raw_prompt': data.rawPrompt ?? 'Input via Chat', // 🔥 KUNCI 3: Lakukan hal sama pada workout_logs jika ada kolomnya
        });
      }
      return true;
    } catch (e) {
      print("====== ERROR DATABASE SUPABASE ======");
      print(e);
      print("=====================================");
      throw 'Database menolak: $e';
    }
  }
}