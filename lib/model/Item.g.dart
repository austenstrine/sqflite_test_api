// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) {
  return Item(
    name: json['name'] as String,
    inventory: json['inventory'] as int,
    upc: json['upc'] as String,
    price: (json['price'] as num).toDouble(),
    mongoID: Map<String, String>.from(json['mongoID'] as Map),
  );
}

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'name': instance.name,
      'mongoID': instance.mongoID,
      'inventory': instance.inventory,
      'price': instance.price,
      'upc': instance.upc,
    };
