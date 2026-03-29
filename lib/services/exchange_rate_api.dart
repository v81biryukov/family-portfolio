import 'dart:convert';
import 'package:http/http.dart' as http;

/// Free exchange rate API service
/// Uses exchangerate-api.com (free tier available)
class ExchangeRateApiService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  /// Fetch latest exchange rates from the API
  /// Returns rates relative to USD
  Future<Map<String, double>?> fetchLatestRates() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/USD'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        return rates.map((key, value) => 
          MapEntry(key, (value as num).toDouble())
        );
      }
      
      return null;
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return null;
    }
  }

  /// Get rate for specific currency
  Future<double?> getRateForCurrency(String currency) async {
    final rates = await fetchLatestRates();
    return rates?[currency];
  }
}
