# brainfxxk

English | [中文](README_zh.md)

A Brainfuck interpreter written in Dart: **a reusable library core with a CLI front end**.

> ✨ v0.1.0 - the library, REPL, and CLI are all implemented.

## Features

- **Pre-compilation + jump table**: source is compiled once into an instruction
  list; bracket jumps are O(1) table lookups with no on-the-fly scanning
- **Parse-time errors**: unmatched brackets are reported before any instruction
  runs, with line:column position
- **Dynamic tape**: starts at 30,000 cells and doubles capacity when the pointer
  moves past the right end
- **Injectable I/O**: the `BrainfuckIO` abstraction allows in-memory I/O in tests
  and stdin/stdout in the CLI
- **REPL**: brackets may span multiple lines (unclosed brackets continue to a
  next-line prompt); tape state persists across lines

## Semantics (BF dialect)

Brainfuck implementations differ widely in the details. This implementation:

| Aspect | Behavior |
|---|---|
| Cell | 8-bit (0–255); `+`/`-` wrap on overflow (255+1→0, 0-1→255) |
| Tape | Grows dynamically to the right; moving the pointer left of 0 throws `BrainfuckRuntimeException` |
| EOF | `,` at EOF throws `BrainfuckRuntimeException` |
| Brackets | Unmatched brackets throw `UnclosedBracketException` / `UnexpectedClosingBracketException` at parse time |

## Requirements

- Dart SDK `^3.12.2`

```bash
dart pub get
```

## CLI Usage

```bash
# Run a file
dart run bin/bf.dart example/hello_world.bf

# Run a code string directly
dart run bin/bf.dart -e '+++++[>+++++++++++++<-]>.'   # prints A

# Start the REPL (no arguments)
dart run bin/bf.dart
```

REPL example — brackets may span lines; an unclosed `[` continues to a
next-line prompt instead of erroring:

```
bf> >> [>><
... ]
bf> q
```

Quit the REPL with `q`, `exit`, or EOF (Ctrl-D). A runtime error —
including `,` at end of input — prints an error and ends the session.

Or activate globally to use the `bf` command directly:

```bash
dart pub global activate --source path .
bf example/hello_world.bf
```

Exit codes: 0 success / 1 runtime error / 64 usage error / 66 file not found or unreadable.

## Library Usage

```dart
import 'package:brainfxxk/brainfxxk.dart';

void main() {
  // Option 1: build from a source string and run
  Interpreter.fromSource('+++++[>+++++++++++++<-]>.').run(); // prints A

  // Option 2: parse into a Program first, then run; tape is inspectable
  final program = parse('+++++[>+++++++++++++<-]>.');
  final interpreter = Interpreter();
  interpreter.run(program);
  print(interpreter.tape[1]); // 65
}
```

Parsing and execution are separate: a `Program` can be run repeatedly, and
passing the same `Tape` to an `Interpreter` preserves tape state across
multiple `run()` calls (the REPL is built on this).

Error handling: `UnclosedBracketException` / `UnexpectedClosingBracketException`
(with line:column) at parse time; `BrainfuckRuntimeException` at run time.

## Project Structure

```
brainfxxk-interpreter/
├── bin/
│   └── bf.dart               # CLI entry: file / -e / REPL modes
├── lib/
│   ├── brainfxxk.dart        # library entry, exports the public API
│   └── src/
│       ├── instruction.dart  # Instruction enum + Program (instructions + jump table)
│       ├── parse.dart        # source -> Program, bracket matching
│       ├── tape.dart         # dynamic tape, 8-bit wrapping cells
│       ├── interpreter.dart  # execution engine
│       ├── io.dart           # BrainfuckIO abstraction + stdin/stdout impl
│       ├── repl.dart         # REPL: bracket buffering, continuation, q/exit/EOF to quit
│       └── exceptions.dart   # parse/runtime exceptions with positions
├── example/
│   ├── hello_world.bf
│   ├── echo.bf
│   └── squares.bf
└── test/
    ├── instruction_test.dart
    ├── io_test.dart
    ├── parse_test.dart
    ├── tape_test.dart
    ├── interpreter_test.dart
    ├── repl_test.dart
    └── e2e/
        └── cli_e2e_test.dart # runs example/ programs and compares expected output
```

## Development

```bash
dart analyze        # lint (very_good_analysis, strict)
dart format .       # format
dart test           # all tests
dart test -n "name" # a single test by name
```
