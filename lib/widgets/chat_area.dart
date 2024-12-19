import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'markdown_text.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: chatProvider.messages.length,
          itemBuilder: (context, index) {
            final message = chatProvider.messages[index];
            return _MessageBubble(
              message: message,
              isLast: index == chatProvider.messages.length - 1,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isLast;

  const _MessageBubble({
    required this.message,
    required this.isLast,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: widget.message.isUser ? const Offset(1, 0) : const Offset(-1, 0),
        end: Offset.zero,
      ).animate(_animation),
      child: FadeTransition(
        opacity: _animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.message.isUser) _buildAvatar(isAI: true),
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: widget.message.isUser
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.message.isUser
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.pinkAccent.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.message.isUser
                                ? Theme.of(context).primaryColor
                                : Colors.pinkAccent)
                            .withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownText(
                        data: widget.message.content,
                        selectable: true,
                      ),
                      if (widget.isLast && !widget.message.isUser)
                        _buildTypingIndicator(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.message.isUser) _buildAvatar(isAI: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required bool isAI}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAI
            ? Colors.pinkAccent.withOpacity(0.1)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border.all(
          color: isAI
              ? Colors.pinkAccent.withOpacity(0.3)
              : Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Icon(
        isAI ? Icons.smart_toy : Icons.person,
        size: 20,
        color: isAI ? Colors.pinkAccent : Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(1),
          _buildDot(2),
          _buildDot(3),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.pinkAccent.withOpacity(value * 0.5),
          ),
        );
      },
    );
  }
}
