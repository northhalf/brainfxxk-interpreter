/// Brainfuck instructions and the compiled form of a program.
///
/// Parsing compiles source text into a [Program]: a flat list of
/// [Instruction]s plus a precomputed bracket jump table, so execution
/// never has to scan for matching brackets at run time.
library;

import 'dart:collection';

/// One of the 8 Brainfuck instructions, named by semantics.
///
/// Non-instruction characters in the source are treated as comments and
/// never reach this enum; parsing maps `>` `<` `+` `-` `.` `,` `[` `]`
/// one-to-one onto these values.
enum Instruction {
  /// `>` — move the tape pointer one cell to the right.
  moveRight,

  /// `<` — move the tape pointer one cell to the left.
  moveLeft,

  /// `+` — increment the current cell, wrapping 255 + 1 to 0.
  increment,

  /// `-` — decrement the current cell, wrapping 0 - 1 to 255.
  decrement,

  /// `.` — write the current cell as one byte of output.
  output,

  /// `,` — read one byte of input into the current cell.
  input,

  /// `[` — jump past the matching `]` if the current cell is 0.
  loopStart,

  /// `]` — jump back to the matching `[` if the current cell is not 0.
  loopEnd,
}

/// The result of parsing Brainfuck source: instructions plus jump table.
///
/// Both lists are exposed as unmodifiable views, so a program cannot be
/// mutated through its public interface and can safely be executed
/// repeatedly, on one shared tape or on fresh ones.
final class Program {
  /// Creates a program from [instructions] and its [jumpTable].
  ///
  /// Both lists are wrapped in an [UnmodifiableListView] — a live view,
  /// not a copy — so callers must not mutate the original lists after
  /// handing them over.
  ///
  /// @param instructions the compiled instructions, in source order
  /// @param jumpTable the bracket jump table, aligned with [instructions]
  /// @param sourceOffsets the UTF-16 source offset of each instruction,
  ///   aligned with [instructions], or null when not recorded
  /// @throws [ArgumentError] if [sourceOffsets] is given but has a
  ///   different length than [instructions]
  Program(
    List<Instruction> instructions,
    List<int> jumpTable, {
    List<int>? sourceOffsets,
  }) : instructions = UnmodifiableListView(instructions),
       jumpTable = UnmodifiableListView(jumpTable),
       sourceOffsets = sourceOffsets == null
           ? null
           : UnmodifiableListView(sourceOffsets) {
    final offsets = this.sourceOffsets;
    if (offsets != null && offsets.length != instructions.length) {
      throw ArgumentError.value(
        offsets.length,
        'sourceOffsets',
        'must have the same length as instructions '
            '(${instructions.length})',
      );
    }
  }

  /// The compiled instructions, in source order.
  final List<Instruction> instructions;

  /// The bracket jump table, aligned index-by-index with [instructions].
  ///
  /// The value is meaningful only at [Instruction.loopStart] and
  /// [Instruction.loopEnd] positions, where it holds the program counter
  /// of the matching bracket; every other position holds -1.
  final List<int> jumpTable;

  /// The UTF-16 offset in the source of each instruction, or null when
  /// the program was parsed without offset recording.
  ///
  /// When present, the list is aligned index-by-index with
  /// [instructions]: `sourceOffsets![i]` is the offset of the source
  /// character that produced `instructions[i]`, so a program counter
  /// can be mapped back to the exact character in the source — e.g. to
  /// highlight the running instruction in an editor. Record offsets
  /// with `parse(source, recordSourceOffsets: true)`.
  final List<int>? sourceOffsets;

  /// The number of instructions in this program.
  int get length => instructions.length;
}
