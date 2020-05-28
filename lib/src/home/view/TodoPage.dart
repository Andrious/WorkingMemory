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
///          Created  25 Aug 2018
/// place: "/todos/todo"
///

import 'package:flutter/material.dart';

import 'package:workingmemory/src/view.dart' show App, TodoAndroid, TodoiOS;

class TodoPage extends StatefulWidget {
  TodoPage({Key key, this.todo}) : super(key: key);

  final Map todo;

  @override
  State createState() => App.useMaterial ? TodoAndroid() : TodoiOS();
}