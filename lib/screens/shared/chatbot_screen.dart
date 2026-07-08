import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../constants/app_theme.dart';
import '../services/ai_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final isArabic =
            context.read<SettingsProvider>().isArabic; // ← define it here
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': isArabic
                ? 'مرحباً! 👋 أنا مساعد بلدية مسقط. يمكنني مساعدتك في:\n\n'
                '• تقديم البلاغات\n'
                '• متابعة شكاواك\n'
                '• فهم خدماتنا\n\n'
                'كيف يمكنني مساعدتك اليوم؟'
                : 'Hello! 👋 I\'m the Muscat Municipality assistant. I can help you with:\n\n'
                '• Submitting issue reports\n'
                '• Tracking your complaints\n'
                '• Understanding our services\n\n'
                'How can I help you today?',
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final apiMessages = _messages
        .where((m) =>
    m['role'] == 'user' || m['role'] == 'assistant')
        .map((m) =>
    {'role': m['role']!, 'content': m['content']!})
        .toList();

    final response = await AIService.chat(messages: apiMessages);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = context.watch<SettingsProvider>().isArabic;

    final List<String> quickPrompts = [
      l10n.howSubmitReport,
      l10n.howTrackIssue,
      l10n.whatTypesIssues,
      l10n.howLongResolve,
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.aiAssistantTitle,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                Text(
                  l10n.online,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_outlined,
              color: AppTheme.textSecondaryColor(context),
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': isArabic
                      ? 'مرحباً! كيف يمكنني مساعدتك؟'
                      : 'Hello! How can I help you today?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── MESSAGES ──────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              itemCount:
              _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator();
                }
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _MessageBubble(
                  content: message['content'] ?? '',
                  isUser: isUser,
                );
              },
            ),
          ),

          // ── QUICK PROMPTS ─────────────────────────────
          if (_messages.length <= 1)
            Container(
              color: AppTheme.backgroundColor(context),
              padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quickQuestions,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      AppTheme.textSecondaryColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: quickPrompts.map((prompt) {
                      return GestureDetector(
                        onTap: () {
                          _messageController.text = prompt;
                          _sendMessage();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withOpacity(0.08),
                            borderRadius:
                            BorderRadius.circular(
                                AppTheme.radiusSm),
                            border: Border.all(
                              color: AppTheme.primary
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            prompt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

          // ── INPUT BAR ─────────────────────────────────
          Container(
            padding:
            const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              border: Border(
                top: BorderSide(
                    color: AppTheme.borderColor(context)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(
                        color:
                        AppTheme.textPrimaryColor(context),
                      ),
                      decoration: InputDecoration(
                        hintText: l10n.typeMessage,
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondaryColor(
                              context),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg),
                          borderSide: BorderSide(
                              color:
                              AppTheme.borderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg),
                          borderSide: BorderSide(
                              color:
                              AppTheme.borderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg),
                          borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 1.5),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor:
                        AppTheme.backgroundColor(context),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isTyping
                            ? AppTheme.textSecondaryColor(
                            context)
                            : AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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

// ── MESSAGE BUBBLE ────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;

  const _MessageBubble({
    required this.content,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : AppTheme.cardColor(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(
                      AppTheme.radiusMd),
                  topRight: const Radius.circular(
                      AppTheme.radiusMd),
                  bottomLeft: Radius.circular(
                      isUser ? AppTheme.radiusMd : 4),
                  bottomRight: Radius.circular(
                      isUser ? 4 : AppTheme.radiusMd),
                ),
                border: isUser
                    ? null
                    : Border.all(
                    color: AppTheme.borderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor(context),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser
                      ? Colors.white
                      : AppTheme.textPrimaryColor(context),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── TYPING INDICATOR ──────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    _animation =
        Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius:
              BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: AppTheme.borderColor(context)),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final opacity =
                    (((_animation.value + delay) % 1.0) >
                        0.5)
                        ? 1.0
                        : 0.3;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color:
                            AppTheme.textSecondaryColor(
                                context),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}