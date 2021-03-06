///
/// Copyright (C) 2018 Andrious Solutions
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  01 Mar 2020

/// place: "/todos"

import 'package:flutter/material.dart'
    show
        AppBar,
        Border,
        BorderSide,
        BoxDecoration,
        BuildContext,
        Colors,
        Container,
        DismissDirection,
        Dismissible,
        EdgeInsets,
        FloatingActionButton,
        Icon,
        IconData,
        Icons,
        ListTile,
        ListView,
        MaterialPageRoute,
        Navigator,
        ObjectKey,
        Route,
        RouteSettings,
        SafeArea,
        Scaffold,
        SnackBar,
        SnackBarAction,
        Text,
        Widget;

import 'package:workingmemory/src/view.dart';

import 'package:workingmemory/src/controller.dart' show App, Controller;

/// MVC design pattern is the 'View' -- the build() in this State object.
class TodosAndroid extends StateMVC<TodosPage> {
  TodosAndroid() : super(Controller()) {
    _con = controller;
  }
  Controller _con;
  WorkMenu _menu;

  @override
  Widget build(BuildContext context) {
    // Rebuilt the menu if state changes.
    _menu = WorkMenu();
    return Scaffold(
      drawer: const SettingsDrawer(),
      appBar: AppBar(
        title: I10n.t('My ToDos'),
        actions: <Widget>[
          _menu.show(this),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: editToDo,
        child: const Icon(
          Icons.add,
        ),
      ),
      body: SafeArea(
        child: _con.data.items.isEmpty
            ? Container()
            : ListView.builder(
                padding: const EdgeInsets.all(6),
                itemCount: _con.data.items.length,
                itemBuilder: (BuildContext context, int index) {
                  return Dismissible(
                    key: ObjectKey(_con.data.items[index]['rowid']),
                    onDismissed: (DismissDirection direction) {
                      _con.data.delete(_con.data.items[index]);
                      Scaffold.of(context).showSnackBar(SnackBar(
                          content: I10n.t('You deleted an item.'),
                          action: SnackBarAction(
                              label: I10n.s('UNDO'),
                              onPressed: () {
                                _con.data.undo(_con.data.items[index]);
                              })));
                    },
                    background: Container(
                        color: Colors.red,
                        child: const ListTile(
                            leading: Icon(Icons.delete,
                                color: Colors.white, size: 36),
                            trailing: Icon(Icons.delete,
                                color: Colors.white, size: 36))),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: App.themeData.dividerColor))),
                      child: ListTile(
                        leading: Icon(IconData(
                            int.tryParse(_con.data.items[index]['Icon']),
                            fontFamily: 'MaterialIcons')),
                        title: Text(_con.data.items[index]['Item']),
                        subtitle: Text(_con.data.dateFormat.format(
                            DateTime.tryParse(
                                _con.data.items[index]['DateTime']))),
                        onTap: () => editToDo(_con.data.items[index]),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> editToDo([Map<String, dynamic> todo]) async {
    final Route<Map<String, dynamic>> route = MaterialPageRoute(
      settings: const RouteSettings(name: '/todos/todo'),
      builder: (BuildContext context) => TodoPage(todo: todo),
      fullscreenDialog: true,
    );
    await Navigator.of(context).push(route);
    refresh();
  }

  // A custom error routine if you want.
  @override
  void onError(FlutterErrorDetails details){
    super.onError(details);
  }
}
