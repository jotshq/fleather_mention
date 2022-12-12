import "package:quill_delta/quill_delta.dart";

String deltaStringForRange(Delta d, int start, int end) {
  final it = DeltaIterator(d);
  assert(end >= start);
  var wantedLen = end - start;
  it.skip(start);
  var res = "";
  while (res.length != wantedLen && it.hasNext) {
    final op = it.next(wantedLen - res.length);
    if (!op.isInsert) throw Exception("Bad operation");
    if (!op.isPlain) throw Exception("Bad data type");
    res += op.data as String;
  }
  return res;
}
