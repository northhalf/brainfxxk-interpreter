# Changelog

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
