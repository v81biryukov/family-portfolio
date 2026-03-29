import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  int _setupStep = 0; // 0: PIN, 1: Confirm
  String _firstPin = ''; // Store first PIN entry

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await ref.read(authNotifierProvider.notifier).authenticateWithBiometric();
    if (success && mounted) {
      context.go(Routes.dashboard);
    }
  }

  Future<void> _authenticateWithPIN() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    final success = await ref.read(authNotifierProvider.notifier).authenticateWithPIN(pin);
    if (success && mounted) {
      context.go(Routes.dashboard);
    }
  }

  Future<void> _setupPIN() async {
    if (_setupStep == 0) {
      // First PIN entry
      final pin = _pinController.text;
      if (pin.length < 4) {
        _showError('PIN must be at least 4 digits');
        return;
      }
      setState(() {
        _firstPin = pin; // Store the first PIN
        _setupStep = 1;
      });
    } else {
      // Confirm PIN
      final confirmPin = _confirmPinController.text;
      
      if (_firstPin != confirmPin) {
        _showError('PINs do not match');
        return;
      }

      final success = await ref.read(authNotifierProvider.notifier).setupPIN(_firstPin);
      if (success && mounted) {
        context.go(Routes.dashboard);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final error = authState.error;

    // Show error if any
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(error);
        ref.read(authNotifierProvider.notifier).clearError();
      });
    }

    // Determine if we need setup or login
    final needsSetup = !authState.pinSet && !authState.biometricEnabled;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: AppConstants.primaryColor,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                needsSetup ? 'Set Up Security' : 'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                needsSetup
                    ? 'Create a PIN to secure your portfolio'
                    : 'Sign in to access your portfolio',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // PIN Input
              if (!needsSetup) ...[
                // Login mode - just enter PIN
                _buildPinInput(
                  controller: _pinController,
                  label: 'Enter PIN',
                  onSubmitted: (_) => _authenticateWithPIN(),
                ),
              ] else if (_setupStep == 0) ...[
                // Setup mode - create PIN
                _buildPinInput(
                  controller: _pinController,
                  label: 'Create PIN',
                  onSubmitted: (_) => _setupPIN(),
                ),
              ] else ...[
                // Setup mode - confirm PIN
                _buildPinInput(
                  controller: _confirmPinController,
                  label: 'Confirm PIN',
                  onSubmitted: (_) => _setupPIN(),
                ),
              ],
              const SizedBox(height: 24),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (needsSetup ? _setupPIN : _authenticateWithPIN),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(needsSetup
                          ? (_setupStep == 0 ? 'Continue' : 'Set PIN')
                          : 'Sign In'),
                ),
              ),
              
              // Back button for confirm step
              if (needsSetup && _setupStep == 1) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _setupStep = 0;
                      _firstPin = '';
                      _confirmPinController.clear();
                    });
                  },
                  child: const Text('Back'),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Biometric option (if available)
              if (!needsSetup && authState.biometricAvailable && authState.biometricEnabled) ...[
                const Divider(),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: isLoading ? null : _authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(authState.biometricEnrolled
                      ? 'Use Biometric'
                      : 'Use Face ID / Touch ID'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput({
    required TextEditingController controller,
    required String label,
    required void Function(String) onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 6,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 8),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
