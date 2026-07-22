/// Echo harness for io_test.dart: pumps stdin through StdioBrainfuckIO
/// and emits a 0xFF sentinel once read() reports EOF.
library;

import 'package:brainfxxk/brainfxxk.dart';

void main() {
  const io = StdioBrainfuckIO();
  while (true) {
    final byte = io.read();
    if (byte == null) {
      io.write(0xFF);
      return;
    }
    io.write(byte);
  }
}
