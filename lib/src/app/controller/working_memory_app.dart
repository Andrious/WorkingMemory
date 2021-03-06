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
///          Created  23 Jun 2018
///

import 'dart:async' show Future;

import 'package:flutter/material.dart'
    show
        AppLifecycleState,
        BuildContext,
        ErrorWidgetBuilder,
        Navigator,
        Widget,
        WidgetsFlutterBinding;

import 'package:flutter/foundation.dart' show FlutterErrorDetails, FlutterExceptionHandler;

import 'package:mvc_application/controller.dart' as c show runApp;

import 'package:workingmemory/src/model.dart'
    show CloudDB, FireBaseDB, RemoteConfig;

import 'package:workingmemory/src/view.dart'
    show I10n, ReportErrorHandler, showBox;

import 'package:workingmemory/src/controller.dart'
    show AppController, Controller;

import 'package:package_info/package_info.dart' show PackageInfo;

import 'package:auth/auth.dart' show Auth;

import 'package:firebase_core/firebase_core.dart' show Firebase;

import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    show FirebaseCrashlytics;

// ignore: avoid_void_async
void runApp(
  Widget app, {
  FlutterExceptionHandler handler,
  ErrorWidgetBuilder builder,
  ReportErrorHandler errorReport,
}) async {
  // Allow for FirebaseCrashlytics.instance
  WidgetsFlutterBinding.ensureInitialized();
  // Allow for FirebaseCrashlytics.instance
  await Firebase.initializeApp();

  // Supply Firebase Crashlytics
  final FirebaseCrashlytics crash = FirebaseCrashlytics.instance;

  handler ??= crash.recordFlutterError;

  errorReport ??= crash.recordError;

  // If true, then crash reporting data is sent to Firebase.
  await crash.setCrashlyticsCollectionEnabled(false);

  c.runApp(app, handler: handler, builder: builder, errorReport: errorReport);
}

/// The Controller for the Application as a whole.
class WorkingController extends AppController {
  factory WorkingController() => _this ??= WorkingController._();
  WorkingController._();
  static WorkingController _this;

  @override
  Future<bool> initAsync() async {
    await super.initAsync();
    // Firebase remote configuration.
    _remoteConfig = RemoteConfig();
    await _remoteConfig.initAsync();
    // Provide the sign in and the loading database info.
    _auth = Auth(listener: _logInUser);
    await signIn();
    // Removed from constructor to prevent a stack overflow.
    _con = Controller();
    await _con.initAsync();
    return true;
  }

  Controller _con;
  bool _loggedIn;
  Auth _auth;

  RemoteConfig get config => _remoteConfig;
  RemoteConfig _remoteConfig;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    FireBaseDB.didChangeAppLifecycleState(state);
    CloudDB.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _con.dispose();
    _auth?.dispose();
    _remoteConfig.dispose();
    I10n.dispose();
    super.dispose();
  }

  bool get loggedIn => _loggedIn;

  // logout and refresh
  void logOut() {
    signOut();
    rebuild();
  }

  void _logInUser(dynamic user) {
    //
    if (user != null) {
      userStamp();
    }
    FirebaseCrashlytics.instance.setUserIdentifier(_auth.displayName);
  }

  // 'disconnect' from Firebase
  Future<void> signOut() => _auth.signOut().then(_logInUser);

  /// Sign in the user to Firebase
  Future<bool> signIn() async {
    _loggedIn = await signInSilently();
    if (!_loggedIn) {
      _loggedIn = await signInAnonymously();
    }
    if (_auth.isAnonymous) {
      FireBaseDB().removeAnonymous();
      _auth.listener = _con?.recordDump;
    }
    return _loggedIn;
  }

  Future<bool> signInAnonymously() => _auth.signInAnonymously();

  Future<bool> signInSilently() => _auth.signInSilently();

  Future<bool> signInWithFacebook() async {
    FireBaseDB().removeAnonymous();
    await _auth.delete();
    await signOut();
    final signIn = _auth.signInWithFacebook();
    return signIn;
  }
  //    List<String> items = App.packageName.split(".");

  Future<bool> signInWithTwitter() async {
    //
    final PackageInfo info = await PackageInfo.fromPlatform();

    final List<String> items = info.packageName.split('.');

    final String one = await _remoteConfig.getStringed(items[0]);
    if (one.isEmpty) {
      return false;
    }
    final String two = await _remoteConfig.getStringed(items[1]);
    if (two.isEmpty) {
      return false;
    }
    FireBaseDB().removeAnonymous();
    await _auth.delete();
    await signOut();

    final bool signIn = await _auth
        .signInWithTwitter(
          key: one,
          secret: two,
        )
        .catchError(getError);

    if (!signIn) {
      final Exception ex = _auth.getError();
      await showBox(text: ex.toString(), context: _con?.state?.context);
    }
    return signIn;
  }

  Future<bool> signInEmailPassword(BuildContext context) async {
    //
    const String email = '';

    const String password = '';

    FireBaseDB().removeAnonymous();
    await _auth.delete();
    await signOut();

    final bool signIn = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (!signIn) {
      final Exception ex = _auth.getError();
      await showBox(text: ex.toString(), context: context);
    }
    return signIn;
  }

  Future<bool> signInWithGoogle() async {
    FireBaseDB().removeAnonymous();
    await _auth.delete();
    await signOut();
    final bool signIn = await _auth.signInWithGoogle();
    if (!signIn) {
      final Exception ex = _auth.getError();
      await showBox(text: ex.toString(), context: _con?.state?.context);
    }
    await rebuild();
    return signIn;
  }

  // Stamp the user information to the firebase database.
  void userStamp() => FireBaseDB().userStamp();

  @override
  Future<void> rebuild() async {
    _loggedIn = _auth.isLoggedIn();
    refresh();
    // Pops only if on the stack and not on the first screen.
    final BuildContext context = _con?.state?.context;
    if (context != null) {
      await Navigator.of(context).maybePop();
    }
  }

  String get uid => _auth.uid;

  String get email => _auth.email;

  String get name => _auth.displayName;

  String get provider => _auth.providerId;

  bool get isNewUser => _auth.isNewUser;

  bool get isAnonymous => _auth.isAnonymous;

  String get photo => _auth.photoUrl;

  String get token => _auth.accessToken;

  String get tokenId => _auth.idToken;

  /// Override if you like to customize error handling.
  @override
  void onError(FlutterErrorDetails details) {
    super.onError(details);
  }
}
