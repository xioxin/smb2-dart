
import 'dart:math';

fileTimeToDateTime(int fileTime) {
  return DateTime.fromMillisecondsSinceEpoch(fileTime ~/ 10000 - 11644473600000);
}

BufferToInt(List<int> buffer) {
  var v = 0;
  for (var i = 0; i < buffer.length; i++) {
    v += buffer[i] * pow(2, i * 8);
  }
  return v;
}