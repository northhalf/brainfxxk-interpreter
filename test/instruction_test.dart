import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('Instruction', () {
    test('declares exactly the 8 Brainfuck instructions in spec order', () {
      expect(
        Instruction.values.map((instruction) => instruction.name).toList(),
        [
          'moveRight',
          'moveLeft',
          'increment',
          'decrement',
          'output',
          'input',
          'loopStart',
          'loopEnd',
        ],
      );
    });
  });

  group('Program', () {
    test('exposes the instruction list and jump table it was built with', () {
      final program = Program(
        [Instruction.loopStart, Instruction.increment, Instruction.loopEnd],
        [2, -1, 0],
      );

      expect(
        program.instructions,
        [Instruction.loopStart, Instruction.increment, Instruction.loopEnd],
      );
      expect(program.jumpTable, [2, -1, 0]);
    });

    test('length is the number of instructions', () {
      final program = Program(
        [Instruction.increment, Instruction.decrement],
        [-1, -1],
      );

      expect(program.length, 2);
    });

    test('length is 0 for an empty program', () {
      final program = Program(<Instruction>[], <int>[]);

      expect(program.length, 0);
    });

    test('instructions cannot be mutated through the program', () {
      final program = Program([Instruction.increment], [-1]);

      expect(
        () => program.instructions.add(Instruction.decrement),
        throwsUnsupportedError,
      );
      expect(
        () => program.instructions[0] = Instruction.decrement,
        throwsUnsupportedError,
      );
    });

    test('jumpTable cannot be mutated through the program', () {
      final program = Program([Instruction.loopStart], [0]);

      expect(() => program.jumpTable[0] = 1, throwsUnsupportedError);
    });
  });
}
