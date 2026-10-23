
import 'package:flutter_test/flutter_test.dart';
import 'package:visualmath_ai/main.dart';

void main() {
  testWidgets('VisualMath AI menampilkan halaman beranda', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisualMathApp());

    expect(find.text('VisualMath AI'), findsOneWidget);
    expect(find.text('Halo, Mahasiswa! 👋'), findsOneWidget);
  });

  testWidgets('Navigasi bawah menampilkan halaman latihan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VisualMathApp());

    await tester.tap(find.text('Latihan').last);
    await tester.pumpAndSettle();

    expect(find.text('Latihan Soal'), findsOneWidget);
    expect(
      find.text('Asah kemampuan kalkulusmu sedikit demi sedikit.'),
      findsOneWidget,
    );
  });
}
