import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((_) => AuthRepository());

// Holds the logged-in user profile; null = not authenticated
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  (ref) => UserProfileNotifier(ref.read(authRepositoryProvider)),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final AuthRepository _repo;

  UserProfileNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final loggedIn = await _repo.isLoggedIn;
      if (!loggedIn) {
        state = const AsyncValue.data(null);
        return;
      }
      final profile = await _repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (_) {
      await _repo.clearSession();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> demoLogin() async {
    state = const AsyncValue.loading();
    try {
      await _repo.demoLogin();
      final profile = await _repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.login(email: email, password: password);
      final profile = await _repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repo.register(
          email: email, username: username, password: password);
      final profile = await _repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() => _init();
}
