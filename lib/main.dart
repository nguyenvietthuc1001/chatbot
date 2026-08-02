import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H\u01b0\u1edbng nghi\u1ec7p AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF215A4F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        useMaterial3: true,
      ),
      home: const CareerChatPage(),
    );
  }
}

enum Sender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.sender,
    this.includeInHistory = true,
  });

  final String text;
  final Sender sender;
  final bool includeInHistory;
}

class GeminiCareerService {
  GeminiCareerService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.1-flash-lite',
  );
  Future<String> getAdvice(List<ChatMessage> messages) async {
    if (_apiKey.isEmpty) {
      throw const GeminiException(
        'Ch\u01b0a c\u1ea5u h\u00ecnh Gemini API key. Ch\u1ea1y app v\u1edbi --dart-define=GEMINI_API_KEY=your_key.',
      );
    }

    final contents = messages
        .where((message) => message.includeInHistory)
        .map(
          (message) => {
            'role': message.sender == Sender.user ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          },
        )
        .toList();

    final response = await _client
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
          ),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {
                  'text':
                      'B\u1ea1n l\u00e0 t\u01b0 v\u1ea5n vi\u00ean h\u01b0\u1edbng nghi\u1ec7p cho h\u1ecdc sinh, sinh vi\u00ean t\u1ea1i Vi\u1ec7t Nam. Lu\u00f4n tr\u1ea3 l\u1eddi b\u1eb1ng ti\u1ebfng Vi\u1ec7t, th\u00e2n thi\u1ec7n v\u00e0 th\u1ef1c t\u1ebf.\n\nTr\u01b0\u1edbc khi \u0111\u01b0a ra k\u1ebft lu\u1eadn ho\u1eb7c g\u1ee3i \u00fd ng\u00e0nh, h\u00e3y h\u1ecfi ng\u01b0\u1ee3c \u0111\u1ec3 hi\u1ec3u \u00edt nh\u1ea5t c\u00e1c th\u00f4ng tin c\u00f2n thi\u1ebfu v\u1ec1: s\u1edf th\u00edch, m\u00f4n h\u1ecdc th\u1ebf m\u1ea1nh v\u00e0 t\u00ednh c\u00e1ch/phong c\u00e1ch l\u00e0m vi\u1ec7c. M\u1ed7i l\u01b0\u1ee3t ch\u1ec9 n\u00ean h\u1ecfi 1\u20133 c\u00e2u r\u00f5 r\u00e0ng, kh\u00f4ng l\u1eb7p l\u1ea1i \u0111i\u1ec1u ng\u01b0\u1eddi h\u1ecdc \u0111\u00e3 n\u00f3i.\n\nKhi \u0111\u00e3 \u0111\u1ee7 th\u00f4ng tin, g\u1ee3i \u00fd \u0111\u00fang 2\u20133 ng\u00e0nh h\u1ecdc. V\u1edbi t\u1eebng ng\u00e0nh, n\u00eau l\u00fd do ph\u00f9 h\u1ee3p v\u00e0 c\u00e1c kh\u1ed1i x\u00e9t tuy\u1ec3n ph\u1ed5 bi\u1ebfn t\u1ea1i Vi\u1ec7t Nam; nh\u1eafc ng\u01b0\u1eddi h\u1ecdc ki\u1ec3m tra \u0111\u1ec1 \u00e1n tuy\u1ec3n sinh ch\u00ednh th\u1ee9c v\u00ec t\u1ed5 h\u1ee3p c\u00f3 th\u1ec3 thay \u0111\u1ed5i. Kh\u00f4ng kh\u1eb3ng \u0111\u1ecbnh ch\u1eafc ch\u1eafn v\u1ec1 \u0111i\u1ec3m chu\u1ea9n, vi\u1ec7c l\u00e0m ho\u1eb7c kh\u1ea3 n\u0103ng tr\u00fang tuy\u1ec3n.\n\nCh\u1ec9 t\u01b0 v\u1ea5n c\u00e1c n\u1ed9i dung li\u00ean quan \u0111\u1ebfn h\u01b0\u1edbng nghi\u1ec7p, ng\u00e0nh h\u1ecdc, n\u0103ng l\u1ef1c, l\u1ef1a ch\u1ecdn ngh\u1ec1 v\u00e0 l\u1ed9 tr\u00ecnh h\u1ecdc. N\u1ebfu ng\u01b0\u1eddi d\u00f9ng h\u1ecfi ch\u1ee7 \u0111\u1ec1 ngo\u00e0i ph\u1ea1m vi n\u00e0y, h\u00e3y l\u1ecbch s\u1ef1 t\u1eeb ch\u1ed1i ng\u1eafn g\u1ecdn v\u00e0 m\u1eddi h\u1ecd quay l\u1ea1i v\u1edbi m\u1ed9t c\u00e2u h\u1ecfi h\u01b0\u1edbng nghi\u1ec7p.',
                },
              ],
            },
            'contents': contents,
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 700},
          }),
        )
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as Map<String, dynamic>?;
      throw GeminiException(
        error?['message'] as String? ??
            'Gemini kh\u00f4ng th\u1ec3 x\u1eed l\u00fd y\u00eau c\u1ea7u n\u00e0y.',
      );
    }

    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException(
        'M\u00ecnh ch\u01b0a nh\u1eadn \u0111\u01b0\u1ee3c ph\u1ea3n h\u1ed3i ph\u00f9 h\u1ee3p. B\u1ea1n th\u1eed l\u1ea1i nh\u00e9.',
      );
    }
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
        ?.map((part) => part['text'] as String? ?? '')
        .join()
        .trim();
    if (text == null || text.isEmpty) {
      throw const GeminiException(
        'M\u00ecnh ch\u01b0a nh\u1eadn \u0111\u01b0\u1ee3c ph\u1ea3n h\u1ed3i ph\u00f9 h\u1ee3p. B\u1ea1n th\u1eed l\u1ea1i nh\u00e9.',
      );
    }
    return text;
  }

  void dispose() => _client.close();
}

