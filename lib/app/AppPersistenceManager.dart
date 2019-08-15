import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_test_api/model/Item.dart';
import 'package:sqflite_test_api/model/SQLinked.dart';
import 'package:recase/recase.dart';
import 'dart:isolate';
import 'package:stack_trace/stack_trace.dart';
import 'package:sqflite_test_api/interface_class/JSONSerializableInterface.dart';
import 'package:sqflite_test_api/model/DatabaseLocation.dart';
import 'package:sqflite_test_api/app/AppException.dart';
import 'package:sqflite_test_api/helper/RawValue.dart';

//import 'package:flutter/foundation.dart';//annotations
///This enum determines the tables and the associated classes to generate columns with in the database.
enum DatabaseTable { Item }

///Used to determine whether the object had a property with an exact match (first), a contains match (second), or no match (omit)
enum FSO { first, second, omit }

class AppPersistenceManager {
  AppPersistenceManager._internal();

  static final AppPersistenceManager shared =
      new AppPersistenceManager._internal();
  final String uniqueRowKey = 'row_id';

  String get uniqueJSONRowKey {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    return getJSONKeyFrom(databaseKey: uniqueRowKey);
  }

  Isolate isolate;
  bool lockedFlag = false;
  bool shouldQuickSearch = false;
  Database _database;

  Future<Database> get database async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    if (_database != null) return _database;

