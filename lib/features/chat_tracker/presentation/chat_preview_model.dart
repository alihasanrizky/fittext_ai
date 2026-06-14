class ChatPreviewData {
  final String intent;
  final String? foodName;
  final double? quantity;
  final int? calories;
  final String? exerciseName;
  final int? sets;
  final int? reps;
  final double? weightKg;
  final String? clarificationMessage;
  String? rawPrompt; // <-- Tambahkan variabel penampung teks mentah di sini

  ChatPreviewData({
    required this.intent,
    this.foodName,
    this.quantity,
    this.calories,
    this.exerciseName,
    this.sets,
    this.reps,
    this.weightKg,
    this.clarificationMessage,
    this.rawPrompt, // <-- Masukkan ke constructor
  });

  factory ChatPreviewData.fromJson(Map<String, dynamic> json) {
    final intent = json['intent'] ?? 'CLARIFICATION';
    final extData = (json['extracted_data'] as List?)?.firstOrNull;

    return ChatPreviewData(
      intent: intent,
      clarificationMessage: json['clarification_message'],
      foodName: extData?['food_name'],
      quantity: (extData?['quantity'] as num?)?.toDouble(),
      calories: extData?['calories'],
      exerciseName: extData?['exercise_name'],
      sets: extData?['sets'],
      reps: extData?['reps'],
      weightKg: (extData?['weight_kg'] as num?)?.toDouble() ?? (extData?['weight_entry'] as num?)?.toDouble(),
    );
  }
}