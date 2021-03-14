import 'dart:async';

import 'package:page/page.dart';

/// Statistics of a page synchronization.
class PageSyncStat {
  /// Number of items in the source only.
  final int? onlySourceCount;

  /// Number of items in the target only.
  final int? onlyTargetCount;

  /// Number of items with matching keys.
  final int? matchingKeyCount;

  /// Number of items that reported synchronized status.
  final int? synchronizedCount;

  PageSyncStat({
    this.onlySourceCount,
    this.onlyTargetCount,
    this.matchingKeyCount,
    this.synchronizedCount,
  });
}

/// Synchronize two pages that are ordered with their keys in ascending order.
Future<PageSyncStat> synchronizePages<T, K extends Comparable<K>>(
  Page<T> source,
  Page<T> target,
  K Function(T item) keyFn, {
  Future<bool> Function(T item)? onlySource,
  Future<bool> Function(T item)? onlyTarget,
  Future<bool> Function(T source, T target)? matched,
}) {
  return synchronizeStreamIterators(
    source.asIterator(),
    target.asIterator(),
    keyFn,
    onlySource: onlySource,
    onlyTarget: onlyTarget,
    matched: matched,
  );
}

/// Synchronize two [StreamIterator]s that are ordered with their keys in
/// ascending order.
Future<PageSyncStat> synchronizeStreamIterators<T, K extends Comparable<K>>(
  StreamIterator<T> source,
  StreamIterator<T> target,
  K Function(T item) keyFn, {
  Future<bool> Function(T item)? onlySource,
  Future<bool> Function(T item)? onlyTarget,
  Future<bool> Function(T source, T target)? matched,
}) async {
  var onlySourceCount = 0;
  var onlyTargetCount = 0;
  var matchingKeyCount = 0;
  var synchronizedCount = 0;

  T? targetItem;
  K? targetKey;
  var hasTarget = true;
  Future moveTarget() async {
    if (hasTarget) {
      if (await target.moveNext()) {
        targetItem = target.current;
        targetKey = keyFn(targetItem!);
      } else {
        targetItem = null;
        targetKey = null;
        hasTarget = false;
      }
    }
  }

  await moveTarget();

  while (await source.moveNext()) {
    final sourceItem = source.current;
    final sourceKey = keyFn(sourceItem);
    while (hasTarget && sourceKey.compareTo(targetKey!) > 0) {
      final s = onlyTarget == null ? null : await onlyTarget(targetItem!);
      onlyTargetCount++;
      if (s == true) {
        synchronizedCount++;
      }
      await moveTarget();
    }
    if (hasTarget && sourceKey.compareTo(targetKey!) == 0) {
      final s = matched == null ? null : await matched(sourceItem, targetItem!);
      matchingKeyCount++;
      if (s == true) {
        synchronizedCount++;
      }
      await moveTarget();
      continue;
    }
    final s = onlySource == null ? null : await onlySource(sourceItem);
    onlySourceCount++;
    if (s == true) {
      synchronizedCount++;
    }
  }
  while (hasTarget) {
    final s = onlyTarget == null ? null : await onlyTarget(targetItem!);
    onlyTargetCount++;
    if (s == true) {
      synchronizedCount++;
    }
    await moveTarget();
  }
  return PageSyncStat(
    onlySourceCount: onlySourceCount,
    onlyTargetCount: onlyTargetCount,
    matchingKeyCount: matchingKeyCount,
    synchronizedCount: synchronizedCount,
  );
}
