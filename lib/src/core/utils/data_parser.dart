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

List<String> hexStringTohexList(String hexString) {
  List<String> convertList = [];

  for (int i = 0; i < hexString.length; i += 2) {
    String splitText = hexString.substring(i, i + 2);

    convertList.add(splitText);
  }

  return convertList;
}

List<int> hexListToIntList(List<String> hexList) {
  return hexList.map((e) => int.parse(e, radix: 16)).toList();
}

int hexListToInt(List<String> hexList) {
  String hex = hexList.join();

  return int.parse(hex, radix: 16);
}