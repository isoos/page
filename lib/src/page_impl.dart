part of 'package:page/page.dart';

typedef Future<Page<T>> _NextPageFn<T>();
typedef Future _CloseFn();
typedef FutureOr<List<R>> _MapFn<T, R>(List<T> item);

class _CastPage<T, R> extends Object with PageMixin<R> implements Page<R> {
  @override
  final List<R> items;
  @override
  final bool isLast;
  final _NextPageFn<T> _nextPageFn;
  final _CloseFn _closeFn;
  final _MapFn<T, R> _mapFn;

  _CastPage(
      this.items, this.isLast, this._nextPageFn, this._closeFn, this._mapFn);

  @override
  Future<Page<R>> next() async {
    if (isLast) return null;
    final next = await _nextPageFn();
    return _CastPage(
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
