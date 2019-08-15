import 'package:sqflite_test_api/app/AppPersistenceManager.dart';
import 'package:sqflite_test_api/model/Item.dart';

class RawValue {
  static String databaseTable(DatabaseTable databaseTable) {
    return databaseTable.toString().split('.').last;
  }

  static String itemSearchParameter(ItemSearchParameter parameter) {
    return parameter.toString().split('.').last;
  }

  static ItemSearchParameter initItemSearchParameter(String rawValue) {
    for(ItemSearchParameter parameter in ItemSearchParameter.values) {
      if(itemSearchParameter(parameter) == rawValue) {
        return parameter;
      }
    }
    return null;
  }
}