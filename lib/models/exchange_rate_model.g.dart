// GENERATED CODE - DO NOT MODIFY BY HAND
// Hive Adapter for ExchangeRate Model

part of 'exchange_rate_model.dart';

class ExchangeRateAdapter extends TypeAdapter<ExchangeRate> {
  @override
  final int typeId = 2;

  @override
  ExchangeRate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRate(
      id: fields[0] as String,
      fromCurrency: fields[1] as String,
      toCurrency: fields[2] as String? ?? 'USD',
      rate: fields[3] as double,
      updatedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRate obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.fromCurrency)
      ..writeByte(2)
      ..write(obj.toCurrency)
      ..writeByte(3)
      ..write(obj.rate)
      ..writeByte(4)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
