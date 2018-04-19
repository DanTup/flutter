// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';

class AndroidConsole {
  final Socket socket;
  final StreamQueue<String> queue;

  AndroidConsole._(this.socket)
      : queue = new StreamQueue<String>(socket.asyncMap(ascii.decode));

  Future<String> getAvdName() async {
    _write('avd name\n');
    return _readResponse();
  }

  void destroy() {
    socket.destroy();
  }

  // Emulators always have IDs in the format emulator-(port) where port is the
  // Android Console port number.
  static final RegExp _emulatorPortRegex = new RegExp(r'emulator-(\d+)');

  static Future<AndroidConsole> connect(String id) async {
    final Match portMatch = _emulatorPortRegex.firstMatch(id);
    if (portMatch == null || portMatch.groupCount < 1) {
      return null;
    }
    
    const String host = 'localhost';
    final int port = int.parse(portMatch.group(1));

    final Socket socket = await Socket.connect(host, port);
    final AndroidConsole console = new AndroidConsole._(socket);

    // Discard connection text.
    await console._readResponse();
    
    return console;
  }

  void _write(String text) {
    socket.add(ascii.encode(text));
  }

  Future<String> _readResponse() async {
    String text = (await queue.next).trim();
    if (text.endsWith('\nOK')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}
