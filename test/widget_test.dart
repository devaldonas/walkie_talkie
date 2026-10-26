import 'package:flutter_test/flutter_test.dart';
import 'package:walkie_talkie/main.dart';

void main() {
  testWidgets('App carrega a tela inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const PreparadoRadioApp());
    expect(find.text('Iniciando...'), findsOneWidget);
  });
}
