/// Brainfuck interpreter core library.
///
/// This entrypoint is platform-neutral pure Dart: it compiles to the
/// VM, to native, and to the web. Command-line apps additionally use
/// `package:brainfxxk/stdio.dart` (stdin/stdout IO) and
/// `package:brainfxxk/repl.dart` (interactive REPL).
library;

export 'src/exceptions.dart';
export 'src/instruction.dart';
export 'src/interpreter.dart';
export 'src/io.dart';
export 'src/parse.dart';
export 'src/tape.dart';
