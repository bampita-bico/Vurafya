class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
      );
}

class UserProfile {
  final int id;
  final String email;
  final String username;
  final String subscriptionTier;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;

  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.subscriptionTier,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as int,
        email: j['email'] as String,
        username: j['username'] as String,
        subscriptionTier: j['subscription_tier'] as String? ?? 'free',
        fullName: j['full_name'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        isVerified: j['is_verified'] as bool? ?? false,
      );

  bool get isPro =>
      subscriptionTier == 'pro' || subscriptionTier == 'premium';
}
