import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medical_chat_system/chat_api.dart';
import 'package:medical_chat_system/main.dart';

void main() {
  testWidgets('shows Arabic health-information disclaimer and session controls',
      (tester) async {
    await tester.pumpWidget(const SabahDemoApp());

    expect(find.text('صباح'), findsOneWidget);
    expect(find.text('اختبارية'), findsOneWidget);
    expect(find.textContaining('ليست تشخيصًا أو علاجًا'), findsOneWidget);
    expect(find.textContaining('لا تكتب بيانات شخصية'), findsWidgets);
    expect(find.textContaining('لا تُحفظ الرسائل'), findsOneWidget);
    expect(find.byKey(const Key('finish-session')), findsOneWidget);
  });

  testWidgets('sends a general question and displays its source',
      (tester) async {
    final service = FakeChatService(
      const ChatReply(
        answer: 'ملخص عربي عام من المصدر، وليس تشخيصًا.',
        sources: [
          ChatSource(
            title: 'Asthma — MedlinePlus',
            url: 'https://medlineplus.gov/asthma.html',
            publisher: 'NLM',
          ),
        ],
      ),
    );
    await tester.pumpWidget(SabahDemoApp(chatService: service));

    await tester.enterText(
      find.byKey(const Key('message-field')),
      'ما هو الربو؟',
    );
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(service.sentMessages, ['ما هو الربو؟']);
    expect(find.text('ما هو الربو؟'), findsOneWidget);
    expect(find.textContaining('ملخص عربي عام'), findsOneWidget);
    expect(find.textContaining('https://medlineplus.gov/asthma.html'),
        findsOneWidget);
  });

  testWidgets(
      'does not send a personal symptom and reminds user at session end',
      (tester) async {
    final service = FakeChatService(
      const ChatReply(answer: 'لا ينبغي الوصول إليه'),
    );
    await tester.pumpWidget(SabahDemoApp(chatService: service));

    await tester.enterText(
      find.byKey(const Key('message-field')),
      'عندي صداع',
    );
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(service.sentMessages, isEmpty);
    expect(find.textContaining('طبيب أو مختص'), findsOneWidget);

    await tester.tap(find.byKey(const Key('finish-session')));
    await tester.pumpAndSettle();

    expect(find.text('تذكير صحي مهم'), findsOneWidget);
    expect(find.textContaining('يجب مراجعة طبيب'), findsOneWidget);
  });

  testWidgets('emergency wording shows Egypt ambulance number immediately',
      (tester) async {
    final service = FakeChatService(
      const ChatReply(answer: 'لا ينبغي الوصول إليه'),
    );
    await tester.pumpWidget(SabahDemoApp(chatService: service));

    await tester.enterText(
      find.byKey(const Key('message-field')),
      'عندي ألم شديد في الصدر',
    );
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(service.sentMessages, isEmpty);
    expect(find.textContaining('123'), findsAtLeastNWidgets(1));
    expect(find.textContaining('eao.gov.eg'), findsOneWidget);
  });

  testWidgets('ending an ordinary session does not claim medical clearance',
      (tester) async {
    await tester.pumpWidget(const SabahDemoApp());
    await tester.tap(find.byKey(const Key('finish-session')));
    await tester.pumpAndSettle();

    expect(find.textContaining('لا يثبت خلوّك'), findsOneWidget);
  });

  testWidgets('personal disease statement is intercepted before networking',
      (tester) async {
    final service = FakeChatService(
      const ChatReply(answer: 'لا ينبغي الوصول إليه'),
    );
    await tester.pumpWidget(SabahDemoApp(chatService: service));

    await tester.enterText(
      find.byKey(const Key('message-field')),
      'عندي ربو',
    );
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(service.sentMessages, isEmpty);
    await tester.tap(find.byKey(const Key('finish-session')));
    await tester.pumpAndSettle();
    expect(find.text('تذكير صحي مهم'), findsOneWidget);
  });
}
