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

      await expectLater(
        _flutter.hotReload(),
        platform.isWindows ? throwsA(anything) : completes,
      );
    });

    test('hits breakpoints with file:// prefixes after reload', () async {
      await _flutter.run(withDebugger: true);

      // This test fails due to // https://github.com/flutter/flutter/issues/18441
      // If you merge a fix for this and the test starts failing because it's not
      // timing out, delete the wrapping expect below and `await` the result directly.
      // If it still fails on Windows, that may be because of 
      // https://github.com/flutter/flutter/issues/17833 (see test above)
      // in which change the expectation to:
      // 
      //    platform.isWindows ? throwsA(anything) : completes
      // 
      // and one the windows issue is fixed, then the expectation can be removed
      // and the breakAt call `await`ed directly.
      // (dantup)
      //
      // final VMIsolate isolate = await _flutter.breakAt(
      //     new Uri.file(_project.breakpointFile).toString(),
      //     _project.breakpointLine
      // );
      // expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
      await expectLater(() async {
        // Hit breakpoint using a file:// URI.
        final VMIsolate isolate = await _flutter.breakAt(
            new Uri.file(_project.breakpointFile).toString(),
            _project.breakpointLine
        );
        expect(isolate.pauseEvent, const isInstanceOf<VMPauseBreakpointEvent>());
      }(), platform.isLinux ? completes : throwsA(anything));
    });
  }, timeout: const Timeout.factor(3));
}
