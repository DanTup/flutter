// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dds/dds.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../../src/common.dart';
import '../test_data/integration_tests_project.dart';
import '../test_utils.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = getFlutterRoot();
  });

  for (final bool enableDds in <bool>[false, true]) {
    test('run basic integration test (${enableDds ? 'with DDS' : 'without DDS'})', () async {
      final IntegrationTestsProject project = IntegrationTestsProject();
      final Directory tempDir =
          createResolvedTempDirectorySync('flutter_test_adapter_test.');
      await project.setUpIn(tempDir);

      final Process proc = await Process.start(
        fileSystem.path.join(
            Cache.flutterRoot!,
            'bin',
            platform.isWindows ? 'flutter.bat' : 'flutter',
        ),
        <String>[
          'test',
          '--machine',
          '--start-paused',
          'integration_test/app_test.dart',
          '-d',
          'flutter-tester'
        ],
        workingDirectory: tempDir.path,
      );
      proc.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((String line) async {
        print(line);

        // Extract the VM Service URI to connect to and resume.
        if (line.contains('test.startedProcess')) {
          final json = jsonDecode(line);
          Uri vmServiceUri = Uri.parse(json[0]['params']['observatoryUri'] as String);
          vmServiceUri = vmServiceUri.replace( scheme: 'ws', path: '${vmServiceUri.path}ws');

          // Create a DDS instance
          if (enableDds) {
            print('Creating DDS connection to $vmServiceUri...');
            final dds = await DartDevelopmentService.startDartDevelopmentService(
              vmServiceUriToHttp(vmServiceUri),
            );
            vmServiceUri = dds.wsUri!;
          }

          // Wait to ensure the initial isolate is available to simplify testing.
          await Future.delayed(const Duration(seconds: 1));
          print('Connecting to VM Service at $vmServiceUri...');

          final VmService vmService = await vmServiceConnectUri(vmServiceUri.toString());
          final VM vm = await vmService.getVM();
          for (IsolateRef isolateRef in vm.isolates ?? const []) {
            if (!(isolateRef.isSystemIsolate ?? false)) {
              final Isolate isolate = await vmService.getIsolate(isolateRef.id!);

              if (isolate.pauseEvent?.kind == EventKind.kPauseStart) {
                print('resuming PauseStart isolate ${isolate.id}');
                await vmService.resume(isolateRef.id!);
              } else {
                print('ignoring ${isolate.pauseEvent?.kind} isolate ${isolate.id}');
              }
            }
          }
        }
      });

      await proc.exitCode;
    });
  }
}

/// Fixes up a VM Service WebSocket URI to not have a trailing /ws
/// and use the HTTP scheme which is what DDS expects.
Uri vmServiceUriToHttp(Uri uri) {
  final isSecure = uri.isScheme('https') || uri.isScheme('wss');
  uri = uri.replace(scheme: isSecure ? 'https' : 'http');

  final segments = uri.pathSegments;
  if (segments.isNotEmpty && segments.last == 'ws') {
    uri = uri.replace(pathSegments: segments.take(segments.length - 1));
  }

  return uri;
}
