import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('StdioBrainfuckIO', () {
    test('round-trips raw bytes and reports EOF as null', () async {
      final process = await Process.start(
        Platform.resolvedExecutable,
        ['test/stdio_echo_harness.dart'],
      );
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      process.stdin.add([72, 105, 0, 255]);
      await process.stdin.close();

      final output = await process.stdout.fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );

      expect(await process.exitCode, 0, reason: await stderrFuture);
      expect(output, [72, 105, 0, 255, 0xFF]);
    });
  });
}
