/// The Brainfuck execution engine.
library;

import 'package:brainfxxk/src/exceptions.dart';
import 'package:brainfxxk/src/instruction.dart';
import 'package:brainfxxk/src/io.dart';
import 'package:brainfxxk/src/parse.dart';
import 'package:brainfxxk/src/tape.dart';

/// Executes compiled Brainfuck [Program]s on a [Tape].
///
/// The interpreter holds a tape and an IO channel. It can be fed a
/// program in three ways: compiled from source at construction time
/// with [Interpreter.fromSource], or passed to [run] directly — or
/// both, in which case the argument wins.
final class Interpreter {
  /// Creates an interpreter with no preloaded program.
  ///
  /// @param io the program's input/output channel; command-line apps
  ///   can use `StdioBrainfuckIO` from `package:brainfxxk/stdio.dart`
  /// @param tape the tape to execute on; a fresh 30000-cell tape is
  ///   created when omitted. Passing the same tape to one interpreter
  ///   keeps cell and pointer state across [run] calls — the REPL is
  ///   built on this
  Interpreter({required this._io, Tape? tape})
    : _tape = tape ?? Tape(),
      _program = null;

  /// Creates an interpreter and compiles [source] at construction time.
  ///
  /// @param source the Brainfuck source code to compile
  /// @param io the program's input/output channel; command-line apps
  ///   can use `StdioBrainfuckIO` from `package:brainfxxk/stdio.dart`
  /// @param tape the tape to execute on; a fresh 30000-cell tape is
  ///   created when omitted
  /// @throws [UnclosedBracketException] if [source] has an unclosed `[`
  /// @throws [UnexpectedClosingBracketException] if [source] has a `]`
  ///   with no matching `[`
  Interpreter.fromSource(String source, {required this._io, Tape? tape})
    : _tape = tape ?? Tape(),
      _program = parse(source);

  final Tape _tape;
  final BrainfuckIO _io;
  final Program? _program;

  /// The tape this interpreter executes on.
  Tape get tape => _tape;

  /// Executes a program.
  ///
  /// @param program the program to run; when omitted, the program
  ///   compiled by [Interpreter.fromSource] is used
  /// @throws [StateError] if there is no program to run: the default
  ///   constructor was used and [program] is omitted
  /// @throws [BrainfuckRuntimeException] on runtime failures: moving
  ///   the pointer left of cell 0, or reading input at end of input
  void run([Program? program]) {
    final resolved = program ?? _program;
    if (resolved == null) {
      throw StateError(
        'No program to run: use Interpreter.fromSource() '
        'or pass a Program to run()',
      );
    }

    final instructions = resolved.instructions;
    final jumpTable = resolved.jumpTable;
    var pc = 0;
    while (pc < instructions.length) {
      switch (instructions[pc]) {
        case Instruction.moveRight:
          _tape.moveRight();
        case Instruction.moveLeft:
          _tape.moveLeft();
        case Instruction.increment:
          _tape.increment();
        case Instruction.decrement:
          _tape.decrement();
        case Instruction.output:
          _io.write(_tape.read());
        case Instruction.input:
          final byte = _io.read();
          if (byte == null) {
            throw const BrainfuckRuntimeException(
              'input instruction read at end of input',
            );
          }
          _tape.write(byte);
        case Instruction.loopStart:
          if (_tape.read() == 0) pc = jumpTable[pc];
        case Instruction.loopEnd:
          if (_tape.read() != 0) pc = jumpTable[pc];
      }
      pc++;
    }
  }
}
