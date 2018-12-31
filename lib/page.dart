import 'dart:async';

part 'src/page_impl.dart';

/// Data structure to help paginating (e.g. cursor- or next-token-driven) API
/// calls.
abstract class Page<T> {
  /// The items of the return page, may be less than the requested limit.
  List<T> get items;

  /// Whether this is the last page, or there may be more pages. There is no
  /// guarantee that the next page will contain items.
  bool get isLast;

  /// Returns the next page.
  Future<Page<T>> next();

  /// Closes the page and associated resources.
  Future close();

  /// Transform the page to a stream of items.
  Stream<T> asStream();

  /// Transform the page and returns an iterator that can go through it
  /// asynchronously.
  StreamIterator<T> asIterator();

  /// Maps the type of the items to a different type. The same mapper function
  /// will be called on subsequent pages.
  ///
  /// The implementation will call the [fn] in sequence, eagerly.
  Future<Page<R>> map<R>(FutureOr<R> fn(T item));

  /// Maps the type of the items to a different type. The same mapper function
  /// will be called on subsequent pages.
  Future<Page<R>> mapItems<R>(FutureOr<List<R>> fn(List<T> items));
}

/// [PageMixin] can be used as a mixin to make a class implement the [Page] interface.
abstract class PageMixin<T> implements Page<T> {
  @override
  Stream<T> asStream() async* {
    final iterator = asIterator();
    while (await iterator.moveNext()) {
      yield iterator.current;
    }
  }

  @override
  StreamIterator<T> asIterator() => new _PageStreamIterator(this);

  @override
  Future<Page<R>> map<R>(FutureOr<R> fn(T item)) {
    return mapItems((items) async {
      final list = <R>[];
      for (T item in items) {
        list.add(await fn(item));
      }
      return list;
    });
  }

  @override
  Future<Page<R>> mapItems<R>(FutureOr<List<R>> fn(List<T> items)) async {
    return new _CastPage(await fn(items), isLast, next, close, fn);
  }
}
