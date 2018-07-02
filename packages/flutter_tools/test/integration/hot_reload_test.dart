// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/test.dart';
import 'package:vm_service_client/vm_service_client.dart';

import 'test_data/basic_project.dart';
import 'test_driver.dart';

BasicProject _project = new BasicProject();
FlutterTestDriver _flutter;

void main() {
  group('hot reload', () {
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

    test('works without error', () async {
      await _flutter.run();

      // Due to https://github.com/flutter/flutter/issues/17833 this will
      // throw on Windows. If you merge a fix for this and this test starts failing
      // because it didn't throw on Windows, you should delete the wrapping expect()
      // and just `await` the hotReload directly
      // (dantup)
      expect(
        _flutter.hotReload,
        platform.isWindows ? throwsA(anything) : returnsNormally,
      );
    });

    test('hits breakpoints with file:// prefixes after reload', () async {
      await _flutter.run(withDebugger: true);

      // Add a breakpoint using a file:// URI.
      await _flutter.addBreakpoint(
          new Uri.file(_project.breakpointFile).toString(),
          _project.breakpointLine);

      // Due to https://github.com/flutter/flutter/issues/17833 this will
      // throw on Windows. If you merge a fix for this and this test starts failing
      // because it didn't throw on Windows, you should delete the wrapping expect()
      // and just `await` the hotReload directly
      // (dantup)
      expect(
        _flutter.hotReload,
        platform.isWindows ? throwsA(anything) : returnsNormally,
      );

      // This test fails due to // https://github.com/flutter/flutter/issues/18441
      // If you merge a fix for this and the test starts failing because it's not
      // timing out, delete the wrapping expect/return below.
      // (dantup)
      //
      // final VMIsolate isolate = await _flutter.waitForBreakpointHit();
      // expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
      expect(() async {
        final VMIsolate isolate = await _flutter.waitForBreakpointHit();
        expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
      },
        throwsA(anything)
      );
    });
  }, timeout: const Timeout.factor(3));
}
