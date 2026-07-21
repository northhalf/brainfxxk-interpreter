/// Exception hierarchy for the brainfxxk interpreter.
///
/// Every error raised by the library is a [BrainfuckException]: either a
/// [BrainfuckParseException] raised while compiling source into a program,
/// or a [BrainfuckRuntimeException] raised while executing one.
library;

/// Base type of every error raised by the brainfxxk interpreter.
///
/// This type is `sealed`: it cannot be instantiated directly, and all of
/// its subtypes live in this library, so callers can switch over them
/// exhaustively.
sealed class BrainfuckException implements Exception {
  /// Creates an exception with the given human-readable [message].
  const BrainfuckException(this.message);

  /// A human-readable description of what went wrong.
  final String message;

  @override
  String toString() => 'BrainfuckException: $message';
}

/// An error raised while parsing Brainfuck source code.
///
/// Carries the 1-based [line] and [column] of the offending character so
/// callers can point the user at the exact location of the problem.
///
/// [line] counts `\n` characters (plus one). [column] counts UTF-16 code
/// units since the last `\n` (plus one): ASCII text — including every
/// Brainfuck instruction — counts one column per character/byte.
base class BrainfuckParseException extends BrainfuckException {
  /// Creates a parse exception for [message] at [line]:[column].
  ///
  /// @param message a human-readable description of the problem
  /// @param line the 1-based line of the offending character, counted by `\n`
  /// @param column the 1-based column of the offending character, in UTF-16
  ///   code units
  const BrainfuckParseException(
    super.message, {
    required this.line,
    required this.column,
  });

  /// The 1-based line of the offending character, counted by `\n`.
  final int line;

  /// The 1-based column of the offending character, in UTF-16 code units.
  final int column;

  @override
  String toString() =>
      'BrainfuckParseException: $message (line $line, column $column)';
}

/// Raised when the source ends with a `[` that is never closed.
///
/// The position points at the unclosed `[`. The REPL catches this
/// exception to keep reading more lines instead of failing, which is what
/// allows brackets to span multiple input lines.
final class UnclosedBracketException extends BrainfuckParseException {
  /// Creates an exception for an unclosed `[` at [line]:[column].
  ///
  /// @param message a human-readable description of the problem
  /// @param line the 1-based line of the unclosed `[`
  /// @param column the 1-based column of the unclosed `[`
  const UnclosedBracketException(
    super.message, {
    required super.line,
    required super.column,
  });

  @override
  String toString() =>
      'UnclosedBracketException: $message (line $line, column $column)';
}

/// Raised when a `]` appears without a matching `[`.
///
/// The position points at the unmatched `]`. Unlike an unclosed `[`, this
/// can never be fixed by reading more input, so it is always a hard error.
final class UnexpectedClosingBracketException extends BrainfuckParseException {
  /// Creates an exception for an unmatched `]` at [line]:[column].
  ///
  /// @param message a human-readable description of the problem
  /// @param line the 1-based line of the unmatched `]`
  /// @param column the 1-based column of the unmatched `]`
  const UnexpectedClosingBracketException(
    super.message, {
    required super.line,
    required super.column,
  });

  @override
  String toString() =>
      'UnexpectedClosingBracketException: $message '
      '(line $line, column $column)';
}

/// An error raised while executing a Brainfuck program.
///
/// Currently the only runtime failure is moving the tape pointer left of
/// cell 0.
final class BrainfuckRuntimeException extends BrainfuckException {
  /// Creates a runtime exception with the given human-readable [message].
  const BrainfuckRuntimeException(super.message);

  @override
  String toString() => 'BrainfuckRuntimeException: $message';
}
