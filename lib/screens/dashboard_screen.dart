import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../models/asset_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final assets = syncState.assets;
    final kpis = _calculateKPIs(assets);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverToBoxAdapter(
              child: _buildModernAppBar(context, ref, syncState),
            ),

            // Status Banners
            SliverToBoxAdapter(
              child: _buildStatusSection(context, ref, syncState),
            ),

            // KPI Cards
            SliverToBoxAdapter(
              child: _buildKPISection(context, kpis),
            ),

            // Portfolio Overview Title
            SliverToBoxAdapter(
              child: assets.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Portfolio Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Charts Grid
            SliverToBoxAdapter(
              child: assets.isNotEmpty
                  ? _buildChartsSection(assets)
                  : _buildEmptyState(context),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addAsset),
        backgroundColor: const Color(0xFF3B82F6),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text('Add Asset'),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, WidgetRef ref, dynamic syncState) {
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
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Portfolio',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Track your investments',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: syncState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    syncState.isOnline ? Icons.sync : Icons.sync_disabled,
                    color: syncState.isOnline ? const Color(0xFF3B82F6) : Colors.grey,
                  ),
            onPressed: syncState.isSyncing || !syncState.isOnline
                ? null
                : () => ref.read(syncNotifierProvider.notifier).sync(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF64748B)),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, WidgetRef ref, dynamic syncState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (!syncState.isOnline)
            _buildStatusBanner(
              icon: Icons.wifi_off,
              message: 'You are offline. Changes will sync when you reconnect.',
              color: Colors.orange,
            ),
          if (!syncState.isAuthenticated && syncState.isOnline)
            _buildStatusBanner(
              icon: Icons.cloud_off,
              message: 'Connect Yandex.Disk to sync across devices',
              color: const Color(0xFF3B82F6),
              action: TextButton(
                onPressed: () => _showYandexAuthDialog(context, ref),
                child: const Text('Connect'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String message,
    required Color color,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildKPISection(BuildContext context, KPIs kpis) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Total Value - Hero Card
          _buildHeroCard(context, kpis),
          const SizedBox(height: 16),
          // Other KPIs
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Annual Income',
                  value: _formatCurrency(kpis.totalAnnualIncomeUSD),
                  subtitle: 'Projected yearly',
                  icon: Icons.trending_up,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Monthly Income',
                  value: _formatCurrency(kpis.totalMonthlyIncomeUSD),
                  subtitle: 'Average per month',
                  icon: Icons.calendar_month,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  title: 'Total Assets',
                  value: kpis.totalAssets.toString(),
                  subtitle: 'Investments',
                  icon: Icons.pie_chart,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKPICard(
                  title: 'Avg. Return',
                  value: '${(kpis.averageInterestRate * 100).toStringAsFixed(2)}%',
                  subtitle: 'Weighted average',
                  icon: Icons.percent,
                  gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, KPIs kpis) {
    return GestureDetector(
      onDoubleTap: () {
        context.push(Routes.assets);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigating to Assets...'),
            duration: Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Total Portfolio Value',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(kpis.totalValueUSD),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatCurrency(kpis.totalAnnualIncomeUSD)}/year income',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(List<Asset> assets) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Assets by Type - Pie Chart
          _buildChartCard(
            title: 'Assets by Type',
            icon: Icons.pie_chart_outline,
            child: _buildModernPieChart(_getAssetsByType(assets)),
          ),
          const SizedBox(height: 16),

          // Assets by Owner - Bar Chart
          _buildChartCard(
            title: 'Assets by Owner',
            icon: Icons.bar_chart,
            child: _buildModernBarChart(_getAssetsByOwner(assets)),
          ),
          const SizedBox(height: 16),

          // Currency Distribution
          _buildChartCard(
            title: 'Currency Distribution',
            icon: Icons.currency_exchange,
            child: _buildModernPieChart(_getAssetsByCurrency(assets)),
          ),
          const SizedBox(height: 16),

          // Income Summary
          _buildIncomeSummaryCard(assets),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildModernPieChart(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final total = data.values.fold(0.0, (a, b) => a + b);
    final sortedData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sortedData.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final percentage = total > 0 ? (item.value / total * 100) : 0;

                return PieChartSectionData(
                  value: item.value,
                  title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
                  color: AppConstants.chartColors[index % AppConstants.chartColors.length],
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 3,
              centerSpaceRadius: 35,
              centerSpaceColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: sortedData.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final percentage = total > 0 ? (item.value / total * 100) : 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppConstants.chartColors[index % AppConstants.chartColors.length]
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppConstants.chartColors[index % AppConstants.chartColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.key}: ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModernBarChart(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: const Color(0xFF1E293B),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatCurrency(rod.toY),
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.keys.elementAt(index),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.value,
                  color: AppConstants.chartColors[index % AppConstants.chartColors.length],
                  width: 35,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.chartColors[index % AppConstants.chartColors.length],
                      AppConstants.chartColors[index % AppConstants.chartColors.length]
                          .withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIncomeSummaryCard(List<Asset> assets) {
    final incomeByType = _getIncomeByType(assets);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Income by Asset Type',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...incomeByType.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(entry.value['annual']!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(entry.value['monthly']!)}/mo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: const Color(0xFF3B82F6).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No assets yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first investment to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(Routes.addAsset),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Asset'),
          ),
        ],
      ),
    );
  }

  void _showYandexAuthDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connect Yandex.Disk'),
        content: const Text(
          'To sync your portfolio across devices, connect your Yandex.Disk account. '
          'Go to Settings to set up the connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(Routes.settings);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  KPIs _calculateKPIs(List<Asset> assets) {
    if (assets.isEmpty) {
      return const KPIs(
        totalValueUSD: 0,
        totalAnnualIncomeUSD: 0,
        totalMonthlyIncomeUSD: 0,
        totalAssets: 0,
        averageInterestRate: 0,
      );
    }

    final totalValueUSD = assets.fold(0.0, (sum, a) => sum + a.amountInUSD);
    final totalAnnualIncomeUSD = assets.fold(0.0, (sum, a) => sum + a.annualIncomeUSD);
    final totalMonthlyIncomeUSD = assets.fold(0.0, (sum, a) => sum + a.monthlyIncomeUSD);

    final weightedRateSum = assets.fold(
      0.0,
      (sum, a) => sum + a.interestRate * a.amountInUSD,
    );
    final averageInterestRate = totalValueUSD > 0 ? weightedRateSum / totalValueUSD : 0.0;

    return KPIs(
      totalValueUSD: totalValueUSD,
      totalAnnualIncomeUSD: totalAnnualIncomeUSD,
      totalMonthlyIncomeUSD: totalMonthlyIncomeUSD,
      totalAssets: assets.length,
      averageInterestRate: averageInterestRate.toDouble(),
    );
  }

  Map<String, double> _getAssetsByType(List<Asset> assets) {
    final map = <String, double>{};
    for (final asset in assets) {
      map[asset.assetType] = (map[asset.assetType] ?? 0) + asset.amountInUSD;
    }
    return map;
  }

  Map<String, double> _getAssetsByOwner(List<Asset> assets) {
    final map = <String, double>{};
    for (final asset in assets) {
      map[asset.owner] = (map[asset.owner] ?? 0) + asset.amountInUSD;
    }
    return map;
  }

  Map<String, double> _getAssetsByCurrency(List<Asset> assets) {
    final map = <String, double>{};
    for (final asset in assets) {
      map[asset.currency] = (map[asset.currency] ?? 0) + asset.amountInUSD;
    }
    return map;
  }

  Map<String, Map<String, double>> _getIncomeByType(List<Asset> assets) {
    final map = <String, Map<String, double>>{};
    for (final asset in assets) {
      map[asset.assetType] = {
        'annual': (map[asset.assetType]?['annual'] ?? 0) + asset.annualIncomeUSD,
        'monthly': (map[asset.assetType]?['monthly'] ?? 0) + asset.monthlyIncomeUSD,
      };
    }
    return map;
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: r'$', decimalDigits: 0).format(value);
  }
}

class KPIs {
  final double totalValueUSD;
  final double totalAnnualIncomeUSD;
  final double totalMonthlyIncomeUSD;
  final int totalAssets;
  final double averageInterestRate;

  const KPIs({
    required this.totalValueUSD,
    required this.totalAnnualIncomeUSD,
    required this.totalMonthlyIncomeUSD,
    required this.totalAssets,
    required this.averageInterestRate,
  });
}
