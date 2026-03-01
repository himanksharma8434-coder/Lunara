const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
    });
}

walkDir('lib/screens', function (filePath) {
    if (!filePath.endsWith('.dart')) return;
    let content = fs.readFileSync(filePath, 'utf8');

    content = content.replace(/LunaraColors\.primary,/g, 'AppTheme.primary(context),');
    content = content.replace(/LunaraColors\.primary\)/g, 'AppTheme.primary(context))');
    content = content.replace(/LunaraColors\.primaryLight/g, 'AppTheme.backgroundPink(context)');
    content = content.replace(/LunaraColors\.background/g, 'AppTheme.background(context)');
    content = content.replace(/LunaraColors\.textDark/g, 'AppTheme.textDark(context)');
    content = content.replace(/LunaraColors\.textBrown/g, 'AppTheme.textBrown(context)');
    content = content.replace(/LunaraColors\.textLight/g, 'AppTheme.textLight(context)');
    content = content.replace(/LunaraColors\.divider/g, 'AppTheme.divider(context)');

    content = content.replace(/LunaraColors\.periodRed/g, 'AppTheme.periodRed(context)');
    content = content.replace(/LunaraColors\.fertileGreen/g, 'AppTheme.fertileGreen(context)');
    content = content.replace(/LunaraColors\.ovulationBlue/g, 'AppTheme.ovulationBlue(context)');
    content = content.replace(/LunaraColors\.lutealPurple/g, 'AppTheme.lutealPurple(context)');
    content = content.replace(/LunaraColors\.follicularTeal/g, 'AppTheme.follicularTeal(context)');

    content = content.replace(/LunaraGradients\.primary/g, 'AppTheme.primaryGradient(context)');
    content = content.replace(/LunaraGradients\.background/g, 'AppTheme.backgroundGradient(context)');
    content = content.replace(/LunaraGradients\.softBackground/g, 'AppTheme.softBackground(context)');

    content = content.replace(/LunaraShadows\.soft/g, 'AppTheme.softShadow(context)');
    content = content.replace(/LunaraShadows\.glow/g, 'AppTheme.glowShadow(context)');

    if (content !== fs.readFileSync(filePath, 'utf8')) {
        if (!content.includes("import '../theme/app_theme.dart';") && !content.includes("import 'package:lunara/theme/app_theme.dart';")) {
            content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../theme/app_theme.dart';");
        }
        fs.writeFileSync(filePath, content, 'utf8');
        console.log(`Migrated ${filePath}`);
    }
});
