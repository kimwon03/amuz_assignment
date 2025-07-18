import 'package:convert/convert.dart';

List<int> toHexList(int value, [int size = 2]) {
  String hexStr = value
      .toRadixString(16)
      .padLeft(2, '0')
      .padRight(size * 2, '0');

  return hex.decode(hexStr);
}

int generateCrc8Bit(List<int> data) {
  int sum = 0;

  for (final int value in data) {
    sum += value;
  }

  return (sum ^ 0x55) % 256;
}

String listToHexString(List<int> data) {
  return data
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();
}