    // if _database is null we instantiate it
    _database = await initDatabase();
    return _database;
  }

  initDatabase() async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    print('passed doc dir');
    String path = join(documentsDirectory.path, "TestDB.db");
    print('passed join');
    return await openDatabase(path, version: 1, onOpen: (db) {
      print('in onOpen');
    }, onCreate: (Database database, int version) async {
      print('in onCreate async');
      for (DatabaseTable databaseTable in DatabaseTable.values) {
        print(
            'reached inside of "for (DatabaseTable databaseTable in DatabaseTable.values)"');
        String executionString =
            "CREATE TABLE IF NOT EXISTS ${RawValue.databaseTable(databaseTable)}("
            "$uniqueRowKey INTEGER PRIMARY KEY,";

        JSONSerializable objectExample;
        switch (databaseTable) {
          case DatabaseTable.Item:
            objectExample = Item.example;
        }
        print('getting parameters');
        List<String> parameters = [];
        for (String key
            in getDatabaseKeyedMapFrom(serialObject: objectExample).keys) {
          parameters.add(key);
        }
        print('getting unique keys');
        List<String> uniqueKeys = [];
        var rawUniqueProperties = objectExample.uniqueProperties();
        for (String property in rawUniqueProperties) {
          uniqueKeys.add(getDatabaseKeyFrom(jsonKey: property));
        }
        print('iterating through parameters');
        for (String parameter in parameters) {
          if (parameter != parameters.first) {
            executionString += ',';
          }
          if (uniqueKeys.contains(parameter)) {
            uniqueKeys.remove(parameter);
            executionString += "$parameter BLOB UNIQUE";
            continue;
          }
          executionString += "$parameter BLOB";
        }
        executionString += ')';
        print('executing string on database');
        await database.execute(executionString);
      }
    });
  }

  /// Attempts to insert the object into its corresponding table.
  ///
  /// Will pass an Exception? exception, and a DatabaseLocation! location
  /// to the onComplete function.
  /// On success, exception will be null. On failure, location will be null.
  Future<DatabaseLocation> insertIntoDatabase(JSONSerializable object) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    final localDatabase = await database;
    String tableName = RawValue.databaseTable(getTableFor(object));
    int row = await localDatabase.insert(
        tableName, getDatabaseKeyedMapFrom(serialObject: object));
    return DatabaseLocation(table: tableName, row: row);
  }

  Future<Map<String, dynamic>> fetchFromDatabase(
      {DatabaseLocation location}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    final localDatabase = await database;
    List<Map<String, dynamic>> response = await localDatabase.query(
        location.table,
        where: "$uniqueRowKey = ?",
        whereArgs: [location.row]);
    if (response.isNotEmpty) {
      return getJSONKeyedMapFrom(databaseKeyedMap: response.first);
    } else {
      throw ObjectNotFoundException(
          'The response from the database was empty.');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTable(String table) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    final localDatabase = await database;
    List<Map<String, dynamic>> extractedTable =
        await localDatabase.query(table);
    List<Map<String, dynamic>> convertedTable = [];
    for (Map<String, dynamic> item in extractedTable) {
      convertedTable.add(getJSONKeyedMapFrom(databaseKeyedMap: item));
    }
    return convertedTable;
  }

  updateInDatabase({DatabaseLocation location, JSONSerializable object}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    final localDatabase = await database;
    await localDatabase.update(
        location.table, getDatabaseKeyedMapFrom(serialObject: object),
        where: "$uniqueRowKey = ?", whereArgs: [location.row]);
    return;
  }

  deleteFromDatabase({DatabaseLocation location}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    final localDatabase = await database;
    localDatabase.delete(location.table,
        where: "$uniqueRowKey = ?", whereArgs: [location.row]);
  }

  DatabaseTable getTableFor(JSONSerializable object) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    if (object is Item) {
      return DatabaseTable.Item;
    } else {
      return null;
    }
  }

  String getDatabaseKeyFrom({String jsonKey}) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    return ReCase(jsonKey).snakeCase;
  }

  String getJSONKeyFrom({String databaseKey}) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    return ReCase(databaseKey).camelCase;
  }

  Map<String, dynamic> getDatabaseKeyedMapFrom(
      {JSONSerializable serialObject}) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    Map<String, dynamic> jsonKeyedMap = serialObject.toJson();
    List<String> jsonPropertyNames = serialObject.propertyNames();
    Map<String, dynamic> databaseKeyedMap = {};
    for (String jsonPropertyName in jsonPropertyNames) {
      ReCase reCase = ReCase(jsonPropertyName);
      String databasePropertyName = reCase.snakeCase;
      databaseKeyedMap[databasePropertyName] = jsonKeyedMap[jsonPropertyName];
    }
    return databaseKeyedMap;
  }

  Map<String, dynamic> getJSONKeyedMapFrom(
      {Map<String, dynamic> databaseKeyedMap}) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    List<String> databasePropertyNames = databaseKeyedMap.keys;
    Map<String, dynamic> jsonKeyedMap = {};
    for (String databasePropertyName in databasePropertyNames) {
      ReCase reCase = ReCase(databasePropertyName);
      String jsonPropertyName = reCase.camelCase;
      jsonKeyedMap[jsonPropertyName] = databaseKeyedMap[databasePropertyName];
    }
    return jsonKeyedMap;
  }

  Future<List<SQLinked>> getSearchResults(
      {String query,
      List<String> parameters,
      JSONSerializable exampleObject}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    List<SQLinked> fetchedData;
    switch (exampleObject.runtimeType) {
      case (Item):
        fetchedData = await SQLinked.fetchAll(Item);
        break;
      default:
        throw new Exception('Unrecognized data type!');
    }
    if (fetchedData.isEmpty) {
      throw new Exception(
          'There is no cached data for type: ${exampleObject.runtimeType}');
    } else {
      switch (exampleObject.runtimeType) {
        case Item:
          List<SQLinked<Item>> items = await getItemSearchResults(
              parameters: parameters, fetchedData: fetchedData, query: query);
          print(items);
          return items;
        default:
          throw new Exception('Unrecognized data type!');
      }
    }
  }

  Future<List<SQLinked<Item>>> getItemSearchResults(
      {List<String> parameters, List<SQLinked> fetchedData, String query}) async {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    List<SQLinked<Item>> items = fetchedData as List<SQLinked<Item>>;
    Set<SQLinked<Item>> firstInsert = Set<SQLinked<Item>>();
    Set<SQLinked<Item>> secondInsert = Set<SQLinked<Item>>();
    for (String parameter in parameters) {
      print("First Insert data is: $firstInsert");
      print("Second Insert data is: $secondInsert");
      print("parameter is '$parameter'");
      if (shouldQuickSearch && firstInsert.isNotEmpty) {
        break;
      }
      ItemSearchParameter paramEnum =
          RawValue.initItemSearchParameter(parameter);
      FSO getItemFSO(FSO fso, SQLinked<Item> sqItem) {//move to class body???
        print("in comparison closure");
        switch (paramEnum) {
          case ItemSearchParameter.categories:
            {
//              for(String category in sqItem.mutableObject.categories)
//              {
//                fso = this.stringComparison (
//                    optionalString: category,
//                    query: query,
//                    fso: fso);
//                if(fso == FSO.first){
//                  break;
//                }
//              }
//              print ("outside of string comparison fso is '$fso'");
              break;
            }
          case ItemSearchParameter.upc:
            {
              fso = this.stringComparison(
                  optionalString: sqItem.mutableObject.upc,
                  query: query,
                  fso: fso);
              print("outside of string comparison fso is '$fso'");
              break;
            }
          case ItemSearchParameter.name:
            {
              fso = this.stringComparison(
                  optionalString: sqItem.mutableObject.name,
                  query: query,
                  fso: fso);
              print("outside of string comparison fso is '$fso'");
              break;
            }
        }
        return fso;
      }
      if (paramEnum != null) {
        insertEachObjectInSetAfterComparingToQuery(
            objectArray: items, //passed by reference!
            firstSet: firstInsert, //passed by reference!
            secondSet: secondInsert, //passed by reference!
            comparisonClosure: getItemFSO);
      }
      else {
        throw new Exception('Unrecognized parameter $parameter');
      }
    }
    Function itemSortFunc = (given, next) {
      int comparison =
          given.mutableObject.category.compareTo(next.mutableObject.category);
      if (comparison == 0) {
        int secondComparison =
            given.mutableObject.name.compareTo(next.mutableObject.name);
        if (secondComparison == 0) {
          int lastComparison =
              given.mutableObject.upc.compareTo(next.mutableObject.upc);
          return lastComparison;
        }
        return secondComparison;
      }
      return comparison;
    };
    List<SQLinked<Item>> firstSorted = List.from(firstInsert);
    firstSorted.sort(itemSortFunc);
    List<SQLinked<Item>> secondSorted = List.from(secondInsert);
    secondSorted.sort(itemSortFunc);
    List<SQLinked<Item>> results = firstSorted;
    results.addAll(secondSorted);
    return results;
  }

  insertEachObjectInSetAfterComparingToQuery<T>(
      {List<T> objectArray,
      Set<T> firstSet,
      Set<T> secondSet,
      FSO Function(FSO, T) comparisonClosure}) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    List<int> indexesToRemove = [];
    int index = -1;
    for (T object in objectArray) {
      index += 1;
      FSO fso = FSO.omit;
      fso = comparisonClosure(fso, object);
      print("item $index");
      print("fso is $fso");
      switch (fso) {
        case FSO.first:
          if (secondSet.contains(object)) {
            secondSet.remove(object);
          }
          firstSet.add(object);
          indexesToRemove.add(index);
          print("First set data is: $firstSet");
          break;
        case FSO.second:
          if (!firstSet.contains(object)) {
            secondSet.add(object);
          }
          print("Second set data is: $secondSet");
          break;
        case FSO.omit:
          continue;
      }

      if (this.shouldQuickSearch && firstSet.isNotEmpty) {
        break;
      }
    }
    for (int index in indexesToRemove.reversed) {
      //must be reversed or will run into index out of range error

      objectArray.removeAt(index);
    }
  }
