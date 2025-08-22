import 'dart:convert';
import 'dart:io';

Future<int> runCmd(
    String cmd,
    List<String> args, {
      String? cwd,
      bool silent = false,
    }) async {
  final p = await Process.start(
    cmd,
    args,
    workingDirectory: cwd,
    runInShell: true,
    mode: ProcessStartMode.inheritStdio,
  );
  return await p.exitCode;
}

Future<String> runAndGetStdout(
    String cmd,
    List<String> args, {
      String? cwd,
    }) async {
  final p = await Process.start(
    cmd,
    args,
    workingDirectory: cwd,
    runInShell: true,
  );
  final out = await utf8.decodeStream(p.stdout);
  final err = await utf8.decodeStream(p.stderr);
  final code = await p.exitCode;
  if (code != 0) {
    stderr.writeln("❌ $cmd ${args.join(' ')} failed ($code)\n$err");
    exit(code);
  }
  return out + err;
}

Future<bool> hasCmd(String name) async {
  try {
    final which = Platform.isWindows ? 'where' : 'which';
    final code = await runCmd(which, [name], silent: true);
    return code == 0;
  } catch (_) {
    return false;
  }
}

bool fileExists(String path) => File(path).existsSync();
bool dirExists(String path) => Directory(path).existsSync();

Future<bool> hasBuildRunner() async {
  if (!fileExists('pubspec.yaml')) return false;
  final txt = await File('pubspec.yaml').readAsString();
  return txt.contains('build_runner');
}

bool hasTestsSync() {
  final d = Directory('test');
  if (!d.existsSync()) return false;
  return d
      .listSync(recursive: false, followLinks: false)
      .any((e) => e is File && e.path.endsWith('.dart'));
}

Future<void> copyFileToDir(String src, String destDir) async {
  final d = Directory(destDir);
  if (!d.existsSync()) d.createSync(recursive: true);
  final f = File(src);
  final basename = src.split(Platform.pathSeparator).last;
  await f.copy('${d.path}${Platform.pathSeparator}$basename');
}

Future<void> copyTree(String from, String to) async {
  final source = Directory(from);
  if (!source.existsSync()) return;
  final target = Directory(to)..createSync(recursive: true);
  await for (final entity in source.list(recursive: true)) {
    final rel = entity.path.substring(source.path.length);
    final newPath = target.path + rel;
    if (entity is Directory) {
      Directory(newPath).createSync(recursive: true);
    } else if (entity is File) {
      File(newPath).createSync(recursive: true);
      await entity.copy(newPath);
    }
  }
}

String nowTag() {
  final n = DateTime.now();
  String two(int x) => x.toString().padLeft(2, '0');
  return '${n.year}${two(n.month)}${two(n.day)}_${two(n.hour)}${two(n.minute)}${two(n.second)}';
}

void printHeader(String title) {
  stdout.writeln('\n=== $title ===');
}

