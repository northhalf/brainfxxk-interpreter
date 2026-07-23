/// A stdin/stdout-backed [BrainfuckIO] for command-line apps.
///
/// This library imports `dart:io` and therefore cannot be compiled to
/// the web; it is exported only from `package:brainfxxk/stdio.dart`,
/// never from the platform-neutral `package:brainfxxk/brainfxxk.dart`.
library;

import 'dart:io';

import 'package:brainfxxk/src/io.dart';

/// A [BrainfuckIO] backed by stdin and stdout; used by the CLI.
final class StdioBrainfuckIO implements BrainfuckIO {
  /// Creates a stdio-backed IO.
  const StdioBrainfuckIO();

  @override
  int? read() {
    final byte = stdin.readByteSync();
    return byte < 0 ? null : byte;
  }

  @override
  void write(int byte) => stdout.add([byte]);
}
