/// Compilation of Brainfuck source text into a [Program].
library;

import 'package:brainfxxk/src/exceptions.dart';
import 'package:brainfxxk/src/instruction.dart';

/// Compiles Brainfuck [source] into a [Program].
///
/// Every character that is not one of the 8 instruction characters is
/// treated as a comment and skipped. Brackets are matched with a stack
/// during the scan, producing the jump table up front, so bracket
/// problems are reported here — before any instruction runs.
///
/// Positions are 1-based: the line counts `\n` characters, the column
/// counts UTF-16 code units since the last `\n`.
///
/// ```dart
/// final program = parse('+++[>++<-]');
/// ```
///
/// @param source the Brainfuck source code to compile
/// @return the compiled [Program]: instructions plus bracket jump table
/// @throws [UnclosedBracketException] if the source ends with an
///   unclosed `[`; the position points at the most recently opened one
/// @throws [UnexpectedClosingBracketException] if a `]` has no matching
///   `[`; the position points at that `]`
Program parse(String source) {
  final instructions = <Instruction>[];
  final jumpTable = <int>[];
  final openBrackets = <({int pc, int line, int column})>[];

  var line = 1;
  var column = 1;
  for (var i = 0; i < source.length; i++) {
    final unit = source.codeUnitAt(i);
    final instruction = switch (unit) {
      62 => Instruction.moveRight, // '>'
      60 => Instruction.moveLeft, // '<'
      43 => Instruction.increment, // '+'
      45 => Instruction.decrement, // '-'
      46 => Instruction.output, // '.'
      44 => Instruction.input, // ','
      91 => Instruction.loopStart, // '['
      93 => Instruction.loopEnd, // ']'
      _ => null,
    };

    if (instruction != null) {
      final pc = instructions.length;
      instructions.add(instruction);
      if (instruction == Instruction.loopStart) {
        openBrackets.add((pc: pc, line: line, column: column));
        jumpTable.add(-1); // Patched when the matching ']' is found.
      } else if (instruction == Instruction.loopEnd) {
        if (openBrackets.isEmpty) {
          throw UnexpectedClosingBracketException(
            "unexpected ']'",
            line: line,
            column: column,
          );
        }
        final open = openBrackets.removeLast();
        jumpTable.add(open.pc);
        jumpTable[open.pc] = pc;
      } else {
        jumpTable.add(-1);
      }
    }

    if (unit == 10) {
      // '\n'
      line++;
      column = 1;
    } else {
      column++;
    }
  }

  if (openBrackets.isNotEmpty) {
    final unclosed = openBrackets.last;
    throw UnclosedBracketException(
      "unclosed '['",
      line: unclosed.line,
      column: unclosed.column,
    );
  }

  return Program(instructions, jumpTable);
}
