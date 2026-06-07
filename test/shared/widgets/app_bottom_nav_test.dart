import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_place_frontend/shared/widgets/app_bottom_nav.dart';

void main() {
  testWidgets('AppBottomNav shows Search, Chat, and Account', (tester) async {
    var chatTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppBottomNav(
            currentIndex: 0,
            onChatTap: () => chatTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await tester.tap(find.text('Chat'));
    await tester.pump();

    expect(chatTapped, isTrue);
  });
}
