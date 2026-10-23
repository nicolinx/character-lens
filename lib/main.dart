import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  EquatableConfig.stringify = kDebugMode;
  runApp(const ProviderScope(child: CharacterLensApp()));
}
