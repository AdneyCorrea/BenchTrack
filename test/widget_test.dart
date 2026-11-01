import 'package:benchtrack/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login exige credenciais antes de autenticar', (tester) async {
    var loggedIn = false;
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(onLoggedIn: () => loggedIn = true),
    ));

    final submit = find.widgetWithText(FilledButton, 'Entrar');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
    expect(loggedIn, isFalse);
    expect(tester.takeException(), isNull);
  });
}
