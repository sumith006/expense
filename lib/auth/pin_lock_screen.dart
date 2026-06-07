import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/routes.dart';
import '../database/hive_service.dart';
import '../providers/shared_providers.dart';
import '../providers/settings_provider.dart';
import '../auth/biometric_service.dart';
import '../theme/neobrutal_theme.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _inputPin = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuth();
    });
  }

  Future<void> _triggerBiometricAuth() async {
    final settings = ref.read(settingsProvider);
    if (settings.isBiometricEnabled) {
      final success = await BiometricService.instance.authenticate();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.neobrutalDashboard);
      }
    }
  }

  void _onKeyPress(String val) {
    if (_isLoading) return;
    setState(() {
      if (_inputPin.length < 4) {
        _inputPin += val;
      }
      if (_inputPin.length == 4) {
        _verifyPin();
      }
    });
  }

  void _onDelete() {
    if (_isLoading || _inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    setState(() { _isLoading = true; });
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isValid = await settingsNotifier.verifyPin(_inputPin);

    if (isValid && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.neobrutalDashboard);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Please try again.'),
            backgroundColor: NeoBrutalTheme.error,
          ),
        );
        setState(() {
          _inputPin = '';
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: NeoBrutalTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: NeoBrutalTheme.radiusLarge),
          title: const Text('Forgot PIN?', style: TextStyle(color: Colors.white)),
          content: const Text(
            'To recover access, you can clear all local app data and reset the security lock. Warning: This will delete everything!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await HiveService.instance.clearAllData();
                final prefs = ref.read(sharedPreferencesProvider);
                await prefs.clear();
                await ref.read(settingsProvider.notifier).disablePin();

                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.pinSetup);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: NeoBrutalTheme.error),
              child: const Text('Reset Everything'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: NeoBrutalTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Header
            Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: NeoBrutalTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: NeoBrutalTheme.primary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 40,
                    color: NeoBrutalTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'ENTER SECURITY PIN',
                  style: NeoBrutalTheme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verify your identity to continue',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = index < _inputPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? NeoBrutalTheme.primary : Colors.white10,
                    boxShadow: active ? [
                      BoxShadow(color: NeoBrutalTheme.primary.withValues(alpha: 0.5), blurRadius: 10)
                    ] : [],
                  ),
                );
              }),
            ),

            const Spacer(),

            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                children: [
                  for (var r = 0; r < 3; r++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var c = 1; c <= 3; c++)
                            _buildNumKey((r * 3 + c).toString()),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (settings.isBiometricEnabled)
                        _buildActionButton(Icons.fingerprint, _triggerBiometricAuth, NeoBrutalTheme.secondary)
                      else
                        const SizedBox(width: 70, height: 70),
                        
                      _buildNumKey('0'),
                      _buildActionButton(Icons.backspace_rounded, _onDelete, Colors.white10),
                    ],
                  ),
                ],
              ),
            ),

            TextButton(
              onPressed: _showForgotPinDialog,
              child: const Text('FORGOT PIN?', style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNumKey(String value) {
    return InkWell(
      onTap: () => _onKeyPress(value),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        child: Center(
          child: Text(
            value,
            style: NeoBrutalTheme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
