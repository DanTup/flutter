// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';
import 'package:vm_service_client/vm_service_client.dart';

import 'test_data/basic_project.dart';
import 'test_driver.dart';

BasicProject _project = new BasicProject();
FlutterTestDriver _flutter;

void main() {
  setUp(() async {
    final Directory tempDir = await fs.systemTempDirectory.createTemp('test_app');
    await _project.setUpIn(tempDir);
    _flutter = new FlutterTestDriver(tempDir);
  });

  tearDown(() async {
    try {
      await _flutter.stop();
      _project.cleanup();
    } catch (e) {
      // Don't fail tests if we failed to clean up temp folder.
    }
  });

  Future<VMIsolate> breakInBuildMethod(FlutterTestDriver flutter) async {
    return _flutter.breakAt(
        _project.buildMethodBreakpointFile,
        _project.buildMethodBreakpointLine);
  }

  Future<VMIsolate> breakInTopLevelFunction(FlutterTestDriver flutter) async {
    return _flutter.breakAt(
        _project.topLevelFunctionBreakpointFile,
        _project.topLevelFunctionBreakpointLine);
  }

  group('FlutterTesterDevice', () {
    test('can hot reload', () async {
      await _flutter.run();
      await _flutter.hotReload();
    }, skip: true); // https://github.com/flutter/flutter/issues/17833

    test('can hit breakpoints with file:// prefixes after reload', () async {
      await _flutter.run(withDebugger: true);

      // Add a breakpoint using a file:// URI.
      await _flutter.addBreakpoint(
          new Uri.file(_project.breakpointFile).toString(),
          _project.breakpointLine);

      await _flutter.hotReload();

      // Ensure we hit the breakpoint.
      final VMIsolate isolate = await _flutter.waitForBreakpointHit();
      expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
    }, skip: true); // https://github.com/flutter/flutter/issues/18441

    Future<void> evaluateTrivialExpressions() async {
      VMInstanceRef res;

      res = await _flutter.evaluateExpression('"test"');
      expect(res is VMStringInstanceRef && res.value == 'test', isTrue);

      res = await _flutter.evaluateExpression('"test"');
      expect(res is VMIntInstanceRef && res.value == 1, isTrue);

      res = await _flutter.evaluateExpression('"test"');
      expect(res is VMBoolInstanceRef && res.value == true, isTrue);
    }

    Future<void> evaluateComplexExpressions() async {
      final VMInstanceRef res = await _flutter.evaluateExpression('new DateTime.now().year');
      expect(res is VMIntInstanceRef && res.value == new DateTime.now().year, isTrue);
    }

    Future<void> evaluateComplexReturningExpressions() async {
      final DateTime now = new DateTime.now();
      final VMInstanceRef resp = await _flutter.evaluateExpression('new DateTime.now()');
      expect(resp.klass.name, equals('DateTime'));
      final DateTime value = await resp.getValue();
      // Ensure we got a reasonable approximation. The more accurate we try to
      // make this, the more likely it'll fail due to differences in the time
      // in the remote VM and the local VM.
      expect('${value.year}-${value.month}-${value.day}',
          equals('${now.year}-${now.month}-${now.day}'));
    }

    test('can evaluate trivial expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678

    test('can evaluate trivial expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateTrivialExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678

    test('can evaluate complex expressions in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateTrivialExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678

    test('can evaluate complex expressions in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678

    test('can evaluate expressions returning complex objects in top level function', () async {
      await _flutter.run(withDebugger: true);
      await breakInTopLevelFunction(_flutter);
      await evaluateComplexReturningExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678

    test('can evaluate expressions returning complex objects in build method', () async {
      await _flutter.run(withDebugger: true);
      await breakInBuildMethod(_flutter);
      await evaluateComplexReturningExpressions();
    }, skip: true); // https://github.com/flutter/flutter/issues/18678
  }, timeout: const Timeout.factor(3));
}
