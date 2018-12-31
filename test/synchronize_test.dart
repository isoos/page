import 'dart:async';

import 'package:page/synchronize.dart';

import 'package:test/test.dart';

void main() {
  test('synchronize', () async {
    final source = new StreamIterator<int>(new Stream.fromIterable(
        [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24]));
    final target = new StreamIterator<int>(
        new Stream.fromIterable([3, 6, 9, 12, 15, 18, 21, 24, 27]));

    final onlySources = <int>[];
    final onlyTargets = <int>[];
    final matched = <int>[];
    final stat = await synchronizeStreamIterators<int, num>(
      source,
      target,
      (x) => x,
      onlySource: (x) async {
        onlySources.add(x);
        return true;
      },
      onlyTarget: (x) async {
        onlyTargets.add(x);
      },
      matched: (x, y) async {
        matched.add(x);
        return true;
      },
    );

    expect(onlySources, [0, 2, 4, 8, 10, 14, 16, 20, 22]);
    expect(onlyTargets, [3, 9, 15, 21, 27]);
    expect(matched, [6, 12, 18, 24]);
    expect(stat.onlySourceCount, 9);
    expect(stat.onlyTargetCount, 5);
    expect(stat.matchingKeyCount, 4);
    expect(stat.synchronizedCount, 13);
  });
}
