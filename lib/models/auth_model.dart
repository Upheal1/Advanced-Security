import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/firebase_auth_service.dart';
import '../services/email_service.dart' as mail;
import '../config.dart';

class AuthModel extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();

  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userName;
  Map<String, int> _failedAttempts = {};
  Map<String, int> _otpAttempts = {};
  Map<String, UserProfile> _userProfiles = {};
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;

  AuthModel() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _firebaseAuthService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _userName = user.displayName;
        if (!_userProfiles.containsKey(user.email)) {
          _userProfiles[user.email!] = UserProfile(
            email: user.email!,
            name: user.displayName ?? '',
            salt: _generateSalt(),
            is2FAEnabled: true,
            isBiometricEnabled: false,
            activities: [],
          );
        }
      } else {
        _isAuthenticated = false;
        _userEmail = null;
        _userName = null;
      }
      notifyListeners();
    });
  }

  String _generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _generateOtp([int length = 6]) {
    final rand = Random.secure();
    return List.generate(length, (_) => rand.nextInt(10)).join();
  }

  String evaluatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    if (score <= 1) return "Weak";
    if (score == 2) return "Medium";
    return "Strong";
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _firebaseAuthService
          .createUserWithEmailAndPassword(email, password);
      if (userCredential != null) {
        await _firebaseAuthService.updateUserProfile(displayName: name);
        _userProfiles[email] = UserProfile(
          email: email,
          name: name,
          salt: _generateSalt(),
          is2FAEnabled: true,
          isBiometricEnabled: false,
          activities: ['Signed up'],
        );
        _isAuthenticated = true;
        _userEmail = email;
        _userName = name;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Failed to create account';
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Signup error: $e');
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool?> login(String email, String password) async {
    try {
      final storedLock = await _storage.read(key: 'lock_$email');
      if (storedLock != null) {
        final lockDate = DateTime.tryParse(storedLock);
        if (lockDate != null && lockDate.isAfter(DateTime.now())) {
          _errorMessage = 'Account is temporarily locked. Try again later.';
          notifyListeners();
          return false;
        } else {
          await _storage.delete(key: 'lock_$email');
        }
      }

      final userCredential = await _firebaseAuthService
          .signInWithEmailAndPassword(email, password);

      if (userCredential != null) {
        _failedAttempts[email] = 0;
        await _storage.delete(key: 'lock_$email');

        final profile = _userProfiles[email];
        profile?.lastLogin = DateTime.now().toIso8601String();
        profile?.activities
            .insert(0, '${DateTime.now().toIso8601String()} - Successful login');

        if (profile != null && profile.is2FAEnabled) {
          final otp = _generateOtp();
          final expiry = DateTime.now()
              .add(const Duration(minutes: 10))
              .toIso8601String();
          await _storage.write(key: 'otp_$email', value: otp);
          await _storage.write(key: 'otp_${email}_expiry', value: expiry);
          await _storage.delete(key: 'otp_${email}_attempts');
          await mail.EmailService.sendOtp(email, otp);
          profile.activities.insert(
              0, '${DateTime.now().toIso8601String()} - OTP sent for 2FA');
          return null;
        }

        _isAuthenticated = true;
        _userEmail = email;
        _userName = _userProfiles[email]?.name ?? '';
        _errorMessage = null;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Invalid email or password';
      notifyListeners();
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      _failedAttempts[email] = (_failedAttempts[email] ?? 0) + 1;
      if (_failedAttempts[email]! >= 5) {
        final lockUntil =
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
        await _storage.write(key: 'lock_$email', value: lockUntil);
        if (!_userProfiles.containsKey(email)) {
          _userProfiles[email] = UserProfile(
            email: email,
            name: '',
            salt: _generateSalt(),
            is2FAEnabled: false,
            isBiometricEnabled: false,
            activities: [],
          );
        }
        _userProfiles[email]?.lockUntil = lockUntil;
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    final attemptsStr =
        await _storage.read(key: 'otp_${email}_attempts') ?? '0';
    final attempts = int.tryParse(attemptsStr) ?? 0;

    if (attempts >= 5) {
      await _storage.delete(key: 'otp_$email');
      await _storage.delete(key: 'otp_${email}_expiry');
      await _storage.delete(key: 'otp_${email}_attempts');
      _errorMessage = 'Too many OTP attempts. Please login again.';
      notifyListeners();
      return false;
    }

    final expiryStr = await _storage.read(key: 'otp_${email}_expiry');
    if (expiryStr == null) {
      _errorMessage = 'OTP not found. Please login again.';
      notifyListeners();
      return false;
    }
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null || DateTime.now().isAfter(expiry)) {
      await _storage.delete(key: 'otp_$email');
      await _storage.delete(key: 'otp_${email}_expiry');
      await _storage.delete(key: 'otp_${email}_attempts');
      _errorMessage = 'OTP has expired. Please login again.';
      notifyListeners();
      return false;
    }

    final storedOtp = await _storage.read(key: 'otp_$email');
    if (storedOtp == otp) {
      final profile = _userProfiles[email];
      _isAuthenticated = true;
      _userEmail = email;
      _userName = profile?.name;
      await _storage.delete(key: 'otp_$email');
      await _storage.delete(key: 'otp_${email}_expiry');
      await _storage.delete(key: 'otp_${email}_attempts');
      profile?.activities.insert(
          0,
          '${DateTime.now().toIso8601String()} - 2FA verified, login complete');
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      await _storage.write(
          key: 'otp_${email}_attempts',
          value: (attempts + 1).toString());
      _userProfiles[email]?.activities.insert(
          0, '${DateTime.now().toIso8601String()} - Invalid OTP attempt');
      _errorMessage =
      'Invalid OTP. ${4 - attempts} attempt(s) remaining.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuthService.signOut();
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleBiometric(String email, bool enabled) async {
    final profile = _userProfiles[email];
    if (profile == null) return;
    profile.isBiometricEnabled = enabled;
    profile.activities.insert(
        0,
        '${DateTime.now().toIso8601String()} - Biometric ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> toggle2FA(String email, bool enabled) async {
    final profile = _userProfiles[email];
    if (profile == null) return;
    profile.is2FAEnabled = enabled;
    profile.activities.insert(
        0,
        '${DateTime.now().toIso8601String()} - 2FA ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuthService.sendPasswordResetEmail(email);
    _userProfiles[email]?.activities.insert(
        0, '${DateTime.now().toIso8601String()} - Password reset requested');
  }

  UserProfile? getUserProfile(String email) {
    return _userProfiles[email];
  }
}

class UserProfile {
  final String email;
  String name;
  final String salt;
  bool is2FAEnabled;
  bool isBiometricEnabled;
  List<String> activities;
  String? lastLogin;
  String? lockUntil;

  UserProfile({
    required this.email,
    required this.name,
    required this.salt,
    required this.is2FAEnabled,
    required this.isBiometricEnabled,
    required this.activities,
    this.lastLogin,
    this.lockUntil,
  });
}
