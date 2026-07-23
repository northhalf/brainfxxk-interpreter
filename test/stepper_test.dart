import 'dart:math';

import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('Stepper construction', () {
    test('starts at pc 0, not halted, for a non-empty program', () {
      final stepper = Stepper.fromSource('++.', io: _MemoryBrainfuckIO());

      expect(stepper.pc, 0);
      expect(stepper.isHalted, isFalse);
    });

    test('is halted at construction for an empty program', () {
      final stepper = Stepper.fromSource('', io: _MemoryBrainfuckIO());

      expect(stepper.pc, 0);
      expect(stepper.isHalted, isTrue);
    });

    test('fromSource propagates parse exceptions', () {
      expect(
        () => Stepper.fromSource('[', io: _MemoryBrainfuckIO()),
        throwsA(isA<UnclosedBracketException>()),
      );
    });
  });

  group('Stepper.step', () {
    test('executes one instruction per call and advances pc', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource('+>++.', io: io)..step();

      expect(stepper.tape[0], 1);
      expect(stepper.pc, 1);

      stepper.step();
      expect(stepper.tape.pointer, 1);
      expect(stepper.pc, 2);

      stepper
        ..step()
        ..step();
      expect(stepper.tape[1], 2);
      expect(stepper.pc, 4);

      stepper.step();
      expect(io.output, [2]);
      expect(stepper.isHalted, isTrue);
    });

    test('a loop start on a zero cell jumps past the matching bracket', () {
      final stepper = Stepper.fromSource('[+].', io: _MemoryBrainfuckIO())
        ..step();

      expect(stepper.pc, 3);
      expect(stepper.tape[0], 0);
    });

    test('a loop end on a non-zero cell jumps back to the loop body', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource('++[>++<-]>.', io: io);

      var steps = 0;
      while (!stepper.isHalted) {
        stepper.step();
        steps++;
      }

      // Two loop iterations execute six body instructions each, so the
      // eleven-instruction program takes seventeen steps in total.
      expect(steps, 17);
      expect(stepper.tape[0], 0);
      expect(stepper.tape[1], 4);
      expect(io.output, [4]);
    });

    test('input writes the read byte into the current cell', () {
      final io = _MemoryBrainfuckIO([65]);
      final stepper = Stepper.fromSource(',.', io: io)..step();

      expect(stepper.tape[0], 65);
      expect(io.output, isEmpty);

      stepper.step();
      expect(io.output, [65]);
    });

    test('throws at end of input and keeps pc so the read can be retried', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource(',.', io: io);

      expect(
        stepper.step,
        throwsA(isA<BrainfuckRuntimeException>()),
      );
      expect(stepper.pc, 0);

      io.addInput([65]);
      stepper.step();
      expect(stepper.tape[0], 65);
      expect(stepper.pc, 1);
    });

    test('propagates BrainfuckRuntimeException from the tape', () {
      final stepper = Stepper.fromSource('<', io: _MemoryBrainfuckIO());

      expect(
        stepper.step,
        throwsA(isA<BrainfuckRuntimeException>()),
      );
      expect(stepper.pc, 0);
    });

    test('stepping a halted stepper throws StateError', () {
      final stepper = Stepper.fromSource('+', io: _MemoryBrainfuckIO())..step();

      expect(stepper.isHalted, isTrue);
      expect(stepper.step, throwsStateError);
    });
  });

  group('Stepper pc setter', () {
    test('jumps the execution position', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource('+++.', io: io)
        ..pc = 2
        ..step();

      expect(stepper.tape[0], 1);

      stepper.step();
      expect(io.output, [1]);
      expect(stepper.isHalted, isTrue);
    });

    test('accepts the program length, which halts the stepper', () {
      final stepper = Stepper.fromSource('++', io: _MemoryBrainfuckIO())
        ..pc = 2;

      expect(stepper.isHalted, isTrue);
    });

    test('throws RangeError outside 0..program.length', () {
      final stepper = Stepper.fromSource('++', io: _MemoryBrainfuckIO());

      expect(() => stepper.pc = -1, throwsRangeError);
      expect(() => stepper.pc = 3, throwsRangeError);
    });
  });

  group('Stepper.run', () {
    test('runs the remaining instructions to completion', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource('+++.', io: io)..run();

      expect(stepper.isHalted, isTrue);
      expect(io.output, [3]);
    });

    test('interleaves with step()', () {
      final io = _MemoryBrainfuckIO();
      final stepper = Stepper.fromSource('+++.', io: io)
        ..step()
        ..step()
        ..run();

      expect(stepper.isHalted, isTrue);
      expect(io.output, [3]);
    });
  });

  group('Stepper tape sharing', () {
    test('a second stepper continues on the same tape from a pc offset', () {
      final io = _MemoryBrainfuckIO();
      final tape = Tape();

      Stepper(parse('++'), io: io, tape: tape).run();

      // The playground's continuation mechanism: run a newly appended,
      // balanced suffix on the same tape, starting right after the
      // previously executed program.
      final continuation = Stepper(parse('++[>+<-]>.'), io: io, tape: tape)
        ..pc = 2
        ..run();

      expect(continuation.isHalted, isTrue);
      expect(tape[0], 0);
      expect(tape[1], 2);
      expect(io.output, [2]);
    });
  });

  group('Stepper equivalence with Interpreter.run()', () {
    final curated = <String, List<int>>{
      '+++.': [],
      '++[>++[>++<-]<-]>>.': [],
      '+[.+]': [],
      '+[-].': [],
      ',>,+.<.': [64, 1],
      'a+ b. hello world': [],
      '': [],
      '++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.'
              '+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.':
          [],
    };
    for (final MapEntry(key: source, value: input) in curated.entries) {
      test('matches for ${source.isEmpty ? '(empty)' : source}', () {
        _expectSameFinalState(source, input);
      });
    }

    test('matches for random loop-free programs', () {
      final random = Random(42);
      const chars = ['+', '-', '.', ',', '>'];
      final input = List.generate(512, (i) => (i * 7 + 3) % 256);

      for (var n = 0; n < 50; n++) {
        final length = 1 + random.nextInt(60);
        final source = StringBuffer();
        for (var i = 0; i < length; i++) {
          source.write(chars[random.nextInt(chars.length)]);
        }
        _expectSameFinalState(source.toString(), input);
      }
    });
  });
}

