import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const SabahDemoApp());
}

class SabahDemoApp extends StatelessWidget {
  const SabahDemoApp({super.key});

  static const _teal = Color(0xFF176B66);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صباح — نسخة تجريبية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F8F7),
          foregroundColor: Color(0xFF17312F),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(height: 1.5),
          bodyMedium: TextStyle(height: 1.5),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'مرحبًا، أنا صباح — واجهة تجريبية للمحادثة. لا أقدم تشخيصًا أو علاجًا، ولا أتصل بطبيب أو قاعدة بيانات. رجاءً لا تكتب بيانات شخصية أو صحية حقيقية هنا.',
      isUser: false,
    ),
  ];

  static const _demoReply =
      'وصلت رسالتك إلى نموذج العرض المحلي فقط. هذا التطبيق لا يحلل الأعراض، ولا يقدم تشخيصًا أو علاجًا أو توصية دوائية، ولا يرسل المحادثة إلى أي خدمة. للمعلومات الصحية تواصل مع مختص مؤهل، وللطوارئ تواصل مع خدمات الطوارئ المحلية.';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages
        ..add(_ChatMessage(text: text, isUser: true))
        ..add(const _ChatMessage(text: _demoReply, isUser: false));
      _controller.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chat-screen'),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Row(
          children: [
            _BrandMark(),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'صباح',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  'محادثة تجريبية محلية',
                  style: TextStyle(fontSize: 12, color: Color(0xFF647773)),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: _DemoBadge(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _SafetyNotice(),
            Expanded(
              child: ListView.builder(
                key: const Key('message-list'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _MessageBubble(
                  message: _messages[index],
                ),
              ),
            ),
            _MessageComposer(
              controller: _controller,
              onSend: _sendMessage,
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, top: 2),
              child: Text(
                'لا تُحفظ الرسائل بعد إغلاق التطبيق',
                style: TextStyle(fontSize: 11, color: Color(0xFF71817D)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF176B66),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.health_and_safety_outlined,
        color: Colors.white,
        size: 25,
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'نسخة تجريبية',
        style: TextStyle(
          color: Color(0xFF145C55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5DF),
        border: Border.all(color: const Color(0xFFEED69D)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF8B6415), size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'نموذج واجهة فقط — لا تشخيص ولا علاج. لا تُدخل معلومات شخصية أو صحية حقيقية.',
              style: TextStyle(
                color: Color(0xFF634C1F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.84,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFFDCEFEB) : Colors.white,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(18),
              topEnd: const Radius.circular(18),
              bottomStart: Radius.circular(isUser ? 18 : 5),
              bottomEnd: Radius.circular(isUser ? 5 : 18),
            ),
            border: Border.all(
              color: isUser ? const Color(0xFFC9E4DE) : const Color(0xFFE5ECE9),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF223532)),
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const Key('message-field'),
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'اكتب رسالة تجريبية…',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDCE6E2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: Color(0xFFDCE6E2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: SabahDemoApp._teal,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const Key('send-message'),
            tooltip: 'إرسال الرسالة',
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(
              backgroundColor: SabahDemoApp._teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
            ),
          ),
        ],
      ),
    );
  }
}
