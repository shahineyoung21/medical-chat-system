import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_chat_system/main.dart';

void main() {
  testWidgets('shows Arabic demo disclaimer and local-only chat',
      (tester) async {
    await tester.pumpWidget(const SabahDemoApp());

    expect(find.text('صباح'), findsOneWidget);
    expect(find.text('نسخة تجريبية'), findsOneWidget);
    expect(find.textContaining('لا تشخيص ولا علاج'), findsOneWidget);
    expect(find.textContaining('لا تُحفظ الرسائل'), findsOneWidget);
  });

  testWidgets('sending a message displays a fixed non-medical demo reply',
      (tester) async {
    await tester.pumpWidget(const SabahDemoApp());

    await tester.enterText(
        find.byKey(const Key('message-field')), 'رسالة اختبارية');
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(find.text('رسالة اختبارية'), findsOneWidget);
    expect(find.textContaining('نموذج العرض المحلي فقط'), findsOneWidget);
    expect(find.textContaining('لا يقدم تشخيصًا أو علاجًا'), findsOneWidget);
  });
}
