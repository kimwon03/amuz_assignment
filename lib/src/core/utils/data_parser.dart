import 'package:convert/convert.dart';

List<int> toHexList(int value, [int size = 2]) {
    String hexStr = value.toRadixString(16).padLeft(2, '0').padRight(size * 2, '0');

  return hex.decode(hexStr);
}