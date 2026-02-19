class ProfileFormValidation {
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 24;
  static const int publicIdMinLength = 3;
  static const int publicIdMaxLength = 24;

  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9 _-]+$');

  static String sanitizePublicPlayerId(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  }

  static String? validateUsername(String input) {
    final trimmed = input.trim();
    if (trimmed.length < usernameMinLength) {
      return 'Username must be at least $usernameMinLength characters.';
    }
    if (trimmed.length > usernameMaxLength) {
      return 'Username must be at most $usernameMaxLength characters.';
    }
    if (!_usernamePattern.hasMatch(trimmed)) {
      return 'Use letters, numbers, spaces, underscores, or hyphens only.';
    }
    return null;
  }

  static String? validatePublicPlayerId(String input) {
    final sanitized = sanitizePublicPlayerId(input);
    if (sanitized.isEmpty) {
      return null;
    }
    if (sanitized.length < publicIdMinLength) {
      return 'Public player ID must be at least $publicIdMinLength characters.';
    }
    if (sanitized.length > publicIdMaxLength) {
      return 'Public player ID must be at most $publicIdMaxLength characters.';
    }
    return null;
  }
}
