import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat_api.dart';
import 'safety_rules.dart';

const _egyptianResources = <ChatSource>[
  ChatSource(
    title: 'وزارة الصحة والسكان',
    url: 'https://www.mohp.gov.eg/',
    publisher: 'وزارة الصحة والسكان المصرية',
  ),
  ChatSource(
    title: 'الإسعاف المصري 123',
    url: 'https://eao.gov.eg/',
    publisher: 'هيئة الإسعاف المصرية',
  ),
  ChatSource(
    title: 'مستشفيات جامعة القاهرة',
    url:
        'https://cu.edu.eg/page.php?pg=contentFront/SubSectionData.php&SubSectionId=199',
    publisher: 'جامعة القاهرة',
  ),
  ChatSource(
    title: 'الخدمات الصحية — جامعة عين شمس',
    url: 'https://www.asu.edu.eg/healthcare',
    publisher: 'جامعة عين شمس',
  ),
];

void main() {
  runApp(const SabahDemoApp());
}

class SabahDemoApp extends StatelessWidget {
  const SabahDemoApp({super.key, this.chatService});

  static const _teal = Color(0xFF176B66);
  final ChatService? chatService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'صباح — معلومات صحية عامة',
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
      home: ChatScreen(chatService: chatService),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.chatService});

  final ChatService? chatService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatService _chatService;
  bool _ownsChatService = false;
  bool _isSending = false;
  bool _sessionHasConcern = false;
  bool _sessionHasEmergency = false;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'أهلًا، أنا صباح. أقدّم معلومات عامة من مصادر موثوقة فقط، ولا أشخّص أو أصف علاجًا. لا تكتب بيانات شخصية أو أعراضًا حقيقية في هذه النسخة.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.chatService != null) {
      _chatService = widget.chatService!;
    } else {
      _chatService = HttpChatService();
      _ownsChatService = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    if (_ownsChatService && _chatService is HttpChatService) {
      _chatService.close();
    }
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final localSafety = SafetyRules.classify(text);
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _sessionHasConcern = _sessionHasConcern || localSafety.concern;
      _sessionHasEmergency = _sessionHasEmergency || localSafety.emergency;
    });

    if (localSafety.concern) {
      final reply = localSafety.emergency
          ? const _ChatMessage(
              text:
                  'إذا كانت الحالة تحدث الآن، اتصل بالإسعاف المصري على 123 أو توجّه إلى أقرب طوارئ فورًا. لا أستطيع تقييم الأعراض أو تشخيص سببها.',
              isUser: false,
              sources: [
                ChatSource(
                  title: 'هيئة الإسعاف المصرية — 123',
                  url: 'https://eao.gov.eg/',
                  publisher: 'هيئة الإسعاف المصرية',
                ),
              ],
            )
          : const _ChatMessage(
              text:
                  'لا أستطيع تقييم شكوى شخصية أو تأكيد وجود مرض أو اقتراح علاج. يُرجى مناقشة الأعراض مع طبيب أو مختص صحي مؤهل. إذا أصبحت الحالة طارئة، اتصل بالإسعاف المصري على 123.',
              isUser: false,
              sources: [
                ChatSource(
                  title: 'هيئة الإسعاف المصرية — 123',
                  url: 'https://eao.gov.eg/',
                  publisher: 'هيئة الإسعاف المصرية',
                ),
              ],
            );
      setState(() => _messages.add(reply));
      _scrollToBottom();
      return;
    }

    setState(() => _isSending = true);
    _scrollToBottom();
    try {
      final reply = await _chatService.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            text: reply.answer,
            isUser: false,
            sources: reply.sources,
          ),
        );
        _sessionHasConcern = _sessionHasConcern || reply.concernDetected;
        _sessionHasEmergency = _sessionHasEmergency || reply.emergency;
        _isSending = false;
      });
    } on ChatApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: error.message, isUser: false));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: 'تعذّر الاتصال بالخادم الآن. لن أقدّم إجابة غير موثقة.',
            isUser: false,
          ),
        );
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSource(String value) async {
    final uri = Uri.tryParse(value);
    const trustedDomains = <String>[
      'medlineplus.gov',
      'mohp.gov.eg',
      'eao.gov.eg',
      'cu.edu.eg',
      'asu.edu.eg',
    ];
    final host = uri?.host.toLowerCase() ?? '';
    final trusted = trustedDomains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
    if (uri == null || uri.scheme != 'https' || !trusted) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر فتح المصدر على هذا الجهاز.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المصدر على هذا الجهاز.')),
      );
    }
  }

  Future<void> _finishSession() async {
    final hasConcern = _sessionHasConcern;
    final hasEmergency = _sessionHasEmergency;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('session-end-dialog'),
        title: Text(hasConcern ? 'تذكير صحي مهم' : 'إنهاء الجلسة'),
        content: Text(
          hasConcern
              ? 'ذكرتَ شكوى أو طلبتَ تقييمًا صحيًا في هذه الجلسة. يجب مراجعة طبيب أو مختص صحي مؤهل؛ صباح لا يشخّص ولا يعالج.'
                  '${hasEmergency ? ' إذا كانت الحالة طارئة الآن، اتصل بالإسعاف المصري على 123.' : ''}'
              : 'انتهت الجلسة. لم تُفعّل قواعد التنبيه المحلية، لكن ذلك لا يثبت خلوّك من مشكلة صحية. هذه المحادثة ليست بديلًا عن الطبيب.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('العودة للمحادثة'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _messages
                  ..clear()
                  ..add(
                    const _ChatMessage(
                      text:
                          'بدأت جلسة جديدة. أقدّم معلومات عامة فقط؛ لا تكتب بيانات شخصية أو أعراضًا حقيقية في هذه النسخة.',
                      isUser: false,
                    ),
                  );
                _sessionHasConcern = false;
                _sessionHasEmergency = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('بدء جلسة جديدة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finishSession();
      },
      child: Scaffold(
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
                    'معلومات عامة بمصادر',
                    style: TextStyle(fontSize: 12, color: Color(0xFF647773)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              key: const Key('finish-session'),
              tooltip: 'إنهاء الجلسة',
              onPressed: _finishSession,
              icon: const Icon(Icons.check_circle_outline_rounded),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: _DemoBadge(),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              const _SafetyNotice(),
              const Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16, 4, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'مصادر مصرية ومؤسسات تعليمية',
                    style: TextStyle(
                      color: Color(0xFF51645F),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 4),
                  itemCount: _egyptianResources.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final source = _egyptianResources[index];
                    return ActionChip(
                      avatar: const Icon(Icons.open_in_new_rounded, size: 14),
                      label: Text(source.title),
                      onPressed: () => _openSource(source.url),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('message-list'),
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: _messages.length + (_isSending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isSending && index == _messages.length) {
                      return const _LoadingBubble();
                    }
                    return _MessageBubble(
                      message: _messages[index],
                      onSourceTap: _openSource,
                    );
                  },
                ),
              ),
              _MessageComposer(
                controller: _controller,
                enabled: !_isSending,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F1ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'اختبارية',
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
              'معلومات عامة وليست تشخيصًا أو علاجًا. لا تكتب بيانات شخصية أو أعراضًا حقيقية؛ قد لا تلتقط قواعد التنبيه كل الحالات.',
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
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.sources = const [],
  });

  final String text;
  final bool isUser;
  final List<ChatSource> sources;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onSourceTap});

  final _ChatMessage message;
  final ValueChanged<String> onSourceTap;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: const TextStyle(fontSize: 14, color: Color(0xFF223532)),
              ),
              if (message.sources.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 7),
                for (final source in message.sources)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: InkWell(
                      onTap: () => onSourceTap(source.url),
                      borderRadius: BorderRadius.circular(8),
                      child: Text(
                        '${source.title} · ${source.publisher}\n${source.url}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF176B66),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
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
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'اسأل سؤالًا عامًا…',
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
            onPressed: enabled ? onSend : null,
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
