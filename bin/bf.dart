/// CLI entry point: `bf <file>` / `bf -e '<code>'` / `bf` (REPL).
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:brainfxxk/brainfxxk.dart';

/// Runs the `bf` command: file mode, `-e` eval mode, or the REPL.
///
/// Exit codes: 0 success, 1 program error (parse or runtime),
/// 64 usage error, 66 file not found or unreadable.
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'eval',
      abbr: 'e',
      help: 'Execute the given Brainfuck source string.',
      valueHelp: 'code',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    );

  final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException catch (e) {
    _usageError(parser, e.message);
    return;
  }

  if (results.flag('help')) {
    stdout.writeln(_usage(parser));
    return;
  }

  final eval = results.option('eval');
  final rest = results.rest;

  if (eval != null) {
    if (rest.isNotEmpty) {
      _usageError(parser, 'pass either a file or -e, not both.');
    } else {
      _runSource(eval);
    }
  } else if (rest.length == 1) {
    await _runFile(rest.single);
  } else if (rest.isEmpty) {
    await Repl.stdio().run();
  } else {
    _usageError(parser, 'pass at most one file.');
  }
}

String _usage(ArgParser parser) =>
    'Usage: bf [<file.bf> | -e <code>]   (no arguments starts the REPL)\n'
    '${parser.usage}';

void _usageError(ArgParser parser, String message) {
  stderr
    ..writeln('bf: $message')
    ..writeln(_usage(parser));
  exitCode = 64;
}

Future<void> _runFile(String path) async {
  final String source;
  try {
    source = await File(path).readAsString();
  } on FileSystemException {
    stderr.writeln('bf: cannot read file: $path');
    exitCode = 66;
    return;
  } on FormatException {
    stderr.writeln('bf: not a UTF-8 text file: $path');
    exitCode = 66;
    return;
  }
  _runSource(source);
}

void _runSource(String source) {
  try {
    Interpreter.fromSource(source).run();
  } on BrainfuckException catch (e) {
    stderr.writeln('bf: $e');
    exitCode = 1;
  }
}
