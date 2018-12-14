import 'package:page/page.dart';

main() async {
  final Page page = await null; // There goes a call to the database.

  final iterator = page.asIterator();
  // iterator will request the next page when needed

  while (await iterator.moveNext()) {
    print(iterator.current); // prints current item
  }
}
