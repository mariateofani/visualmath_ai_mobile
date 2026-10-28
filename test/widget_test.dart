import 'package:flutter_test/flutter_test.dart';
import 'package:visualmath_ai/main.dart';

void main() {
  testWidgets('Layar login tampil', (tester) async {
    await tester.pumpWidget(const VisualMathApp());
    expect(find.text('Masuk'), findsWidgets);
  });
}
