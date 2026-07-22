/// The Brainfuck tape: a dynamically growing line of 8-bit cells.
library;

import 'dart:typed_data';

import 'package:brainfxxk/src/exceptions.dart';

/// A dynamically growing tape of 8-bit wrapping cells.
///
/// The tape starts with a fixed number of zeroed cells (30000 by
/// default; 0 creates an empty tape). Moving the pointer past the right
/// end doubles the capacity, preserving existing contents — an empty
/// tape grows straight to the default 30000 cells; moving it left of
/// cell 0 throws a [BrainfuckRuntimeException]. Every write is stored
/// modulo 256, so `+`/`-` wrap (255 + 1 → 0, 0 - 1 → 255).
final class Tape {
  /// Creates a tape with [initialSize] zeroed cells.
  ///
  /// @param initialSize the starting number of cells, 30000 by default;
  ///   0 creates an empty tape that grows to the default size on its
  ///   first overflow; must not be negative
  /// @throws [ArgumentError] if [initialSize] is negative
  Tape({int initialSize = _defaultInitialSize})
    : _cells = initialSize >= 0
          ? Uint8List(initialSize)
          : throw ArgumentError.value(
              initialSize,
              'initialSize',
              'must not be negative',
            );

  /// The default number of cells, and the capacity an empty tape grows
  /// to on its first overflow.
  static const int _defaultInitialSize = 30000;

  Uint8List _cells;
  int _pointer = 0;

  /// The current position of the tape pointer.
  int get pointer => _pointer;

  /// The current number of cells on the tape.
  ///
  /// Capacity doubles whenever the pointer moves past the right end.
  int get capacity => _cells.length;

  /// A live, read-write view of the tape's cells, [capacity] long.
  ///
  /// The underlying list is replaced when the tape grows, so re-read
  /// this getter after any [moveRight] that crossed the old right end.
  List<int> get cells => _cells;

  /// Reads the cell at [index].
  ///
  /// @param index the cell position, `0 <= index < capacity`
  /// @return the cell's value, 0–255
  /// @throws [RangeError] if [index] is outside the tape
  int operator [](int index) => _cells[index];

  /// Writes [value] to the cell at [index], stored modulo 256.
  ///
  /// @param index the cell position, `0 <= index < capacity`
  /// @param value the value to write
  /// @throws [RangeError] if [index] is outside the tape
  void operator []=(int index, int value) => _cells[index] = value % 256;

  /// Reads the cell under the pointer.
  ///
  /// @return the current cell's value, 0–255
  int read() => _cells[_pointer];

  /// Writes [value] to the cell under the pointer, stored modulo 256.
  ///
  /// @param value the value to write
  void write(int value) => _cells[_pointer] = value % 256;

  /// Increments the cell under the pointer, wrapping 255 + 1 to 0.
  void increment() => _cells[_pointer] = (_cells[_pointer] + 1) % 256;

  /// Decrements the cell under the pointer, wrapping 0 - 1 to 255.
  void decrement() => _cells[_pointer] = (_cells[_pointer] - 1) % 256;

  /// Moves the pointer one cell to the right.
  ///
  /// If the pointer moves past the current right end, the capacity
  /// doubles and the existing contents are copied over; an empty tape
  /// grows to the default 30000 cells instead.
  void moveRight() {
    _pointer++;
    if (_pointer >= _cells.length) {
      final grown = Uint8List(
        _cells.isEmpty ? _defaultInitialSize : _cells.length * 2,
      )..setRange(0, _cells.length, _cells);
      _cells = grown;
    }
  }

  /// Moves the pointer one cell to the left.
  ///
  /// @throws [BrainfuckRuntimeException] if the pointer is at cell 0
  void moveLeft() {
    if (_pointer == 0) {
      throw const BrainfuckRuntimeException(
        'tape pointer moved left of cell 0',
      );
    }
    _pointer--;
  }
}
