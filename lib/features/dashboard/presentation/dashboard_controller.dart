import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_client.dart';

/// State untuk menampung data ringkasan dashboard
class DashboardState {
  final bool isLoading;
  final int totalCaloriesToday;
  final int totalWorkoutsToday;
  final String? errorMessage;

  DashboardState({
    this.isLoading = false,
    this.totalCaloriesToday = 0,
    this.totalWorkoutsToday = 0,
    this.errorMessage,
  });

  DashboardState copyWith({
    bool? isLoading,
    int? totalCaloriesToday,
    int? totalWorkoutsToday,
    String? errorMessage,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalCaloriesToday: totalCaloriesToday ?? this.totalCaloriesToday,
      totalWorkoutsToday: totalWorkoutsToday ?? this.totalWorkoutsToday,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider global untuk Dashboard
final dashboardControllerProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardController(supabase);
});

class DashboardController extends StateNotifier<DashboardState> {
  final _supabase;

  DashboardController(this._supabase) : super(DashboardState()) {
    fetchTodaySummary(); // Otomatis ambil data saat dashboard dibuka
  }

  Future<void> fetchTodaySummary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = _supabase.auth.currentSession?.user;
      if (user == null) throw 'User tidak terautentikasi';

      // Hitung rentang waktu hari ini (mulai 00:00:00 sampai 23:59:59)
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // 1. Tarik data food_logs hari ini berdasarkan user_id
      final List<dynamic> foodData = await _supabase
          .from('food_logs')
          .select('calories')
          .eq('user_id', user.id)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      // 2. Tarik data workout_logs hari ini berdasarkan user_id
      final List<dynamic> workoutData = await _supabase
          .from('workout_logs')
          .select('id')
          .eq('user_id', user.id)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      // 3. Hitung total penjumlahan kalori secara manual dari list
      int totalCal = 0;
      for (var row in foodData) {
        totalCal += (row['calories'] as num? ?? 0).toInt();
      }

      state = state.copyWith(
        isLoading: false,
        totalCaloriesToday: totalCal,
        totalWorkoutsToday: workoutData.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}