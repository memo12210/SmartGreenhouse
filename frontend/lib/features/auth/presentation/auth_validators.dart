/// Shared form validators for the auth screens.
class AuthValidators {
  AuthValidators._();

  // Pragmatic email check: non-empty local part, an @, a domain with a dot.
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? fullName(String? value) {
    // Optional field: only validate when something was entered.
    final name = value?.trim() ?? '';
    if (name.isEmpty) return null;
    if (name.length < 2) return 'Name is too short';
    return null;
  }
}
