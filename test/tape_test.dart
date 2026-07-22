import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('Tape', () {
    test('starts at pointer 0 with 30000 zeroed cells', () {
      final tape = Tape();

      expect(tape.pointer, 0);
      expect(tape.capacity, 30000);
      expect(tape.cells.length, 30000);
      expect(tape.read(), 0);
    });

    test('accepts a custom initial size', () {
      final tape = Tape(initialSize: 4);

      expect(tape.capacity, 4);
      expect(tape.cells.length, 4);
    });

    test('rejects a negative initial size', () {
      expect(() => Tape(initialSize: -3), throwsArgumentError);
    });

    test('starts empty when the initial size is 0', () {
      final tape = Tape(initialSize: 0);

      expect(tape.pointer, 0);
      expect(tape.capacity, 0);
      expect(tape.cells, isEmpty);
    });

    test('grows to the default 30000 cells from an empty tape', () {
      final tape = Tape(initialSize: 0)..moveRight();

      expect(tape.pointer, 1);
      expect(tape.capacity, 30000);
      expect(tape.cells.length, 30000);
    });

    test('reads and writes the cell under the pointer', () {
      final tape = Tape(initialSize: 2)..write(65);

      expect(tape.read(), 65);
    });

    test('writes values modulo 256', () {
      final tape = Tape(initialSize: 2)
        ..write(300)
        ..moveRight()
        ..write(-1);

      expect(tape[0], 44);
      expect(tape[1], 255);
    });

    test('increment wraps 255 + 1 to 0', () {
      final tape = Tape(initialSize: 2)
        ..write(255)
        ..increment();

      expect(tape.read(), 0);
    });

    test('decrement wraps 0 - 1 to 255', () {
      final tape = Tape(initialSize: 2)..decrement();

      expect(tape.read(), 255);
    });

    test('moves the pointer right and left', () {
      final tape = Tape(initialSize: 4)
        ..moveRight()
        ..moveRight()
        ..moveLeft();

      expect(tape.pointer, 1);
    });

    test('moving right past the end doubles capacity, keeping contents', () {
      final tape = Tape(initialSize: 2)
        ..write(7)
        ..moveRight()
        ..moveRight();

      expect(tape.pointer, 2);
      expect(tape.capacity, 4);
      expect(tape.cells.length, 4);
      expect(tape[0], 7);
    });

    test('moving left of cell 0 throws BrainfuckRuntimeException', () {
      final tape = Tape(initialSize: 2);

      expect(tape.moveLeft, throwsA(isA<BrainfuckRuntimeException>()));
      expect(tape.pointer, 0);
    });

    test('indexes arbitrary cells, writing modulo 256', () {
      final tape = Tape(initialSize: 4);
      tape[1] = 300;

      expect(tape[1], 44);
    });

    test('indexing outside the tape throws RangeError', () {
      final tape = Tape(initialSize: 2);

      expect(() => tape[-1], throwsRangeError);
      expect(() => tape[2], throwsRangeError);
      expect(() => tape[-1] = 1, throwsRangeError);
      expect(() => tape[2] = 1, throwsRangeError);
    });

    test('cells is a live read-write view of the tape', () {
      final tape = Tape(initialSize: 4);
      tape.cells[2] = 9;

      expect(tape[2], 9);
      tape[3] = 8;
      expect(tape.cells[3], 8);
    });
  });
}