//
//  private func
//
//  stringToDateRange
//
//  (
//
//  string
//
//      :
//
//  String
//
//  )
//
//  -
//
//  >
//
//  ClosedRange<Date>
//
//  ?
//  {
//  printTrace(function: #function, file: #file, classForCoder: classForCoder)
//
//
//  let splitStrings = string.split(separator: "-")
//  guard splitStrings.count == 2
//  else
//  {
//  return nil
//  }
//  let firstString = String(splitStrings[0])
//  let secondString = String(splitStrings[1])
//  guard let firstDate = appData.shipdateFormatter.date(from: firstString),
//  let secondDate = appData.shipdateFormatter.date(from: secondString),
//  firstDate != secondDate
//  else
//  {
//  return nil
//  }
//  guard firstDate < secondDate
//  else
//  {
//  return secondDate...firstDate
//  }
//  return firstDate...secondDate
//
//  }

  FSO stringComparison({String optionalString, String query, FSO fso}) {
    print("In string comparison, query is '$query'");
    String string = (optionalString ?? "").toLowerCase();
    print("In string comparison, string is '$string'");

    if (string.isNotEmpty) {
      print("string is not empty");
      if (string == query) {
        print("setting to fso.first");
        fso = FSO.first;
      }
      else if (string.contains(query)) {
        print("setting to fso.second");
        fso = FSO.second;
      }
      else {
        print ("setting to fso.omit");
      }
    }
    print("fso after comparison is $fso");
    return fso;
  }

