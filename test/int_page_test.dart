import 'package:page/page.dart';

import 'package:test/test.dart';

void main() {
  test('streaming', () async {
    final page = new IntPage(0, new List.generate(10, (i) => i), false);
    final list = await page.asStream().toList();
    expect(list, hasLength(40));
    expect(list, new List.generate(40, (i) => i));
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
    return new IntPage(pageNum + 1,
        new List.generate(10, (i) => i + 1 + items.last), pageNum == 2);
  }
}
