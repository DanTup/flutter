// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/version.dart';
import '../doctor.dart';
import 'vscode.dart';

class VsCodeValidator extends DoctorValidator {
  final VsCode _vsCode;

  VsCodeValidator(this._vsCode) : super('VS Code');

  static List<DoctorValidator> get installedValidators {
    final List<DoctorValidator> validators = <DoctorValidator>[];
    final List<VsCode> vsCodes = VsCode.allInstalled();
    if (vsCodes.isNotEmpty) {
      validators
          .addAll(vsCodes.map((VsCode vsCode) => new VsCodeValidator(vsCode)));
    }
    return validators;
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;
    final String vsCodeVersionText = _vsCode.version == Version.unknown
        ? null
        : 'version ${_vsCode.version}';
    messages.add(new ValidationMessage('VS Code at ${_vsCode.directory}'));
    if (_vsCode.isValid) {
      type = ValidationType.installed;
      messages.addAll(_vsCode.validationMessages
          .map((String m) => new ValidationMessage(m)));
    } else {
      type = ValidationType.partial;
      messages.addAll(_vsCode.validationMessages
          .map((String m) => new ValidationMessage.error(m)));
      messages.add(new ValidationMessage(
          'Dart Code extension not installed; install from\nhttps://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code'));
    }

    return new ValidationResult(type, messages, statusInfo: vsCodeVersionText);
  }
}
