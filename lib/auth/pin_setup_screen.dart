import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/routes.dart';
import '../providers/shared_providers.dart';
import '../providers/settings_provider.dart';
import '../auth/biometric_service.dart';
import '../theme/neobrutal_theme.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _enableBiometrics = false;
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.instance.isBiometricAvailable();
    setState(() {
      _canBiometric = available;
      if (available) {
        _enableBiometrics = true;
      }
    });
  }

  void _onKeyPress(String val) {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.length < 4) {
          _confirmPin += val;
        }
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      } else {
        if (_pin.length < 4) {
          _pin += val;
        }
        if (_pin.length == 4) {
          _isConfirming = true;
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin == _confirmPin) {
      final settingsNotifier = ref.read(settingsProvider.notifier);
      await settingsNotifier.setPin(_pin);
      if (_enableBiometrics) {
        await settingsNotifier.updateBiometrics(true);
      }
      
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('is_first_launch', false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN Setup Successful!'),
            backgroundColor: NeoBrutalTheme.success,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.neobrutalDashboard);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Please try again.'),
          backgroundColor: NeoBrutalTheme.error,
        ),
      );
      setState(() {
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConfirming ? 'CONFIRM PIN' : 'CREATE SECURITY PIN';
    final subtitle = _isConfirming ? 'Please re-enter your 4-digit code' : 'Secure your financial & productivity data';
    final currentInput = _isConfirming ? _confirmPin : _pin;

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
                    color: NeoBrutalTheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: NeoBrutalTheme.secondary.withValues(alpha: 0.2), width: 1),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 40,
                    color: NeoBrutalTheme.secondary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: NeoBrutalTheme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // PIN Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final active = index < currentInput.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? NeoBrutalTheme.secondary : Colors.white10,
                    boxShadow: active ? [
                      BoxShadow(color: NeoBrutalTheme.secondary.withValues(alpha: 0.5), blurRadius: 10)
                    ] : [],
                  ),
                );
              }),
            ),

            const Spacer(),

            // Biometric Option
            if (_canBiometric)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: InkWell(
                  onTap: () => setState(() => _enableBiometrics = !_enableBiometrics),
                  borderRadius: NeoBrutalTheme.radiusMedium,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: NeoBrutalTheme.radiusMedium,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fingerprint_rounded, color: _enableBiometrics ? NeoBrutalTheme.success : Colors.white24),
                        const SizedBox(width: 12),
                        const Text('USE BIOMETRICS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const Spacer(),
                        Switch(
                          value: _enableBiometrics,
                          onChanged: (val) => setState(() => _enableBiometrics = val),
                          activeThumbColor: NeoBrutalTheme.success,
                        )
                      ],
                    ),
                  ),
                ),
              ),

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
                      const SizedBox(width: 70, height: 70),
                      _buildNumKey('0'),
                      _buildActionButton(Icons.backspace_rounded, _onDelete, Colors.white10),
                    ],
                  ),
                ],
              ),
            ),
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
