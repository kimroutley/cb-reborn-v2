enum UsernameValidationState {
  valid,
  tooShort,
  tooLong,
  invalidCharacters,
}

extension UsernameValidationStateExtension on UsernameValidationState {
  String? get errorMessage {
    switch (this) {
      case UsernameValidationState.valid:
        return null;
      case UsernameValidationState.tooShort:
        return 'Username too short.';
      case UsernameValidationState.tooLong:
        return 'Username too long.';
      case UsernameValidationState.invalidCharacters:
        return 'Use letters, numbers, spaces, underscores, or hyphens only.';
    }
  }
}

enum PublicIdValidationState {
  valid,
  tooShort,
  tooLong,
  invalidCharacters,
}

extension PublicIdValidationStateExtension on PublicIdValidationState {
  String? get errorMessage {
    switch (this) {
      case PublicIdValidationState.valid:
        return null;
      case PublicIdValidationState.tooShort:
        return 'Public ID too short.';
      case PublicIdValidationState.tooLong:
        return 'Public ID too long.';
      case PublicIdValidationState.invalidCharacters:
        return 'Use lowercase letters, numbers, underscores, or hyphens only.';
    }
  }
}

class ProfileFormValidation {
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 24;
  static const int publicIdMinLength = 3;
  static const int publicIdMaxLength = 24;

  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9 _-]+$');

  static String sanitizePublicPlayerId(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
  }

  static UsernameValidationState validateUsername(String input) {
    final trimmed = input.trim();
    if (trimmed.length < usernameMinLength) {
      return UsernameValidationState.tooShort;
    }
    if (trimmed.length > usernameMaxLength) {
      return UsernameValidationState.tooLong;
    }
    if (!_usernamePattern.hasMatch(trimmed)) {
      return UsernameValidationState.invalidCharacters;
    }
    return UsernameValidationState.valid;
  }

  static PublicIdValidationState validatePublicPlayerId(
    String input, {
    String? initialValue,
  }) {
    final sanitized = sanitizePublicPlayerId(input);
    if (sanitized.isEmpty) {
      return PublicIdValidationState.valid;
    }
    if (sanitized.length < publicIdMinLength) {
      return PublicIdValidationState.tooShort;
    }
    if (sanitized.length > publicIdMaxLength) {
      return PublicIdValidationState.tooLong;
    }
    return PublicIdValidationState.valid;
  }
}