/// Runs [source] through both a [Stepper] and an [Interpreter] and
/// compares the final tape contents, pointer, and output.
void _expectSameFinalState(String source, List<int> input) {
  final stepperIo = _MemoryBrainfuckIO(input);
  final stepper = Stepper.fromSource(source, io: stepperIo)..run();

  final interpreterIo = _MemoryBrainfuckIO(input);
  final interpreter = Interpreter.fromSource(source, io: interpreterIo)..run();

  expect(stepper.isHalted, isTrue);
  expect(stepper.tape.pointer, interpreter.tape.pointer);
  expect(stepper.tape.capacity, interpreter.tape.capacity);
  for (var i = 0; i < 128; i++) {
    expect(stepper.tape[i], interpreter.tape[i], reason: 'cell $i');
  }
  expect(stepperIo.output, interpreterIo.output);
}

/// In-memory [BrainfuckIO]: scripted input bytes, captured output.
final class _MemoryBrainfuckIO implements BrainfuckIO {
  _MemoryBrainfuckIO([List<int> input = const []]) : _input = List.of(input);

  final List<int> _input;
  final output = <int>[];

  /// Appends [bytes] to the unread input, as a user feeding more input
  /// after an end-of-input failure would.
  void addInput(List<int> bytes) => _input.addAll(bytes);

  @override
  int? read() => _input.isEmpty ? null : _input.removeAt(0);

  @override
  void write(int byte) => output.add(byte);
}
