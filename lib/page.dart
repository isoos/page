import 'dart:async';

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

typedef Future<Page<T>> _NextPageFn<T>();
typedef Future _CloseFn();
typedef FutureOr<List<R>> _MapFn<T, R>(List<T> item);

class _CastPage<T, R> extends Object with PageMixin<R> implements Page<R> {
  final List<R> items;
  final bool isLast;
  final _NextPageFn<T> _nextPageFn;
  final _CloseFn _closeFn;
  final _MapFn<T, R> _mapFn;

  _CastPage(
      this.items, this.isLast, this._nextPageFn, this._closeFn, this._mapFn);

  Future<Page<R>> next() async {
    if (isLast) return null;
    final next = await _nextPageFn();
    return new _CastPage(
        await _mapFn(next.items), next.isLast, next.next, next.close, _mapFn);
  }

  @override
  Future close() => _closeFn();
}

class _PageStreamIterator<T> implements StreamIterator<T> {
  Page<T> _page;
  int _nextIndex = 0;
  T _current;
  bool _isCancelled = false;

  _PageStreamIterator(Page<T> page) {
    _setPage(page);
  }

  void _setPage(Page<T> page) {
    _page = page;
    _nextIndex = 0;
  }

  @override
  Future cancel() async {
    _isCancelled = true;
    _current = null;
  }

  @override
  T get current => _current;

  @override
  Future<bool> moveNext() async {
    if (_isCancelled) return false;
    if (_nextIndex < _page.items.length) {
      _current = _page.items[_nextIndex++];
      return true;
    }
    if (_page.isLast) {
      return false;
    }
    _setPage(await _page.next());
    return moveNext();
  }
}
