import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

/// State untuk memantau status loading atau eror saat proses login berlangsung
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? user;

  AuthState({this.isLoading = false, this.errorMessage, this.user});

  AuthState copyWith({bool? isLoading, String? errorMessage, User? user}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

/// Provider global yang akan dibaca oleh UI Halaman Login (LoginScreen)
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthController(supabase);
});

class AuthController extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;

  AuthController(this._supabase) : super(AuthState(user: _supabase.auth.currentUser));

  /// Fungsi utama untuk mengeksekusi Google Sign-In ke Supabase
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Konfigurasi Google Sign In dengan Web Client ID dari Firebase/Google Cloud
      // Parameter 'serverClientId' wajib diisi agar Google mengeluarkan idToken untuk Supabase
      final googleSignIn = GoogleSignIn(
        serverClientId: '219387760314-jvi2k8gufoj8b9j8ec9og49e0ukhopvc.apps.googleusercontent.com', // <-- PENTING: Ganti dengan Client ID asli Anda
        scopes: ['email', 'profile'],
      );

      // 2. Munculkan pop-up pilihan akun Google di HP user
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Jika user menekan tombol back atau membatalkan pilihan akun
        state = state.copyWith(isLoading: false);
        return false;
      }

      // 3. Ambil data otentikasi dari akun Google yang dipilih
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'Gagal mendapatkan ID Token dari Google.';
      }

      // 4. Tukarkan token Google ke server Supabase agar tercipta Sesi Login resmi (currentSession)
      final AuthResponse res = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // 5. Update state dengan data user yang berhasil login
      state = state.copyWith(isLoading: false, user: res.user);
      return true;

    } catch (e) {
      // Tangkap jika ada eror teknis (misal: internet mati, client ID salah)
      print("====== ERROR GOOGLE AUTHENTICATION ======");
      print(e);
      print("=========================================");

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login Gagal: $e',
      );
      return false;
    }
  }

  /// Fungsi tambahan untuk Logout / Keluar dari aplikasi
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.disconnect();
    }
    state = AuthState(user: null);
  }
}