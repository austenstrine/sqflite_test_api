import 'package:flutter/material.dart';
import 'package:sqflite_test_api/helper/RawValue.dart';
import 'package:sqflite_test_api/model/Item.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sqflite_test_api/model/SQLinked.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/cupertino.dart';

import 'app/AppPersistenceManager.dart';
//import 'package:sqflite_test_api/app/AppPersistenceManager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'SQFLite Demo',
      theme: CupertinoThemeData(
          primaryColor: Colors.deepPurple,
          barBackgroundColor: Colors.deepPurple.shade600,
          primaryContrastingColor: Colors.deepPurple.shade400,
          scaffoldBackgroundColor: Colors.white,
          textTheme: CupertinoTextThemeData(
              primaryColor: Colors.deepPurpleAccent,
              textStyle: TextStyle(color: Colors.deepPurple),
              navTitleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              navLargeTitleTextStyle:
                  TextStyle(color: Colors.white, fontSize: 24),
              actionTextStyle: TextStyle(color: Colors.white),
              dateTimePickerTextStyle: TextStyle(color: Colors.white),
              navActionTextStyle: TextStyle(color: Colors.white),
              pickerTextStyle: TextStyle(color: Colors.white),
              tabLabelTextStyle: TextStyle(color: Colors.white))),
      home: MyHomePage(title: 'Add or Remove Items'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //computed read-only property that displays search vs all depending on searchBarVisible
  List<SQLinked<Item>> get _items {
    return _searchBarVisible ? _searchResults : _allItems;
  }

  List<SQLinked<Item>> _allItems = [];
  List<SQLinked<Item>> _searchResults = [];
  bool reloadedItems = false;
  bool _isLoadingItems = true;
  bool _searchBarVisible = false;
  TextEditingController _filter = TextEditingController();

  /*
  void _getAllItems() {
    SQLinkedItem.fetchAll().then((items) {
      setState(() {
        _items = items;
      });
    });
  }
  AlertDialog _getDialog(BuildContext context) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    return AlertDialog(
      shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8))),
      content: SingleChildScrollView(child: Text(_getMessageData())),
      actions: <Widget>[
        FlatButton(
          child: Text('Ok'),
          onPressed: () {
            setState(() {
              _addItem();
              Navigator.pop(context);
            });
          },
        )
      ],
    );
  }

  String _getMessageData() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);
    return "An item will be created";
  }
  */
  _searchFor(String query) {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    AppPersistenceManager.shared.getSearchResults(
        query: query,
        exampleObject: Item.example,
        parameters: [
          RawValue.itemSearchParameter(ItemSearchParameter.name),
          RawValue.itemSearchParameter(ItemSearchParameter.categories)
        ]).then((results) {
      _searchResults = results;
      if (_searchBarVisible) {
        setState(() {});
      }
    });
  }

  _toggleSearchBar() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    setState(() {
      _searchBarVisible = !_searchBarVisible;
    });
  }

  _removeItemButtonSelected() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    if (!_searchBarVisible) {
      _removeItem();
    }
  }

  _removeItem() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    if (_allItems.isNotEmpty) {
      SQLinked<Item> lastItem = _allItems.last;
      lastItem.mutableObject = null;
      lastItem.sqPush().then((item) {
        _allItems.removeLast();
        lastItem = null;

        if (!_searchBarVisible) {
          setState(() {});
        }
      });
    }
  }

  _addItemButtonSelected() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    if (!_searchBarVisible) {
      _addItem();
    }
  }

  _addItem() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    int lastInventory = 0;
    if (_allItems.isNotEmpty) {
      SQLinked<Item> lastItem = _allItems.last;
      lastInventory = lastItem.mutableObject.inventory;
    }
    Item newItem = Item(
        //categories: ["Cat" + "${lastInventory + 1}"],
        name: "Name,,,," + "${lastInventory + 1}",
        inventory: lastInventory + 1,
        mongoID: {"\$id":"${lastInventory + 1}"},
        price: Item.example.price + (lastInventory + 1).toDouble(),
        upc: Item.example.upc + "$lastInventory");
    SQLinked<Item>().newDBLink(object: newItem).then((sqLink) {
      _allItems.add(sqLink);
      if (!_searchBarVisible) {
        setState(() {});
      }
    });
  }

  List<Widget> _getListViewChildren() {
    print(new Trace.from(StackTrace.current).terse.frames[0]);

    List<Widget> _widgets = [];
    if (_items.isNotEmpty) {
      print(_items);
      _items.forEach((sqLink) {
        _widgets.add(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(sqLink.mutableObject.name)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text("\$${sqLink.mutableObject.price}")),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text("${sqLink.mutableObject.inventory} available"))
            ]));
      });
    } else {
      if (_isLoadingItems == true) {
        _widgets.add(Padding(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: 200.0,
              height: 100.0,
              child: Shimmer.fromColors(
                baseColor: Colors.deepPurple,
                highlightColor: Colors.black,
                child: Text(
                  'Please Wait...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )));
      }
    }
    return _widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (!reloadedItems) {
      _isLoadingItems = true;
      reloadedItems = true;
      SQLinked.fetchAll(Item).then((items) {
        setState(() {
          _allItems = items as List<SQLinked<Item>>;
          _isLoadingItems = false;
        });
      });
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          middle: _searchBarVisible
              ? CupertinoTextField(
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.shade400,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  cursorColor: Colors.white70,
                  controller: _filter,
                  prefix: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.search, color: Colors.white70)),
                  placeholder: 'Search...',
                  placeholderStyle: TextStyle(color: Colors.white70),
                  clearButtonMode: OverlayVisibilityMode.always,
                  onSubmitted: _searchFor,
                )
              : Text(widget.title),
          trailing: Padding(
              padding: EdgeInsets.only(left: 8),
              child: CupertinoButton(
                child: Icon(
                  _searchBarVisible
                      ? CupertinoIcons.right_chevron
                      : CupertinoIcons.search,
                  color: Colors.white,
                ),
                color: Colors.deepPurple.shade400,
                padding: EdgeInsets.all(4),
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                pressedOpacity: 0.9,
                minSize: 0,
                onPressed: _toggleSearchBar,
              ))),
      child: Center(
        child: Stack(
          alignment: AlignmentDirectional(0, 1),
          fit: StackFit.passthrough,
          overflow: Overflow.clip,
          children: <Widget>[
            ListView(
              scrollDirection: Axis.vertical,
              children: _getListViewChildren(),
            ),
            Stack(
              alignment: Alignment(1, 0),
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.all(8),
                    child: SpeedDial(
                      marginRight: 20,
                      marginBottom: 20,
                      animatedIcon: AnimatedIcons.menu_close,
                      animatedIconTheme: IconThemeData(size: 26.0),
                      closeManually: true,
                      curve: Curves.bounceIn,
                      overlayColor: Colors.black,
                      overlayOpacity: 0.5,
                      onOpen: () => print('OPENING DIAL'),
                      onClose: () => print('DIAL CLOSED'),
                      tooltip: 'Speed Dial',
                      heroTag: 'speed-dial-hero-tag',
                      backgroundColor: Colors.deepPurple.shade400,
                      foregroundColor: Colors.white,
                      elevation: 8.0,
                      shape: CircleBorder(),
                      //RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                      children: [
                        SpeedDialChild(
                          child: Icon(Icons.remove),
                          backgroundColor: Colors.deepPurple.shade300,
                          //shape doesn't work//shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                          //labelStyle: TextStyle(fontSize: 18.0),
                          onTap: _removeItemButtonSelected,
                        ),
                        SpeedDialChild(
                            child: Icon(Icons.add),
                            backgroundColor: Colors.deepPurple.shade200,
                            //shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
                            //labelStyle: TextStyle(fontSize: 18.0),
                            onTap: _addItemButtonSelected),
                      ],
                    ))
              ],
            )
          ],
        ),
      ),
    );
  }
}
