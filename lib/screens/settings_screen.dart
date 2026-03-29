import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/sync_provider.dart';
import '../providers/auth_provider.dart';
import '../services/yandex_disk_service.dart';
import '../utils/constants.dart';
import '../models/settings_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final settings = syncState.settings ?? AppSettings.withDefaults();
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Yandex.Disk Section
          _buildSectionHeader('Cloud Sync'),
          _buildYandexSection(context, ref, syncState),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader('Security'),
          _buildSecuritySection(context, ref, authState),
          
          const SizedBox(height: 24),
          
          // Customization Section
          _buildSectionHeader('Customization'),
          _buildCustomizationSection(context, ref, settings),
          
          const SizedBox(height: 24),
          
          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildDataSection(context, ref, syncState),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('About'),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildYandexSection(BuildContext context, WidgetRef ref, dynamic syncState) {
    final isAuthenticated = syncState.isAuthenticated;
    final lastSync = syncState.lastSyncTime;

    return Container(
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
        children: [
          if (!isAuthenticated)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_off, color: Colors.orange, size: 22),
              ),
              title: const Text(
                'Connect Yandex.Disk',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Sync your portfolio across devices',
                style: TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
                onPressed: () => _showYandexAuthDialog(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Connect'),
              ),
            )
          else ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cloud_done, color: Colors.green, size: 22),
              ),
              title: const Text(
                'Yandex.Disk Connected',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: lastSync != null
                  ? Text(
                      'Last sync: ${_formatDateTime(lastSync)}',
                      style: const TextStyle(fontSize: 12),
                    )
                  : const Text('Not synced yet', style: TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1),
            _buildActionTile(
              icon: Icons.sync,
              title: 'Sync Now',
              onTap: () => ref.read(syncNotifierProvider.notifier).sync(),
            ),
            _buildActionTile(
              icon: Icons.file_upload,
              title: 'Force Upload',
              subtitle: 'Upload local data to cloud',
              onTap: () => ref.read(syncNotifierProvider.notifier).forceUpload(),
            ),
            _buildActionTile(
              icon: Icons.file_download,
              title: 'Force Download',
              subtitle: 'Download cloud data to local',
              onTap: () => ref.read(syncNotifierProvider.notifier).forceDownload(),
            ),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Disconnect',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () => _confirmDisconnect(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context, WidgetRef ref, dynamic authState) {
    return Container(
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
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fingerprint, color: Color(0xFF8B5CF6), size: 22),
            ),
            title: const Text(
              'Biometric Authentication',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              authState.biometricEnabled ? 'Enabled' : 'Disabled',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: authState.biometricEnabled,
              onChanged: authState.biometricAvailable
                  ? (v) => ref.read(authNotifierProvider.notifier).setBiometricEnabled(v)
                  : null,
              activeColor: const Color(0xFF10B981),
            ),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.pin,
            title: 'Change PIN',
            onTap: () => _showChangePinDialog(context, ref),
          ),
          _buildActionTile(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationSection(BuildContext context, WidgetRef ref, AppSettings settings) {
    return Container(
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
        children: [
          _buildActionTile(
            icon: Icons.people,
            title: 'Portfolio Owners',
            subtitle: '${settings.owners.length} owners configured',
            showArrow: true,
            onTap: () => _showOwnersDialog(context, ref, settings),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.currency_exchange,
            title: 'Currencies',
            subtitle: '${settings.currencies.length} currencies configured',
            showArrow: true,
            onTap: () => _showCurrenciesDialog(context, ref, settings),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.category,
            title: 'Asset Types',
            subtitle: '${settings.assetTypes.length} types configured',
            showArrow: true,
            onTap: () => _showAssetTypesDialog(context, ref, settings),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(BuildContext context, WidgetRef ref, dynamic syncState) {
    return Container(
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
        children: [
          _buildActionTile(
            icon: Icons.backup,
            title: 'Export Backup',
            subtitle: 'Save data to file',
            onTap: () => _exportBackup(context, ref),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.restore,
            title: 'Import Backup',
            subtitle: 'Restore from file',
            onTap: () => _importBackup(context, ref),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _confirmClearData(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Container(
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
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline, color: Color(0xFF64748B)),
            title: Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(height: 1),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help & Support'),
                  content: const Text(
                    'Family Portfolio App\n\n'
                    'Track and manage your family investments in one place.\n\n'
                    'Features:\n'
                    '• Multi-currency support\n'
                    '• Cloud sync with Yandex.Disk\n'
                    '• Visual charts and analytics\n'
                    '• Secure PIN/biometric protection',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    bool showArrow = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF64748B), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: showArrow ? const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)) : null,
      onTap: onTap,
    );
  }

  void _showYandexAuthDialog(BuildContext context, WidgetRef ref) {
    final yandexService = YandexDiskService();
    final authUrl = yandexService.getAuthorizationUrl();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Connect Yandex.Disk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To connect your Yandex.Disk:'),
            const SizedBox(height: 12),
            _buildStepText('1. Tap "Open Yandex" button below'),
            _buildStepText('2. Sign in to your Yandex account'),
            _buildStepText('3. Allow access to Family Portfolio'),
            _buildStepText('4. Copy the authorization code'),
            _buildStepText('5. Return here and paste the code'),
            const SizedBox(height: 16),
            // Open Yandex Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(authUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open Yandex')),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Yandex'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC3F1D), // Yandex red color
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Authorization Code',
                hintText: 'Paste code here',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                final success = await yandexService.exchangeCodeForToken(code);
                if (success) {
                  ref.read(syncNotifierProvider.notifier).checkAuthStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connected to Yandex.Disk')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to connect')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disconnect Yandex.Disk?'),
        content: const Text('Your local data will be preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await YandexDiskService().logout();
              ref.read(syncNotifierProvider.notifier).checkAuthStatus();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: 'New PIN',
            hintText: 'Enter 4-6 digit PIN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = controller.text;
              if (pin.length >= 4) {
                await ref.read(authNotifierProvider.notifier).setupPIN(pin);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN updated')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go(Routes.login);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // ==================== OWNERS DIALOG ====================
  void _showOwnersDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _OwnersDialog(settings: settings, ref: ref),
    );
  }

  // ==================== CURRENCIES DIALOG ====================
  void _showCurrenciesDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _CurrenciesDialog(settings: settings, ref: ref),
    );
  }

  // ==================== ASSET TYPES DIALOG ====================
  void _showAssetTypesDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => _AssetTypesDialog(settings: settings, ref: ref),
    );
  }

  void _exportBackup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Export Backup'),
        content: const Text(
          'This feature will export your data to a JSON file.\n\n'
          'Note: For web version, the download will start automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _importBackup(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Import Backup'),
        content: const Text(
          'This feature will import data from a JSON backup file.\n\n'
          'Warning: This will replace your current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Import feature coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your portfolio data. '
          'Make sure you have a backup before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(syncNotifierProvider.notifier).clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('MMM d, yyyy HH:mm').format(date);
  }
}

// ==================== OWNERS DIALOG WIDGET ====================
class _OwnersDialog extends ConsumerStatefulWidget {
  final AppSettings settings;
  final WidgetRef ref;

  const _OwnersDialog({required this.settings, required this.ref});

  @override
  ConsumerState<_OwnersDialog> createState() => _OwnersDialogState();
}

class _OwnersDialogState extends ConsumerState<_OwnersDialog> {
  late List<OwnerInfo> owners;

  @override
  void initState() {
    super.initState();
    owners = List.from(widget.settings.owners);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.people, color: Color(0xFF3B82F6)),
          SizedBox(width: 8),
          Text('Portfolio Owners'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: owners.length,
                itemBuilder: (context, index) {
                  final owner = owners[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _parseColor(owner.color).withOpacity(0.2),
                      child: Text(
                        owner.name,
                        style: TextStyle(
                          color: _parseColor(owner.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(owner.name),
                    subtitle: Text('Code: ${owner.code}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                          onPressed: () => _showEditOwnerDialog(index, owner),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              owners.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Owner'),
              onTap: () => _showAddOwnerDialog(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedSettings = widget.settings.copyWith(owners: owners);
            await widget.ref.read(syncNotifierProvider.notifier).updateSettings(updatedSettings);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showAddOwnerDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., John',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'e.g., J',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isNotEmpty && code.isNotEmpty) {
                setState(() {
                  owners.add(OwnerInfo(
                    id: 'owner_${DateTime.now().millisecondsSinceEpoch}',
                    code: code,
                    name: name,
                    color: '#3B82F6',
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditOwnerDialog(int index, OwnerInfo owner) {
    final nameController = TextEditingController(text: owner.name);
    final codeController = TextEditingController(text: owner.code);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'e.g., John',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code',
                hintText: 'e.g., J',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final code = codeController.text.trim();
              if (name.isNotEmpty && code.isNotEmpty) {
                setState(() {
                  owners[index] = OwnerInfo(
                    id: owner.id,
                    code: code,
                    name: name,
                    color: owner.color,
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}

// ==================== CURRENCIES DIALOG WIDGET ====================
class _CurrenciesDialog extends ConsumerStatefulWidget {
  final AppSettings settings;
  final WidgetRef ref;

  const _CurrenciesDialog({required this.settings, required this.ref});

  @override
  ConsumerState<_CurrenciesDialog> createState() => _CurrenciesDialogState();
}

// Predefined world currencies with flags
final worldCurrencies = [
  {'code': 'USD', 'name': 'US Dollar', 'symbol': r'$', 'flag': '🇺🇸'},
  {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
  {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
  {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'Fr', 'flag': '🇨🇭'},
  {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': r'$', 'flag': '🇨🇦'},
  {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': r'$', 'flag': '🇦🇺'},
  {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
  {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽', 'flag': '🇷🇺'},
  {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
  {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': r'R$', 'flag': '🇧🇷'},
  {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R', 'flag': '🇿🇦'},
  {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': r'$', 'flag': '🇲🇽'},
  {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': r'$', 'flag': '🇸🇬'},
  {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': r'$', 'flag': '🇭🇰'},
  {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
  {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr', 'flag': '🇸🇪'},
  {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr', 'flag': '🇳🇴'},
  {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr', 'flag': '🇩🇰'},
  {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł', 'flag': '🇵🇱'},
  {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
  {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ', 'flag': '🇦🇪'},
  {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼', 'flag': '🇸🇦'},
  {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿', 'flag': '🇹🇭'},
  {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
  {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
  {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱', 'flag': '🇵🇭'},
  {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': r'$', 'flag': '🇳🇿'},
  {'code': 'ILS', 'name': 'Israeli Shekel', 'symbol': '₪', 'flag': '🇮🇱'},
  {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': '£', 'flag': '🇪🇬'},
];

class _CurrenciesDialogState extends ConsumerState<_CurrenciesDialog> {
  late List<CurrencyInfo> currencies;

  @override
  void initState() {
    super.initState();
    currencies = List.from(widget.settings.currencies);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.currency_exchange, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Currencies'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return ListTile(
                    leading: Text(currency.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(currency.name),
                    subtitle: Text('${currency.code} (${currency.symbol})'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          currencies.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Currency'),
              onTap: () => _showAddCurrencyDialog(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedSettings = widget.settings.copyWith(currencies: currencies);
            await widget.ref.read(syncNotifierProvider.notifier).updateSettings(updatedSettings);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showAddCurrencyDialog() {
    // Filter out already added currencies
    final addedCodes = currencies.map((c) => c.code).toSet();
    final availableCurrencies = worldCurrencies
        .where((c) => !addedCodes.contains(c['code']))
        .toList();

    if (availableCurrencies.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No More Currencies'),
          content: const Text('All available currencies have been added.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Currency'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: availableCurrencies.length,
            itemBuilder: (context, index) {
              final currency = availableCurrencies[index];
              return ListTile(
                leading: Text(currency['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(currency['name']!),
                subtitle: Text('${currency['code']} (${currency['symbol']})'),
                onTap: () {
                  setState(() {
                    currencies.add(CurrencyInfo(
                      id: 'ccy_${DateTime.now().millisecondsSinceEpoch}',
                      code: currency['code']!,
                      name: currency['name']!,
                      symbol: currency['symbol']!,
                      flag: currency['flag']!,
                    ));
                  });
                  Navigator.pop(context);
                  
                  // Show message about exchange rate
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${currency['code']} added. Go to FX Rates to update the exchange rate.'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ==================== ASSET TYPES DIALOG WIDGET ====================
class _AssetTypesDialog extends ConsumerStatefulWidget {
  final AppSettings settings;
  final WidgetRef ref;

  const _AssetTypesDialog({required this.settings, required this.ref});

  @override
  ConsumerState<_AssetTypesDialog> createState() => _AssetTypesDialogState();
}

class _AssetTypesDialogState extends ConsumerState<_AssetTypesDialog> {
  late List<AssetTypeInfo> assetTypes;

  @override
  void initState() {
    super.initState();
    assetTypes = List.from(widget.settings.assetTypes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.category, color: Color(0xFF8B5CF6)),
          SizedBox(width: 8),
          Text('Asset Types'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: assetTypes.length,
                itemBuilder: (context, index) {
                  final type = assetTypes[index];
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(type.color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    title: Text(type.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                          onPressed: () => _showEditAssetTypeDialog(index, type),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              assetTypes.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF10B981),
                child: Icon(Icons.add, color: Colors.white),
              ),
              title: const Text('Add Asset Type'),
              onTap: () => _showAddAssetTypeDialog(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final updatedSettings = widget.settings.copyWith(assetTypes: assetTypes);
            await widget.ref.read(syncNotifierProvider.notifier).updateSettings(updatedSettings);
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showAddAssetTypeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Asset Type'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'e.g., Real Estate',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  assetTypes.add(AssetTypeInfo(
                    id: 'type_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    color: '#3B82F6',
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAssetTypeDialog(int index, AssetTypeInfo type) {
    final nameController = TextEditingController(text: type.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Asset Type'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'e.g., Real Estate',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  assetTypes[index] = AssetTypeInfo(
                    id: type.id,
                    name: name,
                    color: type.color,
                  );
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
