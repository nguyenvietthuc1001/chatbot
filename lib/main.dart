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
  static const _endpoint =
      'https://muygnhhqxsdsmfjrhsag.supabase.co/functions/v1/gemini-chat';

  Future<String> getAdvice(List<ChatMessage> messages) async {
    final messagesForApi = messages
        .where((message) => message.includeInHistory)
        .map(
          (message) => {
            'role': message.sender == Sender.user ? 'user' : 'model',
            'text': message.text,
          },
        )
        .toList();

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'messages': messagesForApi}),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeminiException(
          body['error'] as String? ??
              'Không thể nhận phản hồi từ trợ lý. Bạn thử lại nhé.',
        );
      }

      final text = body['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const GeminiException(
          'Mình chưa nhận được phản hồi phù hợp. Bạn thử lại nhé.',
        );
      }
      return text.trim();
    } on GeminiException {
      rethrow;
    } on FormatException {
      throw const GeminiException(
        'Phản hồi từ máy chủ không hợp lệ. Bạn thử lại nhé.',
      );
    } catch (_) {
      throw const GeminiException(
        'Không thể kết nối máy chủ tư vấn. Bạn kiểm tra mạng rồi thử lại nhé.',
      );
    }
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
