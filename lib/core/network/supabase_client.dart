import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider global untuk mengakses Supabase di seluruh aplikasi
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});