// GENERATED CODE - DO NOT MODIFY BY HAND
// Hive Adapter for Asset Model

part of 'asset_model.dart';

class AssetAdapter extends TypeAdapter<Asset> {
  @override
  final int typeId = 1;

  @override
  Asset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Asset(
      id: fields[0] as String,
      owner: fields[1] as String,
      assetType: fields[2] as String,
      institution: fields[3] as String,
      country: fields[4] as String,
      currency: fields[5] as String,
      amountInCCY: fields[6] as double,
      interestRate: fields[7] as double,
      annualIncomeCCY: fields[8] as double? ?? 0,
      monthlyIncomeCCY: fields[9] as double? ?? 0,
      amountInUSD: fields[10] as double? ?? 0,
      annualIncomeUSD: fields[11] as double? ?? 0,
      monthlyIncomeUSD: fields[12] as double? ?? 0,
      createdAt: fields[13] as DateTime,
      updatedAt: fields[14] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Asset obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.owner)
      ..writeByte(2)
      ..write(obj.assetType)
      ..writeByte(3)
      ..write(obj.institution)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.amountInCCY)
      ..writeByte(7)
      ..write(obj.interestRate)
      ..writeByte(8)
      ..write(obj.annualIncomeCCY)
      ..writeByte(9)
      ..write(obj.monthlyIncomeCCY)
      ..writeByte(10)
      ..write(obj.amountInUSD)
      ..writeByte(11)
      ..write(obj.annualIncomeUSD)
      ..writeByte(12)
      ..write(obj.monthlyIncomeUSD)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
