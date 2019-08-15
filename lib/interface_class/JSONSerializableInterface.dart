abstract class JSONSerializable {
  static final JSONSerializable example = null;
  JSONSerializable();
  factory JSONSerializable.fromJson(Map<String, dynamic> json){}
  Map<String, dynamic> toJson(){}
  List<String> propertyNames(){}
  List<String> uniqueProperties(){}
}