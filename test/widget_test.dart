import 'package:flutter_test/flutter_test.dart';
import 'package:bazari_8656/main.dart';

void main() {
  testWidgets('App builds and shows Home title', (tester) async {
    await tester.pumpWidget(const BazariApp());
    expect(find.text('Bazari 8656'), findsOneWidget);
  });
}
