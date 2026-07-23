import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('Interpreter', () {
    test('writes the current cell to output', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('+++.', io: io).run();

      expect(io.output, [3]);
    });

    test('runs a loop to compute and print A', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('+++++[>+++++++++++++<-]>.', io: io).run();

      expect(io.output, [65]);
    });

    test('counts down with a loop', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('+++[.-]', io: io).run();

      expect(io.output, [3, 2, 1]);
    });

    test('executes nested loops', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('++[>++[>++<-]<-]>>.', io: io).run();

      expect(io.output, [8]);
    });

    test('skips the loop body when the current cell is zero', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('[+].', io: io).run();

      expect(io.output, [0]);
    });

    test('moves the pointer across cells', () {
      final io = _MemoryBrainfuckIO();

      Interpreter.fromSource('++>+++>++++<<.', io: io).run();

      expect(io.output, [2]);
    });

    test('reads input into the current cell', () {
      final io = _MemoryBrainfuckIO([65]);

      Interpreter.fromSource(',.', io: io).run();

      expect(io.output, [65]);
    });

    test('throws BrainfuckRuntimeException when input hits EOF', () {
      final io = _MemoryBrainfuckIO();
      final interpreter = Interpreter.fromSource('+,.', io: io);

      expect(interpreter.run, throwsA(isA<BrainfuckRuntimeException>()));
      expect(interpreter.tape[0], 1);
    });

    test('exposes its tape for inspection', () {
      final interpreter = Interpreter.fromSource(
        '++.',
        io: _MemoryBrainfuckIO(),
      )..run();

      expect(interpreter.tape[0], 2);
    });

    test('keeps tape state across runs on the same tape', () {
      final tape = Tape();
      Interpreter(tape: tape, io: _MemoryBrainfuckIO())
        ..run(parse('++'))
        ..run(parse('+++'));

      expect(tape[0], 5);
    });

    test('run(program) executes the given program', () {
      final io = _MemoryBrainfuckIO();

      Interpreter(io: io).run(parse('+++.'));

      expect(io.output, [3]);
    });

    test('run() without any program throws StateError', () {
      final interpreter = Interpreter(io: _MemoryBrainfuckIO());

      expect(interpreter.run, throwsStateError);
    });

    test('throws parse exceptions at construction time', () {
      expect(
        () => Interpreter.fromSource('[', io: _MemoryBrainfuckIO()),
        throwsA(isA<UnclosedBracketException>()),
      );
    });

    test('propagates BrainfuckRuntimeException from the tape', () {
      final interpreter = Interpreter.fromSource(
        '<',
        io: _MemoryBrainfuckIO(),
      );

      expect(interpreter.run, throwsA(isA<BrainfuckRuntimeException>()));
    });
  });
}

/// In-memory [BrainfuckIO]: scripted input bytes, captured output.
final class _MemoryBrainfuckIO implements BrainfuckIO {
  _MemoryBrainfuckIO([List<int> input = const []]) : _input = List.of(input);

  final List<int> _input;
  final output = <int>[];

  @override
  int? read() => _input.isEmpty ? null : _input.removeAt(0);

  @override
  void write(int byte) => output.add(byte);
}
