import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/settings.dart';
import 'data/repositories/word_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面端（Windows/Linux）使用 sqflite ffi 实现；iOS/Android 使用原生 sqflite。
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppDatabase.instance.open();
  await AppSettings.instance.load();
  await WordRepository.instance.seedBuiltInBooks();

  runApp(const CijiApp());
}