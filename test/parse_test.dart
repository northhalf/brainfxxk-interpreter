import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('parse', () {
    test('parses every instruction character', () {
      final program = parse('><+-.,[]');

      expect(program.instructions, [
        Instruction.moveRight,
        Instruction.moveLeft,
        Instruction.increment,
        Instruction.decrement,
        Instruction.output,
        Instruction.input,
        Instruction.loopStart,
        Instruction.loopEnd,
      ]);
      expect(program.jumpTable, [-1, -1, -1, -1, -1, -1, 7, 6]);
    });

    test('ignores non-instruction characters as comments', () {
      final program = parse('foo + bar -');

      expect(
        program.instructions,
        [Instruction.increment, Instruction.decrement],
      );
      expect(program.jumpTable, [-1, -1]);
    });

    test('compiles empty source to an empty program', () {
      final program = parse('');

      expect(program.length, 0);
      expect(program.instructions, isEmpty);
      expect(program.jumpTable, isEmpty);
    });

    test('builds a jump table for nested loops', () {
      final program = parse('[+[-]+]');

      expect(program.instructions, [
        Instruction.loopStart,
        Instruction.increment,
        Instruction.loopStart,
        Instruction.decrement,
        Instruction.loopEnd,
        Instruction.increment,
        Instruction.loopEnd,
      ]);
      expect(program.jumpTable, [6, -1, 4, -1, 2, -1, 0]);
    });

    test('throws UnexpectedClosingBracketException for a lone ]', () {
      expect(
        () => parse(']'),
        throwsA(
          isA<UnexpectedClosingBracketException>()
              .having((e) => e.line, 'line', 1)
              .having((e) => e.column, 'column', 1),
        ),
      );
    });

    test('reports the line and column of an unmatched ]', () {
      expect(
        () => parse('ab\ncd]'),
        throwsA(
          isA<UnexpectedClosingBracketException>()
              .having((e) => e.line, 'line', 2)
              .having((e) => e.column, 'column', 3),
        ),
      );
    });

    test('throws UnclosedBracketException for an unclosed [', () {
      expect(
        () => parse('++[>'),
        throwsA(
          isA<UnclosedBracketException>()
              .having((e) => e.line, 'line', 1)
              .having((e) => e.column, 'column', 3),
        ),
      );
    });

    test('points at the most recently opened unclosed [', () {
      expect(
        () => parse('[['),
        throwsA(
          isA<UnclosedBracketException>()
              .having((e) => e.line, 'line', 1)
              .having((e) => e.column, 'column', 2),
        ),
      );
    });

    test('tracks the position of an unclosed [ across lines', () {
      expect(
        () => parse('+\n ['),
        throwsA(
          isA<UnclosedBracketException>()
              .having((e) => e.line, 'line', 2)
              .having((e) => e.column, 'column', 2),
        ),
      );
    });

    test('counts columns in UTF-16 code units', () {
      expect(
        () => parse('😀]'),
        throwsA(
          isA<UnexpectedClosingBracketException>()
              .having((e) => e.line, 'line', 1)
              .having((e) => e.column, 'column', 3),
        ),
      );
    });
  });
}
