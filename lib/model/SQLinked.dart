import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';

import 'package:sqflite_test_api/helper/RawValue.dart';
import 'package:sqflite_test_api/app/AppPersistenceManager.dart';
import 'package:sqflite_test_api/interface_class/JSONSerializableInterface.dart';

import 'Item.dart';
import 'DatabaseLocation.dart';

///a wrapper that manages database persistence.
class SQLinked<T extends JSONSerializable> {
  //table & row (row is the unique ID generated when the Item is inserted)
  DatabaseLocation _databaseLocation;
  //mutable Item
  T mutableObject;

  //functions

  Future<DatabaseLocation> _sqInsert(JSONSerializable object) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    return await AppPersistenceManager.shared.insertIntoDatabase(object);
  }

  sqPull() async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    mutableObject = null;
    Map<String, dynamic> objectJSON = await AppPersistenceManager.shared
        .fetchFromDatabase(location: _databaseLocation);
    switch (_databaseLocation.table) {
      case 'Item':
        mutableObject = Item.fromJson(objectJSON) as T;
        break;
      default:
        print(T.runtimeType);
        throw new Exception('Unknown class type!');
    }
  }

  sqPush() async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    if (mutableObject == null) {
      print('removing object from table: ${_databaseLocation.table}');
      return AppPersistenceManager.shared
          .deleteFromDatabase(location: _databaseLocation);
    } else {
      print('updating object in table: ${_databaseLocation.table}');
      return AppPersistenceManager.shared
          .updateInDatabase(location: _databaseLocation, object: mutableObject);
    }
  }

  //constructors
  ///Must call newDBLink() or existingDBLink after to finish instantiation
  SQLinked();

  Future<SQLinked<T>> newDBLink({T object}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    mutableObject = object;
    _databaseLocation = await _sqInsert(object);
    return this;
  }

  Future<SQLinked<T>> existingDBLink({DatabaseLocation location}) async {
    _databaseLocation = location;
    await sqPull();
    return this;
  }

  SQLinked<NewType> cast<NewType extends JSONSerializable>() {
    SQLinked<NewType> linked = SQLinked<NewType>();
    linked._databaseLocation = this._databaseLocation;
    linked.mutableObject = this.mutableObject as NewType;
    return linked;
  }

  static Future<List<SQLinked>> fetchAll(Type type) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    print('getting table name');
    String tableName;
    switch (type) {
      case Item:
        tableName = RawValue.databaseTable(DatabaseTable.Item);
        break;
      default:
        throw new Exception('Unknowm class type!');
    }
    print('getting json table');
    List<Map<String, dynamic>> jsonTable =
        await AppPersistenceManager.shared.fetchTable(tableName);
    print('getting allLinkedItems');
    List<SQLinked> allLinkedObjects = [];
    if (jsonTable.isNotEmpty) {
      for (Map<String, dynamic> jsonMappedObject in jsonTable) {
        print("jsonMap: $jsonMappedObject");
        print('getting row');
        int row =
            jsonMappedObject[AppPersistenceManager.shared.uniqueJSONRowKey]
                as int;
        print('adding to linked Items');
        SQLinked dynamicSQObject;
        switch (type) {
          case (Item):
            dynamicSQObject = SQLinked<Item>();
            break;
          default:
            throw new Exception('Unknowm class type!');
        }
        SQLinked sqLinkedObject = await dynamicSQObject.existingDBLink(
            location: DatabaseLocation(table: tableName, row: row));
        if (sqLinkedObject != null) {
          allLinkedObjects.add(sqLinkedObject);
        }
      }
    }
    print('returning linked Items');

    switch (type) {
      case Item:
        List<SQLinked<Item>> items = [];
        for(SQLinked<JSONSerializable> sqLinkedSerial in allLinkedObjects) {
          items.add(sqLinkedSerial.cast<Item>());
        }
        print('cast succeeded');
        return items;
      default:
        throw new Exception('Unknowm class type!');
    }
  }
}
