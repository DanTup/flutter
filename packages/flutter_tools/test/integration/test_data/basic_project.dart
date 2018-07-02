// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'test_project.dart';

class BasicProject extends TestProject {

  @override
  final String pubspec = '''
  name: test
  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'package:flutter/material.dart';
  
  void main() => runApp(new MyApp());
  
  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      topLevelFunction();
      return new MaterialApp( // BREAKPOINT
        title: 'Flutter Demo',
        home: new Container(),
      );
    }
  }

  topLevelFunction() {
    print("test"); // 2 BREAKPOINT
  }
  ''';

  String get buildMethodBreakpointFile => breakpointFile;
  int get buildMethodBreakpointLine => breakpointLine;

  String get topLevelFunctionBreakpointFile => breakpointFile;
  int get topLevelFunctionBreakpointLine => lineContaining(main, '// 2 BREAKPOINT');
}
