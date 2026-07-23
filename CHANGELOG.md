# Changelog

## 0.2.0

Web-compilable core plus a single-stepping execution engine, in
preparation for the planned Flutter Web playground.

- **Breaking**: the core entrypoint `package:brainfxxk/brainfxxk.dart`
  is now platform-neutral pure Dart and compiles to the web.
  `StdioBrainfuckIO` moved to `package:brainfxxk/stdio.dart` and `Repl`
  to `package:brainfxxk/repl.dart`; neither is exported from the core
  entry anymore
- **Breaking**: the `Interpreter` constructors' `io` parameter is now
  required — its old default was `StdioBrainfuckIO`, which the pure
  core cannot reference
- **Stepper**: new single-instruction execution engine with `step()`,
  `run()`, `isHalted`, an inspectable `tape`, and a `pc` getter/setter;
  a failed instruction keeps `pc` so it can be retried (e.g. `,` at end
  of input). `Interpreter` is now a batch facade over `Stepper`
- **Parser**: opt-in source mapping — `parse(source,
  recordSourceOffsets: true)` fills the new nullable
  `Program.sourceOffsets` with the UTF-16 offset of each instruction's
  source character, mapping a program counter back to the source text
- **Example**: add `example/stepper_example.dart`, tracing a program
  instruction by instruction and demonstrating a retry after end of
  input

## 0.1.1

- **Example**: add `example/brainfxxk_example.dart`, a runnable Dart
  example that drives the interpreter through `parse()`, `Interpreter`,
  and an in-memory `BrainfuckIO`

## 0.1.0

Initial release of `brainfxxk`, a Brainfuck interpreter library and CLI
written in Dart.

- **Library core**: source is compiled once into an instruction list with
  a precomputed bracket jump table, so loop jumps are O(1) lookups with no
  on-the-fly scanning
- **Tape**: 8-bit wrapping cells (255+1 -> 0, 0-1 -> 255) on a dynamic
  tape that starts at 30000 cells and doubles capacity past the right end;
  moving left of cell 0 throws
- **I/O**: an injectable `BrainfuckIO` abstraction (`int? read()` / `void
  write(int)`) with a stdin/stdout implementation; `,` at EOF throws a
  `BrainfuckRuntimeException`
- **REPL**: brackets may span lines (unclosed brackets continue to a
  `... ` prompt); tape state persists across lines; `q` / `exit` / EOF /
  runtime error ends the session
- **CLI** (`bf`): `bf <file>` / `bf -e '<code>'` / `bf` (REPL); exit codes
  0 success / 1 program error / 64 usage error / 66 file unreadable
- **Errors**: sealed `BrainfuckException` hierarchy; parse errors carry a
  1-based line:column position
- **Examples**: `hello_world.bf`, `echo.bf`, `squares.bf`
