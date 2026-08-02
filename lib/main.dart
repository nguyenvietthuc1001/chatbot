import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gate.dart';

abstract final class SupabaseConfig {
  static const url = 'https://muygnhhqxsdsmfjrhsag.supabase.co';
  static const publishableKey =
      'sb_publishable_xmRxYByGyXdFUUUJcVxlzg_FCeG2eQn';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7566E8),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF201C35)
          : const Color(0xFFF7F8F5),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;
    return MaterialApp(
      title: 'Hướng nghiệp AI',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _themeMode,
      home: AuthGate(
        isDark: isDark,
        onToggleTheme: _toggleTheme,
        authenticatedBuilder: (_) =>
            CareerChatPage(isDark: isDark, onToggleTheme: _toggleTheme),
      ),
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

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw const GeminiException(
        'Phi\u00ean \u0111\u0103ng nh\u1eadp \u0111\u00e3 h\u1ebft h\u1ea1n. H\u00e3y \u0111\u0103ng nh\u1eadp l\u1ea1i.',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'apikey': SupabaseConfig.publishableKey,
              'Authorization': 'Bearer ${session.accessToken}',
            },
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
  const CareerChatPage({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;

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
    final isDark = widget.isDark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 78,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7467E8), Color(0xFFAA7EE9), Color(0xFFFF9AA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(9),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
            ),
            SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hướng nghiệp AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: .2,
                  ),
                ),
                Text(
                  'Cùng khám phá điều bạn giỏi nhất',
                  style: TextStyle(color: Color(0xFFFDF7FF), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Chuyển sang nền sáng' : 'Chuyển sang nền tối',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: '\u0110\u0103ng xu\u1ea5t',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [
                    Color(0xFF211C38),
                    Color(0xFF29234A),
                    Color(0xFF193D42),
                  ]
                : const [
                    Color(0xFFF6F2FF),
                    Color(0xFFFFF6EE),
                    Color(0xFFEAF8F3),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 14, 18, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFFFAE42),
                      size: 19,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Mỗi câu trả lời là một gợi ý nhỏ cho hành trình của bạn',
                      style: TextStyle(
                        color: Color(0xFF736D88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
                colors: [Color(0xFF7566E8), Color(0xFF9B70E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFFFFCFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isUser ? 24 : 7),
          bottomRight: Radius.circular(isUser ? 7 : 24),
        ),
        border: Border.all(
          color: isUser ? const Color(0x337563E8) : const Color(0xFFE9DDF8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUser ? const Color(0xFF7869E7) : const Color(0xFF8E79AF))
                .withValues(alpha: .14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: isUser
          ? Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                height: 1.45,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            )
          : _FormattedAssistantText(text: message.text),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const _AssistantAvatar(size: 34),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({this.size = 38});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFB8C8), Color(0xFFFFD386)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * .55,
      ),
    );
  }
}

class _FormattedAssistantText extends StatelessWidget {
  const _FormattedAssistantText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text
        .replaceAll(RegExp(r'[#*]'), '')
        .replaceAll('\r', '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, color: Color(0xFFFF8FA6), size: 15),
            SizedBox(width: 5),
            Text(
              'Trợ lý hướng nghiệp',
              style: TextStyle(
                color: Color(0xFF8B6AB5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < lines.length; index++)
          _AnswerLine(text: lines[index], isFirst: index == 0),
      ],
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({required this.text, required this.isFirst});
  final String text;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final isSuggestion = RegExp(r'^(?:[-•–]|\d+[.)])\s*').hasMatch(text);
    final cleanText = text.replaceFirst(RegExp(r'^(?:[-•–]|\d+[.)])\s*'), '');

    if (!isSuggestion) {
      return Padding(
        padding: EdgeInsets.only(bottom: isFirst ? 9 : 7),
        child: Text(
          cleanText,
          style: TextStyle(
            color: const Color(0xFF3D3650),
            height: 1.48,
            fontSize: 15,
            fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.stars_rounded,
              color: Color(0xFFFFAE42),
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cleanText,
              style: const TextStyle(
                color: Color(0xFF3D3650),
                height: 1.45,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AssistantAvatar(),
          SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFFFF8FD)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(23)),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFFE9DDF8), width: 1.2),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFFF8FA6),
                    ),
                  ),
                  SizedBox(width: 9),
                  Text(
                    'AI đang suy nghĩ...',
                    style: TextStyle(
                      color: Color(0xFF776D8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        color: Color(0xFFFEFCFF),
        border: Border(top: BorderSide(color: Color(0xFFE7DCF5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),
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
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!isLoading) onSend();
                  },
                  decoration: InputDecoration(
                    hintText: 'Kể mình nghe về điều bạn yêu thích...',
                    hintStyle: const TextStyle(color: Color(0xFF9B91AA)),
                    prefixIcon: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Color(0xFF9B78D0),
                      size: 20,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F0FC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Color(0xFFE5D8F5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              FilledButton.icon(
                onPressed: isLoading ? null : onSend,
                icon: isLoading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Gửi'),
                style: FilledButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFFF7FA0),
                  disabledBackgroundColor: const Color(0xFFFFB7C7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 3,
                  shadowColor: const Color(0x66FF7FA0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