Future<void> main(List<String> args) async {
  // Targets: --apk --aab --web --ios (اگر هیچ کدام نباشد: apk+aab+web)
  final wantApk = args.contains('--apk');
  final wantAab = args.contains('--aab');
  final wantWeb = args.contains('--web');
  final wantIos = args.contains('--ios');
  final none = !wantApk && !wantAab && !wantWeb && !wantIos;

  final appName = Platform.environment['APP_NAME'] ?? 'Bazari';
  final versionName = Platform.environment['VERSION_NAME'] ?? '1.0.0';
  final buildNumber = Platform.environment['BUILD_NUMBER'] ?? '1';

  // Checks
  if (!await hasCmd('flutter')) {
    stderr.writeln('❌ Flutter در PATH نیست. flutter doctor را نصب/تنظیم کن.');
    exit(1);
  }
  if (!await hasCmd('dart')) {
    stderr.writeln('❌ Dart در PATH نیست (با Flutter نصب می‌شود).');
    exit(1);
  }

  // Clean & pub get
  printHeader('🧹 Clean');
  if (await runCmd('flutter', ['clean']) != 0) exit(1);

  printHeader('📦 Pub get');
  if (await runCmd('flutter', ['pub', 'get']) != 0) exit(1);

  // Enable web (best effort)
  try {
    await runCmd('flutter', ['config', '--enable-web']);
  } catch (_) {}

  // build_runner (اختیاری)
  if (await hasBuildRunner()) {
    printHeader('🔧 build_runner');
    await runCmd('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  }

  // Analyze
  printHeader('🧪 Analyze');
  if (await runCmd('flutter', ['analyze']) != 0) {
    stderr.writeln('⚠️ Analyze هشدار/خطا داشت (ادامه می‌دهیم).');
  }

  // Test (اختیاری)
  if (hasTestsSync()) {
    printHeader('🧪 Test');
    final code = await runCmd('flutter', ['test']);
    if (code != 0) {
      stderr.writeln('⚠️ Test ناموفق بود (ادامه می‌دهیم).');
    }
  }

  // Dist folder
  final distDir = 'dist/${nowTag()}';
  Directory(distDir).createSync(recursive: true);

  // Build targets
  if (none || wantApk) {
    printHeader('📦 Build APK (release, split-ABI)');
    final code = await runCmd('flutter', [
      'build',
      'apk',
      '--release',
      '--split-per-abi',
      '--build-name=$versionName',
      '--build-number=$buildNumber',
    ]);
    if (code == 0) {
      final apkDir = Directory('build/app/outputs/flutter-apk');
      if (apkDir.existsSync()) {
        final out = '$distDir/android-apk';
        for (final e in apkDir.listSync()) {
          if (e is File && e.path.endsWith('-release.apk')) {
            await copyFileToDir(e.path, out);
          }
        }
      }
    } else {
      stderr.writeln('❌ ساخت APK ناموفق بود.');
    }
  }

  if (none || wantAab) {
    printHeader('🧰 Build AAB (release)');
    final code = await runCmd('flutter', [
      'build',
      'appbundle',
      '--release',
      '--build-name=$versionName',
      '--build-number=$buildNumber',
    ]);
    if (code == 0) {
      final aabPath = 'build/app/outputs/bundle/release/app-release.aab';
      if (fileExists(aabPath)) {
        final outDir = '$distDir/android-aab';
        Directory(outDir).createSync(recursive: true);
        final dest = '$outDir/$appName-$versionName+$buildNumber.aab';
        await File(aabPath).copy(dest);
      }
    } else {
      stderr.writeln('❌ ساخت AAB ناموفق بود.');
    }
  }

  if (none || wantWeb) {
    printHeader('🌐 Build Web (release)');
    final code = await runCmd('flutter', ['build', 'web', '--release']);
    if (code == 0) {
      await copyTree('build/web', '$distDir/web');
    } else {
      stderr.writeln('❌ ساخت Web ناموفق بود.');
    }
  }

  if (wantIos) {
    if (!Platform.isMacOS) {
      stderr.writeln('⚠️ ساخت iOS فقط روی macOS ممکن است. رد شد.');
    } else {
      printHeader('🍎 Build iOS (IPA)');
      final code = await runCmd('flutter', ['build', 'ipa', '--release']);
      if (code == 0) {
        final iosOut = Directory('build/ios');
        final dest = '$distDir/ios-ipa';
        Directory(dest).createSync(recursive: true);
        if (iosOut.existsSync()) {
          for (final e in iosOut.listSync(recursive: true)) {
            if (e is File && e.path.endsWith('.ipa')) {
              await copyFileToDir(e.path, dest);
            }
          }
        }
      } else {
        stderr.writeln('⚠️ ساخت iOS ناموفق (امضای کد/پروفایل؟).');
      }
    }
  }

  printHeader('✅ تمام شد! خروجی‌ها داخل: $distDir');
  try {
    for (final f in Directory(distDir).listSync(recursive: true)) {
      if (f is File) stdout.writeln('  • ${f.path}');
    }
  } catch (_) {}
}
