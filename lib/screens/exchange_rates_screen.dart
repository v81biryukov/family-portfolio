import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/sync_provider.dart';
import '../services/exchange_rate_api.dart';
import '../utils/constants.dart';

class ExchangeRatesScreen extends ConsumerStatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  ConsumerState<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends ConsumerState<ExchangeRatesScreen> {
  bool _isUpdating = false;
  String? _updateError;

  Future<void> _updateFromInternet() async {
    setState(() {
      _isUpdating = true;
      _updateError = null;
    });

    try {
      final api = ExchangeRateApiService();
      final rates = await api.fetchLatestRates();

      if (rates != null) {
        final syncNotifier = ref.read(syncNotifierProvider.notifier);
        final currentRates = ref.read(syncNotifierProvider).exchangeRates;

        for (final rate in currentRates) {
          if (rate.fromCurrency != 'USD') {
            final newRate = rates[rate.fromCurrency];
            if (newRate != null) {
              await syncNotifier.updateExchangeRate(
                rate.copyWith(rate: newRate, updatedAt: DateTime.now()),
              );
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exchange rates updated successfully'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else {
        setState(() => _updateError = 'Failed to fetch rates from server');
      }
    } catch (e) {
      setState(() => _updateError = 'Error: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    final rates = syncState.exchangeRates;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(),
            ),

            // Info Card
            SliverToBoxAdapter(
              child: _buildInfoCard(),
            ),

            // Error Banner
            if (_updateError != null)
              SliverToBoxAdapter(
                child: _buildErrorBanner(),
              ),

            // Rates List
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rate = rates[index];
                    return _RateCard(
                      rate: rate,
                      onUpdate: (newRate) {
                        ref.read(syncNotifierProvider.notifier).updateExchangeRate(
                          rate.copyWith(rate: newRate, updatedAt: DateTime.now()),
                        );
                      },
                    );
                  },
                  childCount: rates.length,
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.currency_exchange,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exchange Rates',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Manage currency conversion rates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh, color: Colors.white),
              onPressed: _isUpdating ? null : _updateFromInternet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Exchange Rates',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Rates are used to convert asset values to USD. Tap the refresh button to get the latest rates from the internet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _updateError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700, size: 18),
            onPressed: () => setState(() => _updateError = null),
          ),
        ],
      ),
    );
  }
}

class _RateCard extends StatefulWidget {
  final dynamic rate;
  final void Function(double) onUpdate;

  const _RateCard({required this.rate, required this.onUpdate});

  @override
  State<_RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<_RateCard> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.rate.rate.toStringAsFixed(4));
  }

  @override
  void didUpdateWidget(covariant _RateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rate.rate != widget.rate.rate) {
      _controller.text = widget.rate.rate.toStringAsFixed(4);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.rate;
    final flag = _getFlag(rate.fromCurrency);
    final isBaseCurrency = rate.fromCurrency == 'USD';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Currency flag
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: isBaseCurrency
                  ? const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    )
                  : LinearGradient(
                      colors: [
                        _getCurrencyColor(rate.fromCurrency),
                        _getCurrencyColor(rate.fromCurrency).withOpacity(0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Currency info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rate.fromCurrency,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (isBaseCurrency) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'BASE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '1 USD = ${rate.rate.toStringAsFixed(4)} ${rate.fromCurrency}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Updated: ${_formatDate(rate.updatedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit field
          if (!isBaseCurrency)
            Container(
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  final newRate = double.tryParse(value);
                  if (newRate != null && newRate > 0) {
                    widget.onUpdate(newRate);
                  }
                },
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '1.0000',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getFlag(String currency) {
    switch (currency) {
      case 'USD':
        return '🇺🇸';
      case 'EUR':
        return '🇪🇺';
      case 'RUB':
        return '🇷🇺';
      case 'GBP':
        return '🇬🇧';
      case 'JPY':
        return '🇯🇵';
      case 'CNY':
        return '🇨🇳';
      case 'CHF':
        return '🇨🇭';
      case 'CAD':
        return '🇨🇦';
      case 'AUD':
        return '🇦🇺';
      default:
        return '🏳️';
    }
  }

  Color _getCurrencyColor(String currency) {
    switch (currency) {
      case 'USD':
        return const Color(0xFF3B82F6);
      case 'EUR':
        return const Color(0xFF8B5CF6);
      case 'RUB':
        return const Color(0xFFEF4444);
      case 'GBP':
        return const Color(0xFF10B981);
      case 'JPY':
        return const Color(0xFFF59E0B);
      case 'CNY':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, HH:mm').format(date);
  }
}
