/// Example: single-step a Brainfuck program with `Stepper`.
///
/// Run with `dart run example/stepper_example.dart`.
library;

import 'dart:io';

import 'package:brainfxxk/brainfxxk.dart';

/// A minimal in-memory [BrainfuckIO] with a refillable input buffer.
final class _MemoryIO implements BrainfuckIO {
  _MemoryIO(List<int> input) : _input = List.of(input);

  final List<int> _input;
  final List<int> _output = <int>[];
  var _cursor = 0;

  /// The bytes the program has written so far.
  List<int> get output => _output;

  /// Appends more input bytes, as if the user typed them later.
  void feed(List<int> bytes) => _input.addAll(bytes);

  @override
  int? read() => _cursor < _input.length ? _input[_cursor++] : null;

  @override
  void write(int byte) => _output.add(byte);
}

/// The source character for [instruction], for display.
String _symbol(Instruction instruction) => switch (instruction) {
  Instruction.moveRight => '>',
  Instruction.moveLeft => '<',
  Instruction.increment => '+',
  Instruction.decrement => '-',
  Instruction.output => '.',
  Instruction.input => ',',
  Instruction.loopStart => '[',
  Instruction.loopEnd => ']',
};

void main() {
  // 1) Step through a program one instruction at a time, printing a
  //    trace: the pc and instruction about to run, then the tape state
  //    right after it. The program doubles 2 into 4 and outputs it.
  final program = parse('++[>++<-]>.');
  final traceIO = _MemoryIO(const []);
  final stepper = Stepper(program, io: traceIO);

  stdout.writeln('trace of ++[>++<-]>. :');
  while (!stepper.isHalted) {
    final pc = stepper.pc;
    final instruction = _symbol(program.instructions[pc]);
    stepper.step();
    final tape = stepper.tape;
    stdout.writeln(
      '  pc=${pc.toString().padLeft(2)}  $instruction  '
      'ptr=${tape.pointer}  cell=${tape[tape.pointer]}',
    );
  }
  stdout.writeln('output: ${traceIO.output}'); // [4]

  // 2) A failed instruction keeps its pc, so it can be retried: the
  //    input below starts empty, the `,` hits end of input, we feed a
  //    byte, and the very same instruction then succeeds.
  final echoIO = _MemoryIO(const []);
  final echo = Stepper.fromSource(',.', io: echoIO);
  try {
    echo.step();
  } on BrainfuckRuntimeException {
    stdout.writeln('retry: input empty at pc=${echo.pc}, feeding 65');
  }
  echoIO.feed([65]);
  echo
    ..step() // the same `,` that just failed
    ..step();
  stdout.writeln('retry: output ${echoIO.output}'); // [65]
}
