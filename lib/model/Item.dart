import 'package:json_annotation/json_annotation.dart';
import 'package:sqflite_test_api/interface_class/JSONSerializableInterface.dart';
part 'Item.g.dart'; //flutter pub run build_runner build

@JsonSerializable(nullable: false)
class Item implements JSONSerializable {
  //comment this out before running build_runner
  static final Item example = Item(
      inventory: 0,
      name: "Example Name",
      //categories: ["Example Category"],
      price: 0.50,
      mongoID: {"\$id":"8447aa9608663R9"},
      upc: "844796086639");

  final String name;
  final Map<String, String> mongoID;
  //final List<String> categories;
  final int inventory;
  final double price;
  final String upc;
  final DateTime dateCreated = DateTime.now();
  Item({this.name, //this.categories,
         this.inventory, this.upc, this.price, this.mongoID
  });
  @override
  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
  @override
  List<String> propertyNames() {
    List<String> list = [];
    for(String str in toJson().keys) {
      list.add(str);
    }
    print('returning property names');
    return list;
  }
  @override
  List<String> uniqueProperties() {
    print('returning unique properties');
    return ['upc'];
  }
}

enum ItemSearchParameter{name,categories,upc}

