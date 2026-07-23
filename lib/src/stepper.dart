/// Single-stepping execution engine for Brainfuck programs.
library;

import 'package:brainfxxk/src/exceptions.dart';
import 'package:brainfxxk/src/instruction.dart';
import 'package:brainfxxk/src/io.dart';
import 'package:brainfxxk/src/parse.dart';
import 'package:brainfxxk/src/tape.dart';

/// Executes a compiled Brainfuck [Program] one instruction at a time.
///
/// The stepper is the interpreter's execution core, exposed for tools
/// that need to observe execution: debuggers and live previews call
/// [step] and inspect [pc] and [tape] between instructions, while batch
/// callers use [run] — or the `Interpreter` facade, which is a thin
/// wrapper over this class.
final class Stepper {
  /// Creates a stepper for [program].
  ///
  /// @param program the compiled program to execute
  /// @param io the program's input/output channel
  /// @param tape the tape to execute on; a fresh 30000-cell tape is
  ///   created when omitted. Passing an existing tape continues from
  ///   its current cell and pointer state
  Stepper(Program program, {required this._io, Tape? tape})
    : _program = program,
      _tape = tape ?? Tape();

  /// Creates a stepper, compiling [source] at construction time.
  ///
  /// @param source the Brainfuck source code to compile
  /// @param io the program's input/output channel
  /// @param tape the tape to execute on; a fresh 30000-cell tape is
  ///   created when omitted
  /// @throws [UnclosedBracketException] if [source] has an unclosed `[`
  /// @throws [UnexpectedClosingBracketException] if [source] has a `]`
  ///   with no matching `[`
  Stepper.fromSource(String source, {required this._io, Tape? tape})
    : _program = parse(source),
      _tape = tape ?? Tape();

  final Program _program;
  final BrainfuckIO _io;
  final Tape _tape;
  int _pc = 0;

  /// The tape this stepper executes on.
  Tape get tape => _tape;

  /// The index of the next instruction to execute, `0..program.length`.
  int get pc => _pc;

  /// Jumps the execution position to [value].
  ///
  /// Setting [pc] to the program's length halts the stepper; setting it
  /// back re-executes instructions — tape and IO side effects are not
  /// undone.
  ///
  /// @param value the new program counter, `0 <= value <= program.length`
  /// @throws [RangeError] if [value] is outside `0..program.length`
  set pc(int value) {
    RangeError.checkValueInInterval(value, 0, _program.length, 'pc');
    _pc = value;
  }

  /// Whether the program has run to completion.
  bool get isHalted => _pc == _program.length;

  /// Executes the single instruction at [pc] and advances past it.
  ///
  /// @throws [StateError] if the stepper [isHalted]
  /// @throws [BrainfuckRuntimeException] on runtime failures: moving
  ///   the pointer left of cell 0, or reading input at end of input.
  ///   [pc] is unchanged when an instruction throws, so the failed
  ///   instruction can be retried — e.g. after feeding more input
  void step() {
    if (isHalted) {
      throw StateError('cannot step: the program has run to completion');
    }
    switch (_program.instructions[_pc]) {
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
        if (_tape.read() == 0) _pc = _program.jumpTable[_pc];
      case Instruction.loopEnd:
        if (_tape.read() != 0) _pc = _program.jumpTable[_pc];
    }
    _pc++;
  }

  /// Executes instructions until the stepper [isHalted].
  ///
  /// @throws [BrainfuckRuntimeException] on runtime failures; see [step]
  void run() {
    while (!isHalted) {
      step();
    }
  }
}
