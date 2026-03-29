import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/yandex_disk_service.dart';
import '../providers/sync_provider.dart';
import '../utils/constants.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? code;

  const AuthCallbackScreen({super.key, this.code});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  bool _isProcessing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _processAuth();
  }

  Future<void> _processAuth() async {
    if (widget.code == null) {
      setState(() {
        _isProcessing = false;
        _error = 'No authorization code received';
      });
      return;
    }

    final success = await YandexDiskService().exchangeCodeForToken(widget.code!);

    if (success) {
      ref.read(syncNotifierProvider.notifier).checkAuthStatus();
      if (mounted) {
        context.go(Routes.dashboard);
      }
    } else {
      setState(() {
        _isProcessing = false;
        _error = 'Failed to authenticate. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Connecting to Yandex.Disk...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go(Routes.settings),
                        child: const Text('Go to Settings'),
                      ),
                    ],
                  )
                : const Icon(Icons.check_circle, size: 64, color: Colors.green),
      ),
    );
  }
}
