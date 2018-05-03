// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

final String stocksExampleAppPath = fs.path.join(getFlutterRoot(), 'examples', 'stocks');

void main() {
  setUp(() async {
    final Directory buildDirectory =
        fs.directory(fs.path.join(stocksExampleAppPath, 'build'));
    if (await buildDirectory.exists()) {
      await buildDirectory.delete(recursive: true);
    }
  });

  tearDown(() {});

  group('flutter run --machine', () {
    testUsingContext('stops builds when sent app.stop', () async {
      
      final FlutterRun flutterRun = await FlutterRun.start(stocksExampleAppPath);      
      // TODO(dantup): Is it valid to have async in listen function?
      flutterRun.commands.listen((dynamic cmd) async {
        // As soon as we get app.start, send a request to stop.
        if (cmd['event'] == 'app.start') {
          await flutterRun.send(<String, dynamic>{
            'event': 'app.stop',
            'params': <String, dynamic>{'appId': cmd['params']['appId']}
          });
        } else if (cmd['event'] == 'app.started' || cmd['event'] == 'app.debugPort') {
          throw new Exception('App started after app.stop was sent');
        }
      });
      flutterRun.errors.listen((String line) {
        throw new Exception('Unexpected stderr running flutter run --machine: ' + line);
      });

      await flutterRun.exitCode;
    }, timeout: const Timeout.factor(2));
  });
}

class FlutterRun {
  final Process process;
  final Stream<dynamic> commands;
  final Stream<String> errors;
  final Future<int> exitCode;
  FlutterRun._(this.process)
      : commands = process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .where((String line) => line.startsWith('[') && line.endsWith(']'))
            .map<dynamic>((String line) {
          print('<== ' + line); // TODO(dantup): Remove debug logging
          return json.decode(line)[0];
        }),
        errors = process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter()),
        exitCode = process.exitCode;

  static Future<FlutterRun> start(String appDirectory) async {
    final List<String> command = <String>[
      fs.path.join(getFlutterRoot(), 'bin', 'flutter'),
      'run',
      '--machine',
      '-d',
      'flutter-tester'
    ];
    final Process process =
        await processManager.start(command, workingDirectory: appDirectory);
    return new FlutterRun._(process);
  }

  Future<void> send(Map<String, dynamic> command) async {
    final String text = json.encode(<dynamic>[command]);
    print('==> ' + text); // TODO(dantup): Remove debug logging
    process.stdin.add(text.codeUnits);
    await process.stdin.flush();
  }
}
