import 'package:hive/hive.dart';

part 'exchange_rate_model.g.dart';

@HiveType(typeId: 2)
class ExchangeRate extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String fromCurrency;
  
  @HiveField(2)
  String toCurrency;
  
  @HiveField(3)
  double rate;
  
  @HiveField(4)
  DateTime updatedAt;

  ExchangeRate({
    required this.id,
    required this.fromCurrency,
    this.toCurrency = 'USD',
    required this.rate,
    required this.updatedAt,
  });

  // Copy with method
  ExchangeRate copyWith({
    String? id,
    String? fromCurrency,
    String? toCurrency,
    double? rate,
    DateTime? updatedAt,
  }) {
    return ExchangeRate(
      id: id ?? this.id,
      fromCurrency: fromCurrency ?? this.fromCurrency,
      toCurrency: toCurrency ?? this.toCurrency,
      rate: rate ?? this.rate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'rate': rate,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      id: json['id'] as String,
      fromCurrency: json['fromCurrency'] as String,
      toCurrency: json['toCurrency'] as String? ?? 'USD',
      rate: (json['rate'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// Default exchange rates
final defaultExchangeRates = [
  ExchangeRate(
    id: 'eur-usd',
    fromCurrency: 'EUR',
    toCurrency: 'USD',
    rate: 1.08,
    updatedAt: DateTime.now(),
  ),
  ExchangeRate(
    id: 'rub-usd',
    fromCurrency: 'RUB',
    toCurrency: 'USD',
    rate: 84.0,
    updatedAt: DateTime.now(),
  ),
  ExchangeRate(
    id: 'usd-usd',
    fromCurrency: 'USD',
    toCurrency: 'USD',
    rate: 1.0,
    updatedAt: DateTime.now(),
  ),
];
