// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();

    // Simple regex replacements for the main offenders
    content = content.replaceAll(
        'LunaraColors.primary,', 'AppTheme.primary(context),');
    content = content.replaceAll(
        'LunaraColors.primary)', 'AppTheme.primary(context))');
    content = content.replaceAll(
        'LunaraColors.primaryLight', 'AppTheme.backgroundPink(context)');
    content = content.replaceAll(
        'LunaraColors.background', 'AppTheme.background(context)');
    content = content.replaceAll(
        'LunaraColors.textDark', 'AppTheme.textDark(context)');
    content = content.replaceAll(
        'LunaraColors.textBrown', 'AppTheme.textBrown(context)');
    content = content.replaceAll(
        'LunaraColors.textLight', 'AppTheme.textLight(context)');
    content =
        content.replaceAll('LunaraColors.divider', 'AppTheme.divider(context)');

    content = content.replaceAll(
        'LunaraColors.periodRed', 'AppTheme.periodRed(context)');
    content = content.replaceAll(
        'LunaraColors.fertileGreen', 'AppTheme.fertileGreen(context)');
    content = content.replaceAll(
        'LunaraColors.ovulationBlue', 'AppTheme.ovulationBlue(context)');
    content = content.replaceAll(
        'LunaraColors.lutealPurple', 'AppTheme.lutealPurple(context)');
    content = content.replaceAll(
        'LunaraColors.follicularTeal', 'AppTheme.follicularTeal(context)');

    content = content.replaceAll(
        'LunaraGradients.primary', 'AppTheme.primaryGradient(context)');
    content = content.replaceAll(
        'LunaraGradients.background', 'AppTheme.backgroundGradient(context)');
    content = content.replaceAll(
        'LunaraGradients.softBackground', 'AppTheme.softBackground(context)');

    content = content.replaceAll(
        'LunaraShadows.soft', 'AppTheme.softShadow(context)');
    content = content.replaceAll(
        'LunaraShadows.glow', 'AppTheme.glowShadow(context)');

    // Add import if missing and something was replaced
    if (content != file.readAsStringSync() &&
        !content.contains("import '../theme/app_theme.dart';") &&
        !content.contains("import 'package:lunara/theme/app_theme.dart';")) {
      // Just insert it after material.dart
      content = content.replaceFirst("import 'package:flutter/material.dart';",
          "import 'package:flutter/material.dart';\nimport '../theme/app_theme.dart';");
    }

    file.writeAsStringSync(content);
    print('Migrated \${file.path}');
  }
}
