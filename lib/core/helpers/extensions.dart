import 'package:flutter/widgets.dart';
import 'dart:math';

extension Navigation on BuildContext {
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(
      this,
    ).pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
    required RoutePredicate predicate,
  }) {
    return Navigator.of(
      this,
    ).pushNamedAndRemoveUntil(routeName, predicate, arguments: arguments);
  }

  void pop() => Navigator.of(this).pop();
}

extension StringExtension on String? {
  bool isNullOrEmpty() => this == null || this == "";
}

extension ListExtension<T> on List<T>? {
  bool isNullOrEmpty() => this == null || this!.isEmpty;
}

//NOTE: random username

extension RandomUsernameGenerator on String {
  /// Generates a random username with alphanumeric characters
  ///
  /// [length] - The length of the username (default: 8)
  /// [includeNumbers] - Whether to include numbers (default: true)
  /// [includeUppercase] - Whether to include uppercase letters (default: true)
  /// [includeLowercase] - Whether to include lowercase letters (default: true)
  /// [prefix] - Optional prefix for the username
  /// [suffix] - Optional suffix for the username
  static String generateRandomUsername({
    int length = 10,
    bool includeNumbers = true,
    bool includeUppercase = true,
    bool includeLowercase = true,
    String? prefix,
    String? suffix,
  }) {
    if (length <= 0) {
      throw ArgumentError('Length must be greater than 0');
    }

    const String numbers = '0123456789';
    const String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';

    String characters = '';

    if (includeNumbers) characters += numbers;
    if (includeUppercase) characters += uppercaseLetters;
    if (includeLowercase) characters += lowercaseLetters;

    if (characters.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }

    final Random random = Random();
    String username = '';

    for (int i = 0; i < length; i++) {
      username += characters[random.nextInt(characters.length)];
    }

    // Add prefix and suffix if provided
    if (prefix != null) username = prefix + username;
    if (suffix != null) username = username + suffix;

    return username;
  }

  /// Generates a modern random username for professional use
  static String generateModernUsername() {
    final List<String> modernPrefixes = [
      'user',
      'chat',
      'connect',
      'modern',
      'swift',
      'bright',
      'smart',
      'wave',
      'spark',
      'flow',
    ];

    final Random random = Random();
    final String prefix = modernPrefixes[random.nextInt(modernPrefixes.length)];
    final String randomPart = generateRandomUsername(
      length: 4,
      includeNumbers: true,
      includeUppercase: false,
      includeLowercase: true,
    );

    return '$prefix$randomPart';
  }
}
