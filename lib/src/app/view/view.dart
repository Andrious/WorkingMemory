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
///          Created  23 Jun 2018
///

import 'package:flutter/material.dart';

import 'package:mvc_application/view.dart' show AppView;

import 'package:workingmemory/src/controller.dart';

import 'package:workingmemory/src/view.dart';

//import 'package:workingmemory/src/view/LoginInfo.dart' show LoginInfo;

class View extends AppView {
  View()
      : super(
          con: _app,
          title: 'Working Memory',
          home: TodosPage(),
          debugShowCheckedModeBanner: false,
        ) {
    _this = this;
    idKey = _app.keyId;
  }
  static View _this;

  /// Allow for easy access to 'the View' throughout the application.
  static View get view => _this;

  /// Instantiate here so to get the 'keyId.'
  static final WorkingMemoryApp _app = WorkingMemoryApp();
  String idKey;

  @override
  ThemeData onTheme() => ThemeData(
        primarySwatch: App.colorTheme,
      );
}