//  private func
//
//  dateComparison
//
//  (
//
//  optionalDate
//
//      :
//
//  Date
//
//  ?
//
//  ,
//
//  query
//
//      :
//
//  String
//
//  ,
//
//  fso
//
//      :
//
//  inout FSO, as
//
//  shipdateOrAPI
//
//      :
//
//  DateFormatterType
//
//  =
//
//      .
//
//  shipdate
//
//  )
//  {
//  let formatter:DateFormatter
//  switch shipdateOrAPI
//  {
//  case .shipdate:
//  formatter = appData.shipdateFormatter
//  case .api:
//  formatter = appData.apiDateFormatter
//  }
//  if let date = optionalDate
//  {
//  if let queryDate:Date = formatter.date(from: query)
//  {
//  if date == queryDate
//  {
//  fso = FSO.first
//  return
//  }
//  }
//  if let queryDateRange:ClosedRange<Date> = self.stringToDateRange(string: query)
//  {
//  if queryDateRange.contains(date)
//  {
//  fso = FSO.first
//  }
//
//  }
//  }
//  }
//
//  private func
//
//  intComparison
//
//  (
//
//  optionalInt
//
//      :
//
//  Int
//
//  ?
//
//  ,
//
//  query
//
//      :
//
//  String
//
//  ,
//
//  fso
//
//      :
//
//  inout FSO
//
//  )
//  {
//  if let int = optionalInt, let queryInt = Int(query)
//  {
//  if int == queryInt
//  {
//  fso = FSO.first
//  }
//  else if String(int).contains(query)
//  {
//  fso = FSO.second
//  }
//  }
//  }
//
//  private func
//
//  floatComparison
//
//  (
//
//  optionalFloat
//
//      :
//
//  Float
//
//  ?
//
//  ,
//
//  query
//
//      :
//
//  String
//
//  ,
//
//  fso
//
//      :
//
//  inout FSO
//
//  )
//  {
//  if let float = optionalFloat, let queryFloat = Float(query)
//  {
//  if float == queryFloat
//  {
//  fso = FSO.first
//  }
//  else if String(float).contains(query)
//  {
//  fso = FSO.second
//  }
//  }
//  }
//
//  ///needs
//  private func
//
//  stringIntFloatComparison
//
//  (
//
//  optionalData
//
//      :
//
//  Any
//
//  ?
//
//  ,
//
//  query
//
//      :
//
//  String
//
//  ,
//
//  fso
//
//      :
//
//  inout FSO
//
//  )
//  {
//  func intCode(int:Int)
//  {
//  if let queryInt = Int(query)
//  {
//  if int == queryInt
//  {
//  fso = FSO.first
//  }
//  else if String(int).contains(query)
//  {
//  fso = FSO.second
//  }
//  }
//  }
//  if let data = optionalData
//  {
//  if let string = data as? String
//  {
//  if string.lowercased() == query.lowercased()
//  {
//  fso = FSO.first
//  }
//  else if string.lowercased().localizedCaseInsensitiveContains(query.lowercased())
//  {
//  fso = FSO.second
//  }
//  }
//  else if let int = data as? Int
//  {
//  intCode(int: int)
//  }
//  else if let int16 = data as? Int16
//  {
//  intCode(int: Int(int16))
//  }
//  else if let int32 = data as? Int32
//  {
//  intCode(int: Int(int32))
//  }
//  else if let float = data as? Float,
//  let queryFloat = Float(query)
//  {
//  if float == queryFloat
//  {
//  fso = FSO.first
//  }
//  else if String(float).contains(query)
//  {
//  fso = FSO.second
//  }
//  }
//  else
//  {
//  fatalError("Incompatible data type!")
//  }
//  }// if let data = optionalData
//  } // private func stringIntFloatComparison<T:Any>(optionalData:T?, query:String, fso:inout FSO)

}
