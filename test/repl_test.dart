import 'dart:convert';
import 'dart:io';

import 'package:brainfxxk/brainfxxk.dart';
import 'package:test/test.dart';

void main() {
  group('Repl', () {
    test('executes each complete line as a program', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['+++.', '>++.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, [3, 2]);
      expect(out.toString(), 'bf> bf> bf> ');
    });

    test('preserves tape state across lines', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['++', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, [5]);
    });

    test('buffers lines until brackets balance', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['++[>++', '<-]>.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, [4]);
      expect(out.toString(), 'bf> ... bf> ');
    });

    test('quits on q without executing further lines', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['q', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, isEmpty);
      expect(out.toString(), 'bf> ');
    });

    test('quits on exit', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['exit', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, isEmpty);
    });

    test('quits on q while in continuation mode', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['[', 'q', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(io.output, isEmpty);
      expect(out.toString(), 'bf> ... ');
    });

    test('quits on q surrounded by whitespace', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['  q  ']),
        io: io,
        out: out,
      ).run();

      expect(io.output, isEmpty);
      expect(out.toString(), 'bf> ');
    });

    test('ends the session when the line stream ends', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: const Stream<String>.empty(),
        io: io,
        out: out,
      ).run();

      expect(io.output, isEmpty);
      expect(out.toString(), 'bf> ');
    });

    test('prints an unexpected closing bracket and recovers', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable([']', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(out.toString(), contains('UnexpectedClosingBracketException'));
      expect(io.output, [3]);
    });

    test('ends the session on a runtime error', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable(['<', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(out.toString(), contains('BrainfuckRuntimeException'));
      expect(io.output, isEmpty);
    });

    test('ends the session when input reads EOF', () async {
      final io = _MemoryBrainfuckIO();
      final out = StringBuffer();

      await Repl(
        lines: Stream.fromIterable([',', '+++.']),
        io: io,
        out: out,
      ).run();

      expect(out.toString(), contains('end of input'));
      expect(io.output, isEmpty);
    });
  });
  group('Repl.stdio', () {
    test('wires stdin lines and stdio IO into the session', () async {
      final process = await Process.start(
        Platform.resolvedExecutable,
        ['test/stdio_repl_harness.dart'],
      );
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      process.stdin
        ..writeln('++[>++')
        ..writeln('<-]>.')
        ..writeln('q');
      await process.stdin.close();

      final output = await process.stdout.fold<List<int>>(
        [],
        (bytes, chunk) => bytes..addAll(chunk),
      );

      expect(await process.exitCode, 0, reason: await stderrFuture);
      expect(output, [...'bf> ... '.codeUnits, 4, ...'bf> '.codeUnits]);
    });
  });
}

/// In-memory [BrainfuckIO]: scripted input bytes, captured output.
final class _MemoryBrainfuckIO implements BrainfuckIO {
  _MemoryBrainfuckIO([List<int> input = const []]) : _input = List.of(input);

  final List<int> _input;
  final output = <int>[];

  @override
  int? read() => _input.isEmpty ? null : _input.removeAt(0);

  @override
  void write(int byte) => output.add(byte);
}
