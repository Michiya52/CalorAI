import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/chatbot_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uid = context.read<AuthProvider>().userId;
        if (uid != null) {
          context.read<ChatbotProvider>().loadUserSessions(uid);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a message.')),
        );
      }
      return;
    }

    final profile = context.read<ProfileProvider>().profile;
    final uid = context.read<AuthProvider>().userId;
    if (profile == null || uid == null) return;

    _messageController.clear();
    FocusManager.instance.primaryFocus?.unfocus();

    await context.read<ChatbotProvider>().sendMessage(
          text: text,
          profile: profile,
          uid: uid,
          todaysMeals: context.read<MealProvider>().todaysMeals,
        );
    _scrollToBottom();
  }

  void _showHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ChatHistorySheet(
        onSessionTap: (session) {
          Navigator.pop(ctx);
          context.read<ChatbotProvider>().loadSession(session);
          _scrollToBottom();
        },
        onDeleteSession: (sessionId) {
          context.read<ChatbotProvider>().deleteSession(sessionId);
        },
        onNewChat: () {
          Navigator.pop(ctx);
          context.read<ChatbotProvider>().startNewChat();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('AI Assistant'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // History button
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.history_rounded,
                  size: 18, color: AppColors.textSecondary(context)),
              onPressed: _showHistoryDrawer,
              tooltip: 'Chat history',
              padding: EdgeInsets.zero,
            ),
          ),
          // New chat button
          Container(
            margin: const EdgeInsets.only(right: 4),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.add_comment_outlined,
                  size: 18, color: AppColors.textSecondary(context)),
              onPressed: () => context.read<ChatbotProvider>().startNewChat(),
              tooltip: 'New chat',
              padding: EdgeInsets.zero,
            ),
          ),
          // Clear button
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.textSecondary(context)),
              onPressed: () => context.read<ChatbotProvider>().clearHistory(),
              tooltip: 'Clear chat',
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatbotProvider>(
              builder: (context, chatbot, _) {
                if (chatbot.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount:
                      chatbot.messages.length + (chatbot.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == chatbot.messages.length && chatbot.isTyping) {
                      return _buildTypingIndicator(isDark);
                    }
                    final msg = chatbot.messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                );
              },
            ),
          ),

          // Input bar
          Consumer<ChatbotProvider>(
            builder: (context, chatbot, _) => Container(
              margin: const EdgeInsets.only(
                  bottom: 110), // Clears 76px nav + 24px padding + 10px gap
              decoration: BoxDecoration(
                color: AppColors.surface(context).withValues(alpha: 0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: SafeArea(
                    top: false,
                    bottom: false, // Don't double-pad with the margin
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer(context),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _messageController,
                                enabled: !chatbot.isTyping,
                                decoration: InputDecoration(
                                  hintText: chatbot.isTyping
                                      ? 'CalorAI is typing...'
                                      : 'Ask about Malaysian food...',
                                  filled: false,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                onSubmitted:
                                    chatbot.isTyping ? null : _sendMessage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: chatbot.isTyping
                                  ? null
                                  : AppColors.primaryGradient(context),
                              color: chatbot.isTyping
                                  ? AppColors.surfaceContainer(context)
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: chatbot.isTyping
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: IconButton(
                              onPressed: chatbot.isTyping
                                  ? null
                                  : () => _sendMessage(_messageController.text),
                              icon: Icon(
                                Icons.arrow_upward_rounded,
                                color: chatbot.isTyping
                                    ? AppColors.textSecondary(context)
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final suggestions = [
      'What\'s a healthier alternative to nasi lemak?',
      'Generate a meal plan under 1800 kcal',
      'How many calories is a bowl of laksa?',
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.auraGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.aura.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.auto_awesome, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'Ask CalorAI anything!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal Malaysian food\nnutrition assistant',
              style: TextStyle(
                  color: AppColors.textSecondary(context), height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _sendMessage(s),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: AppColors.premiumCard(context, radius: 16),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              size: 16, color: AppColors.aura),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary(context))),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.textSecondary(context)),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient(context) : null,
          color: isUser ? null : AppColors.surface(context),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: msg.text,
                shrinkWrap: true,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 14,
                  ),
                  blockSpacing: 8,
                  listIndent: 16,
                  listBulletPadding: const EdgeInsets.only(right: 6),
                  a: TextStyle(color: AppColors.primary),
                  em: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(delay: 0, color: AppColors.aura),
            _PulsingDot(delay: 150, color: AppColors.aura),
            _PulsingDot(delay: 300, color: AppColors.aura),
          ],
        ),
      ),
    );
  }
}

// ── Chat History Bottom Sheet ───────────────────────────────────────

class _ChatHistorySheet extends StatelessWidget {
  final void Function(ChatSession) onSessionTap;
  final void Function(String) onDeleteSession;
  final VoidCallback onNewChat;

  const _ChatHistorySheet({
    required this.onSessionTap,
    required this.onDeleteSession,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Chat'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Sessions list
          Flexible(
            child: Consumer<ChatbotProvider>(
              builder: (context, chatbot, _) {
                final sessions = chatbot.savedSessions;
                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 40, color: AppColors.textSecondary(context)),
                        const SizedBox(height: 12),
                        Text(
                          'No previous chats',
                          style: TextStyle(
                              color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final messageCount = session.messages.length;
                    final timeAgo = _formatTimeAgo(session.createdAt);

                    return Dismissible(
                      key: Key(session.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppColors.error,
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      onDismissed: (_) => onDeleteSession(session.id),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.chat_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '$messageCount messages • $timeAgo',
                          style: TextStyle(
                              color: AppColors.textSecondary(context),
                              fontSize: 12),
                        ),
                        onTap: () => onSessionTap(session),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Pulsing Dot ────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  final int delay;
  final Color color;
  const _PulsingDot({required this.delay, required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
