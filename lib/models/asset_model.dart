import 'package:hive/hive.dart';

part 'asset_model.g.dart'; // Only for Hive adapter

@HiveType(typeId: 1)
class Asset extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String owner;
  
  @HiveField(2)
  String assetType;
  
  @HiveField(3)
  String institution;
  
  @HiveField(4)
  String country;
  
  @HiveField(5)
  String currency;
  
  @HiveField(6)
  double amountInCCY;
  
  @HiveField(7)
  double interestRate;
  
  // Calculated fields
  @HiveField(8)
  double annualIncomeCCY;
  
  @HiveField(9)
  double monthlyIncomeCCY;
  
  @HiveField(10)
  double amountInUSD;
  
  @HiveField(11)
  double annualIncomeUSD;
  
  @HiveField(12)
  double monthlyIncomeUSD;
  
  // Metadata
  @HiveField(13)
  DateTime createdAt;
  
  @HiveField(14)
  DateTime updatedAt;

  Asset({
    required this.id,
    required this.owner,
    required this.assetType,
    required this.institution,
    required this.country,
    required this.currency,
    required this.amountInCCY,
    required this.interestRate,
    this.annualIncomeCCY = 0,
    this.monthlyIncomeCCY = 0,
    this.amountInUSD = 0,
    this.annualIncomeUSD = 0,
    this.monthlyIncomeUSD = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate derived fields
  Asset calculateFields(Map<String, double> exchangeRates) {
    final rate = exchangeRates[currency] ?? 1.0;
    final annualIncome = amountInCCY * interestRate;
    final monthlyIncome = annualIncome / 12;
    
    return Asset(
      id: id,
      owner: owner,
      assetType: assetType,
      institution: institution,
      country: country,
      currency: currency,
      amountInCCY: amountInCCY,
      interestRate: interestRate,
      annualIncomeCCY: annualIncome,
      monthlyIncomeCCY: monthlyIncome,
      amountInUSD: amountInCCY / rate,
      annualIncomeUSD: annualIncome / rate,
      monthlyIncomeUSD: monthlyIncome / rate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Copy with method
  Asset copyWith({
    String? id,
    String? owner,
    String? assetType,
    String? institution,
    String? country,
    String? currency,
    double? amountInCCY,
    double? interestRate,
    double? annualIncomeCCY,
    double? monthlyIncomeCCY,
    double? amountInUSD,
    double? annualIncomeUSD,
    double? monthlyIncomeUSD,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      assetType: assetType ?? this.assetType,
      institution: institution ?? this.institution,
      country: country ?? this.country,
      currency: currency ?? this.currency,
      amountInCCY: amountInCCY ?? this.amountInCCY,
      interestRate: interestRate ?? this.interestRate,
      annualIncomeCCY: annualIncomeCCY ?? this.annualIncomeCCY,
      monthlyIncomeCCY: monthlyIncomeCCY ?? this.monthlyIncomeCCY,
      amountInUSD: amountInUSD ?? this.amountInUSD,
      annualIncomeUSD: annualIncomeUSD ?? this.annualIncomeUSD,
      monthlyIncomeUSD: monthlyIncomeUSD ?? this.monthlyIncomeUSD,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': owner,
      'assetType': assetType,
      'institution': institution,
      'country': country,
      'currency': currency,
      'amountInCCY': amountInCCY,
      'interestRate': interestRate,
      'annualIncomeCCY': annualIncomeCCY,
      'monthlyIncomeCCY': monthlyIncomeCCY,
      'amountInUSD': amountInUSD,
      'annualIncomeUSD': annualIncomeUSD,
      'monthlyIncomeUSD': monthlyIncomeUSD,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      owner: json['owner'] as String,
      assetType: json['assetType'] as String,
      institution: json['institution'] as String,
      country: json['country'] as String,
      currency: json['currency'] as String,
      amountInCCY: (json['amountInCCY'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      annualIncomeCCY: (json['annualIncomeCCY'] as num?)?.toDouble() ?? 0,
      monthlyIncomeCCY: (json['monthlyIncomeCCY'] as num?)?.toDouble() ?? 0,
      amountInUSD: (json['amountInUSD'] as num?)?.toDouble() ?? 0,
      annualIncomeUSD: (json['annualIncomeUSD'] as num?)?.toDouble() ?? 0,
      monthlyIncomeUSD: (json['monthlyIncomeUSD'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// Asset Input for creating new assets
class AssetInput {
  String owner;
  String assetType;
  String institution;
  String country;
  String currency;
  double amountInCCY;
  double interestRate;

  AssetInput({
    required this.owner,
    required this.assetType,
    required this.institution,
    required this.country,
    required this.currency,
    required this.amountInCCY,
    required this.interestRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'owner': owner,
      'assetType': assetType,
      'institution': institution,
      'country': country,
      'currency': currency,
      'amountInCCY': amountInCCY,
      'interestRate': interestRate,
    };
  }

  factory AssetInput.fromJson(Map<String, dynamic> json) {
    return AssetInput(
      owner: json['owner'] as String,
      assetType: json['assetType'] as String,
      institution: json['institution'] as String,
      country: json['country'] as String,
      currency: json['currency'] as String,
      amountInCCY: (json['amountInCCY'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
    );
  }
}
