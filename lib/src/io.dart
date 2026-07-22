/// Byte-level input/output abstraction for Brainfuck programs.
library;

import 'dart:io';

/// Byte-level input and output for a running Brainfuck program.
///
/// The interpreter talks only to this interface, so tests can inject an
/// in-memory implementation while the CLI uses [StdioBrainfuckIO].
abstract interface class BrainfuckIO {
  /// Reads one byte of input.
  ///
  /// @return the byte read (0–255), or null at end of input — the
  ///   interpreter throws a BrainfuckRuntimeException on EOF
  int? read();

  /// Writes one byte of output.
  ///
  /// @param byte the byte to write (0–255)
  void write(int byte);
}

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
