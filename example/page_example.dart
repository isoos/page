import 'package:page/page.dart';

Future<void> main() async {
  final page = await _page(); // There goes a call to the database.

  final iterator = page.asIterator();
  // iterator will request the next page when needed

  while (await iterator.moveNext()) {
    print(iterator.current); // prints current item
  }
}

Future<Page> _page() async => Page.empty();
