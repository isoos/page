import 'package:page/page.dart';

import 'package:test/test.dart';

void main() {
  test('streaming', () async {
    final page = IntPage(0, List.generate(10, (i) => i), false);
    final list = await page.asStream().toList();
    expect(list, hasLength(40));
    expect(list, List.generate(40, (i) => i));
  });
}

class IntPage extends Object with PageMixin<int> {
  final int pageNum;

  @override
  final List<int> items;

  @override
  final bool isLast;

  IntPage(this.pageNum, this.items, this.isLast);

  @override
  Future close() {
    return null;
  }

  @override
  Future<Page<int>> next() async {
    if (isLast) return null;
    return IntPage(pageNum + 1, List.generate(10, (i) => i + 1 + items.last),
        pageNum == 2);
  }
}
