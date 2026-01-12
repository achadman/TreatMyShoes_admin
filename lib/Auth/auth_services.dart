import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServices {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Sign In dengan Email dan Password
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 2. Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 3. Mendapatkan Email User yang sedang login (Opsional)
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  // 4. Mendapatkan User ID (Opsional)
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }
}