class GeminiException implements Exception {
  const GeminiException(this.message);
  final String message;
}

class CareerChatPage extends StatefulWidget {
  const CareerChatPage({super.key});

  @override
  State<CareerChatPage> createState() => _CareerChatPageState();
}

class _CareerChatPageState extends State<CareerChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _gemini = GeminiCareerService();
  final _messages = <ChatMessage>[
    const ChatMessage(
      sender: Sender.assistant,
      includeInHistory: false,
      text:
          'Ch\u00e0o b\u1ea1n! M\u00ecnh l\u00e0 tr\u1ee3 l\u00fd h\u01b0\u1edbng nghi\u1ec7p AI. H\u00e3y k\u1ec3 m\u00ecnh nghe v\u1ec1 s\u1edf th\u00edch, m\u00f4n h\u1ecdc b\u1ea1n y\u00eau th\u00edch ho\u1eb7c c\u00f4ng vi\u1ec7c b\u1ea1n t\u1eebng mu\u1ed1n l\u00e0m nh\u00e9.',
    ),
  ];
  var _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _gemini.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;
    _inputController.clear();
    await _performRequest(
      prompt: text,
      request: () => _gemini.getAdvice(List.of(_messages)),
    );
  }

  Future<void> _performRequest({
    required String prompt,
    required Future<String> Function() request,
  }) async {
    if (_isLoading) return;
    setState(() {
      _messages.add(ChatMessage(text: prompt, sender: Sender.user));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final answer = await request();
      if (!mounted) return;
      setState(
        () =>
            _messages.add(ChatMessage(text: answer, sender: Sender.assistant)),
      );
    } on GeminiException catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          ChatMessage(
            text: error.message,
            sender: Sender.assistant,
            includeInHistory: false,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text:
                'Kh\u00f4ng th\u1ec3 k\u1ebft n\u1ed1i Gemini. Ki\u1ec3m tra m\u1ea1ng, API key v\u00e0 model r\u1ed3i th\u1eed l\u1ea1i nh\u00e9.',
            sender: Sender.assistant,
            includeInHistory: false,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F5),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFD9EFE3),
              child: Icon(Icons.auto_awesome_rounded, color: Color(0xFF215A4F)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'H\u01b0\u1edbng nghi\u1ec7p AI',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                Text(
                  'Lu\u00f4n s\u1eb5n s\u00e0ng l\u1eafng nghe',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5D6B65)),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return const _TypingBubble();
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _MessageComposer(
              controller: _inputController,
              isLoading: _isLoading,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF215A4F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF27332E),
            height: 1.42,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('AI dang suy nghi...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9E5))),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) {
                  if (!isLoading) onSend();
                },
                decoration: InputDecoration(
                  hintText: 'Nh\u1eadp c\u00e2u h\u1ecfi c\u1ee7a b\u1ea1n...',
                  filled: true,
                  fillColor: const Color(0xFFF4F6F3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: const Text('G\u1eedi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                backgroundColor: const Color(0xFF215A4F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
