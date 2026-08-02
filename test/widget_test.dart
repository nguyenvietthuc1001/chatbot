import 'package:chatbot/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches between login and registration forms', (
    WidgetTester tester,
  ) async {
    var registerMode = false;

    Widget buildPage() {
      return MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return AuthPage(
              isDark: false,
              registerMode: registerMode,
              onToggleTheme: () {},
              onToggleMode: () {
                setState(() => registerMode = !registerMode);
              },
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildPage());

    expect(find.text('\u0110\u0103ng nh\u1eadp'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(
      find.text(
        'Ch\u01b0a c\u00f3 t\u00e0i kho\u1ea3n? \u0110\u0103ng k\u00fd',
      ),
    );
    await tester.pump();

    expect(find.text('T\u1ea1o t\u00e0i kho\u1ea3n'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('X\u00e1c nh\u1eadn m\u1eadt kh\u1ea9u'), findsOneWidget);
  });
}
