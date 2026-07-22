/// Example: drive the `brainfxxk` interpreter from Dart code.
///
/// Run with `dart run example/brainfxxk_example.dart`.
library;

import 'dart:io';

import 'package:brainfxxk/brainfxxk.dart';

/// A minimal in-memory [BrainfuckIO]: it feeds seeded input bytes and
/// captures every byte the program writes.
final class _MemoryIO implements BrainfuckIO {
  _MemoryIO(this._input);

  final List<int> _input;
  final List<int> _output = <int>[];
  var _cursor = 0;

  /// The bytes the program has written so far.
  List<int> get output => _output;

  @override
  int? read() => _cursor < _input.length ? _input[_cursor++] : null;

  @override
  void write(int byte) => _output.add(byte);
}

void main() {
  // 1) Compile once, then run on a fresh interpreter with a capturing IO.
  //    This is the classic "Hello World!\n" program.
  const hello =
      '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.'
      '+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.';

  final program = parse(hello);
  final helloIO = _MemoryIO(const []);
  Interpreter(io: helloIO).run(program);
  stdout.writeln('hello: ${String.fromCharCodes(helloIO.output)}');

  // 2) Programs that read input can be driven with seeded bytes. `,+.`
  //    reads one byte, bumps it by one, and writes it back out: 'A' -> 'B'.
  final bumpIO = _MemoryIO([65]); // 'A'
  Interpreter.fromSource(',+.', io: bumpIO).run();
  stdout.writeln('bump:  ${String.fromCharCodes(bumpIO.output)}');
}
