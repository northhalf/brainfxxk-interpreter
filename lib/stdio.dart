/// Stdin/stdout-backed IO for command-line apps.
///
/// This entrypoint transitively imports `dart:io`; web apps should
/// depend only on `package:brainfxxk/brainfxxk.dart` and implement
/// `BrainfuckIO` themselves.
library;

export 'src/stdio.dart';
