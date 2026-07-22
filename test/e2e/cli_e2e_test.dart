import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  final dart = Platform.resolvedExecutable;

  Future<ProcessResult> runCli(List<String> args) => Process.run(
    dart,
    ['bin/bf.dart', ...args],
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );

  group('bf CLI', () {
    test('-e executes a source string', () async {
      final result = await runCli(['-e', '+++.']);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(result.stdout, [3]);
    });

    test('executes a file', () async {
      final tempDir = Directory.systemTemp.createTempSync('bf_e2e_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final file = File('${tempDir.path}/prog.bf')..writeAsStringSync('+++.');

      final result = await runCli([file.path]);

      expect(result.exitCode, 0, reason: result.stderr as String);
      expect(result.stdout, [3]);
    });

    test('exits 66 when the file cannot be read', () async {
      final result = await runCli(['no/such/file.bf']);

      expect(result.exitCode, 66);
      expect(result.stderr as String, contains('cannot read'));
    });

    test('exits 64 when both -e and a file are given', () async {
      final result = await runCli(['-e', '+.', 'prog.bf']);

      expect(result.exitCode, 64);
      expect(result.stderr as String, contains('Usage'));
    });

    test('exits 64 on an unknown option', () async {
      final result = await runCli(['--nope']);

      expect(result.exitCode, 64);
      expect(result.stderr as String, contains('Usage'));
    });

    test('exits 1 with the position on a parse error', () async {
      final result = await runCli(['-e', '[']);

      expect(result.exitCode, 1);
      expect(result.stderr as String, contains('line 1, column 1'));
    });

    test('exits 1 on a runtime error', () async {
      final result = await runCli(['-e', '<']);

      expect(result.exitCode, 1);
      expect(result.stderr as String, contains('BrainfuckRuntimeException'));
    });

    test('--help prints usage and exits 0', () async {
      final result = await runCli(['--help']);

      expect(result.exitCode, 0);
      expect(utf8.decode(result.stdout as List<int>), contains('Usage'));
    });

    test('starts a REPL session when no arguments are given', () async {
      final process = await Process.start(dart, ['bin/bf.dart']);
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      process.stdin
        ..writeln('+++.')
        ..writeln('q');
      await process.stdin.close();

      final output = await process.stdout.fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );

      expect(await process.exitCode, 0, reason: await stderrFuture);
      expect(output, [...'bf> '.codeUnits, 3, ...'bf> '.codeUnits]);
    });
  });
}
