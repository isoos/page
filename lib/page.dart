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
  Future<void> close();

  /// Transform the page to a stream of items.
  Stream<T> asStream();

  /// Transform the page and returns an iterator that can go through it
  /// asynchronously.
  StreamIterator<T> asIterator();

  /// Maps the type of the items to a different type. The same mapper function
  /// will be called on subsequent pages.
  ///
  /// The implementation will call the [fn] in sequence, eagerly.
  Future<Page<R>> map<R>(FutureOr<R> Function(T item) fn);

  /// Maps the type of the items to a different type. The same mapper function
  /// will be called on subsequent pages.
  Future<Page<R>> mapItems<R>(FutureOr<List<R>> Function(List<T> items) fn);

  factory Page.empty() => _EmptyPage<T>();
  factory Page.from(Iterable<T> items) =>
      _Page(items is List<T> ? items : items.toList());
}

/// [PageMixin] can be used as a mixin to make a class implement the [Page] interface.
mixin PageMixin<T> implements Page<T> {
  @override
  Stream<T> asStream() async* {
    final iterator = asIterator();
    while (await iterator.moveNext()) {
      yield iterator.current!;
    }
  }

  @override
  StreamIterator<T> asIterator() => _PageStreamIterator(this);

  @override
  Future<Page<R>> map<R>(FutureOr<R> Function(T item) fn) {
    return mapItems((items) async {
      final list = <R>[];
      for (final item in items) {
        list.add(await fn(item));
      }
      return list;
    });
  }

  @override
  Future<Page<R>> mapItems<R>(
      FutureOr<List<R>> Function(List<T> items) fn) async {
    return _CastPage(await fn(items), isLast, next, close, fn);
  }
}

class _EmptyPage<T> extends Object with PageMixin<T> {
  @override
  Future<void> close() async {}

  @override
  final isLast = true;

  @override
  final List<T> items = <T>[];

  @override
  Future<Page<T>> next() async => this;
}

class _Page<T> extends Object with PageMixin<T> {
  @override
  final List<T> items;

  _Page(this.items);

  @override
  Future<void> close() async {}

  @override
  final isLast = true;

  @override
  Future<Page<T>> next() async => Page<T>.empty();
}
