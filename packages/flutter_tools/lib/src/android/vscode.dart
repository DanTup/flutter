// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/version.dart';
import '../ios/plist_utils.dart';

// VS Code layout:

// Linux/Windows:
// ?????????????????

// macOS:
// /Applications/Visual Studio Code.app/Contents/
// /Applications/Visual Studio Code - Insiders.app/Contents/
// $HOME/Applications/Visual Studio Code.app/Contents/
// $HOME/Applications/Visual Studio Code - Insiders.app/Contents/

class VsCode {
  VsCode(this.directory, this.dataFolderName, {Version version})
      : this.version = version ?? Version.unknown {
    _init();
  }

  final String directory;
  final String dataFolderName;
  final Version version;

  bool _isValid = false;
  Version extensionVersion;
  final List<String> _validationMessages = <String>[];

  factory VsCode.fromMacOSBundle(String bundlePath, String dataFolderName) {
    final String vsCodePath = fs.path.join(bundlePath, 'Contents');
    final String plistFile = fs.path.join(vsCodePath, 'Info.plist');
    final String versionString =
        getValueFromFile(plistFile, kCFBundleShortVersionStringKey);
    Version version;
    if (versionString != null) version = new Version.parse(versionString);
    return new VsCode(bundlePath, dataFolderName, version: version);
  }

  bool get isValid => _isValid;

  List<String> get validationMessages => _validationMessages;

  static List<VsCode> allInstalled() =>
      platform.isMacOS ? _allMacOS() : _allLinuxOrWindows();

  static List<VsCode> _allMacOS() {
    final List<VsCode> results = <VsCode>[];

    for (var root in ['/', homeDirPath]) {
      // VS Code
      var directory =
          fs.path.join(root, 'Applications', 'Visual Studio Code.app');
      if (fs.directory(directory).existsSync())
        results.add(new VsCode.fromMacOSBundle(directory, '.vscode'));

      // VS Code Insiders
      // TODO: This is helpful for testing (since uninstalling/reinstalling Insiders
      // is less disruptive than uninstalling the Code you're using to develop)
      // but probably shouldn't be in shipping version because we don't want to
      // warn people that may have Dart Code installed for Code but not Insiders.
      directory = fs.path
          .join(root, 'Applications', 'Visual Studio Code - Insiders.app');
      if (fs.directory(directory).existsSync())
        results.add(new VsCode.fromMacOSBundle(directory, '.vscode-insiders'));
    }

    return results;
  }

  static List<VsCode> _allLinuxOrWindows() {
    throw new UnimplementedError();
  }

  void _init() {
    _isValid = false;
    _validationMessages.clear();

    if (!fs.isDirectorySync(directory)) {
      _validationMessages.add('VS Code not found at $directory');
      return;
    }

    // Check for presence of extension.
    final extensionFolders = fs
        .directory(fs.path.join(homeDirPath, dataFolderName, 'extensions'))
        .listSync()
        .where((d) => fs.isDirectorySync(d.path))
        .where((d) => d.basename.startsWith('Dart-Code.dart-code'));

    if (extensionFolders.isNotEmpty) {
      final extensionFolder = extensionFolders.first;

      _isValid = true;
      extensionVersion = new Version.parse(
          extensionFolder.basename.substring('Dart-Code.dart-code-'.length));
      validationMessages.add('Dart Code extension version $extensionVersion');
    }
  }

  @override
  String toString() =>
      'VS Code ($version)${(extensionVersion != Version.unknown ? ', Dart Code ($extensionVersion)' : '')}';
}
