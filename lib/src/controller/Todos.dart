///
/// Copyright (C) 2018 Andrious Solutions
///
/// This program is free software; you can redistribute it and/or
/// modify it under the terms of the GNU General Public License
/// as published by the Free Software Foundation; either version 3
/// of the License, or any later version.
///
/// You may obtain a copy of the License at
///
///  http://www.apache.org/licenses/LICENSE-2.0
///
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  04 Nov 2018

import 'package:flutter/material.dart'
    show
        Alignment,
        AppLifecycleState,
        Axis,
        Border,
        BorderSide,
        BoxDecoration,
        BuildContext,
        Center,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        DismissDirection,
        Dismissible,
        EdgeInsets,
        FormState,
        GlobalKey,
        Icon,
        IconData,
        Icons,
        InputDecoration,
        ListTile,
        ListView,
        ObjectKey,
        ScaffoldState,
        SnackBar,
        SnackBarAction,
        Navigator,
        Text,
        TextEditingController,
        TextFormField,
        ThemeData,
        Widget;

import 'package:intl/intl.dart' show DateFormat;

import 'package:workingmemory/src/view/DateTimeItem.dart';

import 'package:workingmemory/src/view/IconItems.dart';

import 'package:mvc_application/app.dart';

import 'package:mvc_application/controller.dart';

import 'package:workingmemory/src/model/Model.dart' as m;

final ThemeData theme = App.theme;

class Controller extends ControllerMVC {
  factory Controller() {
    if (_this == null) _this = Controller._();
    return _this;
  }
  static Controller _this;

  Controller._() : super();

  /// Allow for easy access to 'the Controller' throughout the application.
  static Controller get con => _this ?? Controller();

  static final m.Model model = m.Model();

  @override
  void initState() {
    super.initState();
    model.initState();
  }

  @override
  void dispose() {
    model.dispose();
    add.dispose();
    edit.dispose();
    list.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      model.sync();
    }

    /// Passing these possible values:
    /// AppLifecycleState.paused (may enter the suspending state at any time)
    /// AppLifecycleState.resumed
    /// AppLifecycleState.inactive (may be paused at any time)
    /// AppLifecycleState.suspending (Android only)
  }

  static ToDoAdd get add => _addToDo;
  static ToDoAdd _addToDo = ToDoAdd();

  static ToDoEdit get edit => _editToDo;
  static ToDoEdit _editToDo = ToDoEdit();

  static ToDoList get list => _listToDo;
  static ToDoList _listToDo = ToDoList();

  Future<bool> save(Map data) => model.save(data);

  Future<bool> saveRec(Map diffRec, Map oldRec) {
    Map newRec = Map();

    if (oldRec == null) {
      newRec.addAll(diffRec);
    } else {
      newRec.addAll(oldRec);

      newRec.addEntries(diffRec.entries);
    }
    return save(newRec);
  }

// No need now. In ToDoEdit class.
//  Future<bool> delete(Map data) {
//    return model.delete(data);
//  }

//  Future<bool> undelete(Map data) {
//    return model.undelete(data);
//  }

  static get defaultIcon => model.defaultIcon;
}

class ToDoAdd extends ToDoEdit {}

class ToDoEdit extends ToDoList {
  bool hasName;
  TextEditingController changer;
  bool hasChanged = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final formKey = GlobalKey<FormState>();

  void init([Map todo]) {
    this.todo = todo;

    hasName = this.todo?.isNotEmpty ?? false;

    if (hasName) {
      item = todo['Item'];
      dateTime = DateTime.tryParse(todo['DateTime']);
      icon = todo['Icon'];
    } else {
      item = ' ';
      icon = Controller.defaultIcon;
    }

    changer = TextEditingController(text: item);
    changer.addListener(() {
      hasChanged = true;
    });
    dateTime = dateTime ?? DateTime.now();
  }

  Widget get title => Text(hasName ? item : 'Event Name TBD');

  Widget get child => ListView(
      padding: const EdgeInsets.all(16.0), children: Controller.edit.children);

  get children => <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          alignment: Alignment.bottomLeft,
          child: TextFormField(
              controller: changer,
              decoration: const InputDecoration(
                filled: true,
                labelText: 'Event name',
              ),
              style: theme.textTheme.headline,
              validator: (v) {
                if (v.isEmpty) return 'Cannot be empty.';
              },
              onSaved: (value) {
                item = value;
              }),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Center(
              child: Icon(
                  IconData(int.tryParse(icon), fontFamily: 'MaterialIcons'))),
          Text('From', style: theme.textTheme.caption),
          DateTimeItem(
            dateTime: dateTime,
            onChanged: (DateTime value) {
              setState(() {
                dateTime = value;
              });
              saveNeeded = true;
            },
          )
        ]),
        Container(
            height: 300.0,
            child: IconItems(
                icon: icon,
                onTap: (icon) {
                  setState(() {
                    this.icon = icon;
                  });
                })),
      ];

  Future<void> onPressed() async {
    bool valid = Controller.edit.formKey.currentState.validate();
    if (valid) {
      Controller.edit.formKey.currentState.save();
      await Controller.edit
          .save({'Item': item, 'DateTime': dateTime, 'Icon': icon}, this.todo);
    }
  }

  Future<bool> save(Map diffRec, Map oldRec) async {
    bool save = await Controller().saveRec(diffRec, oldRec);
    query();
    return save;
  }

  Future<bool> delete(Map data) => model.delete(data).then((delete) {
        refresh();
        return delete;
      });

  Future<bool> undelete(Map data) => model.undelete(data);
}

typedef MapCallback = void Function(Map data);

class ToDoList extends ToDoFields {
  final ThemeData _theme = App.theme;

  final _dateFormat = DateFormat('EEEE, MMM dd  h:mm a');

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final m.Model model = m.Model();

  Future<List<Map<String, dynamic>>> get future => _future;
  Future<List<Map<String, dynamic>>> _future;

  void query() => _future = list();

  Future<List<Map<String, dynamic>>> list() => model.list();

  Widget items(List content, MapCallback onTap) {
    List _content = content;
    return ListView.builder(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.all(6.0),
      itemCount: _content.length,
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          key: ObjectKey(_content[index]['rowid']),
          direction: DismissDirection.endToStart,
          onDismissed: (DismissDirection direction) {
            Controller.edit.delete(_content[index]);
            final String action = (direction == DismissDirection.endToStart)
                ? 'deleted'
                : 'archived';
            Controller.list.scaffoldKey.currentState?.showSnackBar(SnackBar(
                content: Text('You $action an item.'),
                action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      Controller.edit
                          .undelete(_content[index])
                          .then((undelete) {
                        if (undelete) refresh();
                      });
                    })));
          },
          background: Container(
              color: Colors.red,
              child: const ListTile(
                  trailing: const Icon(Icons.delete,
                      color: Colors.white, size: 36.0))),
          child: Container(
            decoration: BoxDecoration(
                color: _theme.canvasColor,
                border: Border(bottom: BorderSide(color: _theme.dividerColor))),
            child: ListTile(
              leading: Icon(IconData(int.tryParse(_content[index]['Icon']),
                  fontFamily: 'MaterialIcons')),
              title: Text(_content[index]['Item']),
              subtitle: Text(_dateFormat
                  .format(DateTime.tryParse(_content[index]['DateTime']))),
              onTap: () => onTap(_content[index]),
            ),
          ),
        );
      },
    );
  }
}

class ToDoFields extends StateObserver {
  Map todo;
  String item;
  String icon;
  DateTime dateTime;
  bool saveNeeded;
  bool hasChanged;
}