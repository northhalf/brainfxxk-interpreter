/// Interactive read-eval-print loop for Brainfuck.
library;

import 'dart:async';
import 'dart:io';

import 'package:brainfxxk/src/exceptions.dart';
import 'package:brainfxxk/src/instruction.dart';
import 'package:brainfxxk/src/interpreter.dart';
import 'package:brainfxxk/src/io.dart';
import 'package:brainfxxk/src/parse.dart';
import 'package:brainfxxk/src/stdio.dart';

/// An interactive Brainfuck read-eval-print loop.
///
/// Source lines are read one at a time and executed on a single shared
/// [Interpreter], so tape and pointer state persist across lines.
/// Brackets may span lines: while a `[` stays unclosed, input is
/// buffered behind a `...` continuation prompt instead of being
/// executed or reported as an error.
final class Repl {
  /// Creates a REPL.
  ///
  /// @param lines the source of input lines
  /// @param io the channel executed programs use for `,` and `.`
  /// @param out where prompts and error messages are written
  Repl({
    required this._lines,
    required BrainfuckIO io,
    required this._out,
  }) : _interpreter = Interpreter(io: io);

  /// Creates a REPL wired to stdin and stdout.
  ///
  /// Input lines come from stdin via `stdin.readLineSync`, executed
  /// programs use a [StdioBrainfuckIO] for `,` and `.`, and prompts
  /// and error messages go to stdout. The CLI uses this.
  ///
  /// Lines are read with `stdin.readLineSync` rather than the async
  /// `stdin` stream because the async stream does not reliably detect
  /// end of input from a terminal Ctrl-D, while the synchronous read
  /// does. The `async*` generator still yields one line at a time so
  /// the loop can execute each program before reading the next.
  factory Repl.stdio() => Repl(
    lines: _stdioLines(),
    io: const StdioBrainfuckIO(),
    out: stdout,
  );

  static Stream<String> _stdioLines() async* {
    while (true) {
      final line = stdin.readLineSync();
      if (line == null) return;
      yield line;
    }
  }

  static const String _prompt = 'bf> ';
  static const String _continuationPrompt = '... ';

  final Stream<String> _lines;
  final Interpreter _interpreter;
  final StringSink _out;

  /// Runs the interactive loop until the session ends.
  ///
  /// The session ends when a trimmed input line is exactly `q` or
  /// `exit` (checked before bracket buffering, also in continuation
  /// mode), when the line stream ends (EOF), or when a running program
  /// throws a [BrainfuckRuntimeException] — the error is printed
  /// first. An [UnexpectedClosingBracketException] is printed, the
  /// buffer is dropped, and the loop returns to the main prompt.
  Future<void> run() async {
    final buffer = StringBuffer();
    _out.write(_prompt);
    await for (final line in _lines) {
      final trimmed = line.trim();
      if (trimmed == 'q' || trimmed == 'exit') return;

      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(line);

      final Program program;
      try {
        program = parse(buffer.toString());
      } on UnclosedBracketException {
        _out.write(_continuationPrompt);
        continue;
      } on UnexpectedClosingBracketException catch (e) {
        _out
          ..writeln(e)
          ..write(_prompt);
        buffer.clear();
        continue;
      }
      buffer.clear();

      try {
        _interpreter.run(program);
      } on BrainfuckRuntimeException catch (e) {
        _out.writeln(e);
        return;
      }
      _out.write(_prompt);
    }
  }
}
