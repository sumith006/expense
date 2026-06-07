import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final BiometricService instance = BiometricService._init();
  final LocalAuthentication _auth = LocalAuthentication();

  BiometricService._init();

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      // Check if device supports biometrics
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) return false;

      // Check if biometrics are enrolled
      final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('Biometric availability error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected biometric error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to access Expense & Task Manager',
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Authentication error: ${e.message}');
      if (e.code == 'NotAvailable') {
        debugPrint('Biometrics not available on this device');
      } else if (e.code == 'NotEnrolled') {
        debugPrint('No biometrics enrolled');
      }
      return false;
    } catch (e) {
      debugPrint('Auth error: $e');
      return false;
    }
  }

  // Helper for emulator testing
  Future<bool> isProbablyEmulator() async {
    if (kIsWeb) return false;
    try {
      final List<BiometricType> available = await _auth.getAvailableBiometrics();
      return available.isEmpty;
    } catch (_) {
      return true;
    }
  }
}
