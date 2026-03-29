import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../providers/sync_provider.dart';
import '../models/asset_model.dart';
import '../models/settings_model.dart';
import '../utils/constants.dart';

class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _institutionController = TextEditingController();
  final _countryController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  
  String? _selectedOwner;
  String? _selectedType;
  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(syncNotifierProvider).settings ?? AppSettings.withDefaults();
    _selectedOwner = settings.owners.firstOrNull?.code;
    _selectedType = settings.assetTypes.firstOrNull?.name;
    _selectedCurrency = settings.currencies.firstOrNull?.code;
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _countryController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = ref.read(syncNotifierProvider).settings ?? AppSettings.withDefaults();
    final exchangeRates = ref.read(syncNotifierProvider).exchangeRates;
    
    final rateMap = {for (var r in exchangeRates) r.fromCurrency: r.rate};

    final input = AssetInput(
      owner: _selectedOwner!,
      assetType: _selectedType!,
      institution: _institutionController.text.trim(),
      country: _countryController.text.trim(),
      currency: _selectedCurrency!,
      amountInCCY: double.parse(_amountController.text),
      interestRate: double.parse(_rateController.text) / 100,
    );

    final asset = Asset(
      id: const Uuid().v4(),
      owner: input.owner,
      assetType: input.assetType,
      institution: input.institution,
      country: input.country,
      currency: input.currency,
      amountInCCY: input.amountInCCY,
      interestRate: input.interestRate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).calculateFields(rateMap);

    await ref.read(syncNotifierProvider.notifier).addAsset(asset);
    
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncNotifierProvider);
    final settings = syncState.settings ?? AppSettings.withDefaults();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Asset'),
        actions: [
          TextButton(
            onPressed: _saveAsset,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner
              _buildDropdown(
                label: 'Owner',
                value: _selectedOwner,
                items: settings.owners.map((o) => DropdownMenuItem(
                  value: o.code,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse(o.color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(o.name),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedOwner = v),
              ),
              const SizedBox(height: 16),

              // Asset Type
              _buildDropdown(
                label: 'Asset Type',
                value: _selectedType,
                items: settings.assetTypes.map((t) => DropdownMenuItem(
                  value: t.name,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(int.parse(t.color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(t.name),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
              ),
              const SizedBox(height: 16),

              // Institution
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution',
                  hintText: 'e.g., Bank 1, Broker X',
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Country
              Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return commonCountries;
                  }
                  return commonCountries.where((c) =>
                    c.toLowerCase().contains(textEditingValue.text.toLowerCase())
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _countryController.text = controller.text;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'e.g., US, Russia',
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  );
                },
                onSelected: (selection) {
                  _countryController.text = selection;
                },
              ),
              const SizedBox(height: 16),

              // Currency
              _buildDropdown(
                label: 'Currency',
                value: _selectedCurrency,
                items: settings.currencies.map((c) => DropdownMenuItem(
                  value: c.code,
                  child: Row(
                    children: [
                      Text(c.flag),
                      const SizedBox(width: 8),
                      Text('${c.code} (${c.symbol})'),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: InputDecoration(
                  labelText: 'Amount (${_selectedCurrency ?? ''})',
                  hintText: '0.00',
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Required';
                  if (double.tryParse(v!) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Interest Rate
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: const InputDecoration(
                  labelText: 'Annual Interest Rate (%)',
                  hintText: '0.00',
                  suffixText: '%',
                ),
                validator: (v) {
                  if (v?.isEmpty == true) return 'Required';
                  final rate = double.tryParse(v!);
                  if (rate == null) return 'Invalid number';
                  if (rate < 0 || rate > 100) return 'Must be 0-100';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Preview
              if (_amountController.text.isNotEmpty && _rateController.text.isNotEmpty)
                _buildPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildPreview() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = (double.tryParse(_rateController.text) ?? 0) / 100;
    final annualIncome = amount * rate;
    final monthlyIncome = annualIncome / 12;

    return Card(
      color: AppConstants.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preview',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Annual Income:', style: TextStyle(color: Colors.grey.shade600)),
                    Text(
                      annualIncome.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Monthly Income:', style: TextStyle(color: Colors.grey.shade600)),
                    Text(
                      monthlyIncome.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
