/// REPL harness for repl_test.dart: runs a Repl wired to stdio.
library;

import 'package:brainfxxk/repl.dart';

Future<void> main() => Repl.stdio().run();
