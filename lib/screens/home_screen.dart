import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../widgets/api_doc_input.dart';
import '../widgets/chat_area.dart';
import '../widgets/history_sidebar.dart';
import '../providers/chat_provider.dart';
import '../providers/api_provider.dart';
import '../services/ai_service.dart';
import '../widgets/console_panel.dart';
import '../services/log_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();
    // 初始化 AIService
    _aiService = AIService(
      logService: context.read<LogService>(),
      configService: context.read<ConfigService>(),
    );
    // 加载历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<String> _processMessageWithAI(String message, String apiDocs) async {
    try {
      // 获取聊天历史
      final chatHistory = context
          .read<ChatProvider>()
          .messages
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      // 调用 AI 服务处理消息
      return await _aiService.processMessage(
        userMessage: message,
        apiDocs: apiDocs,
        chatHistory: chatHistory,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 收起键盘
    FocusScope.of(context).unfocus();

    final chatProvider = context.read<ChatProvider>();
    final apiProvider = context.read<ApiProvider>();
    final logService = context.read<LogService>();

    setState(() => _isLoading = true);
    try {
      // 添加用户消息
      await chatProvider.addMessage(message, true);
      _messageController.clear();

      // 获取API文档
      final apiDocs = apiProvider.apiDocs;
      if (apiDocs.isEmpty) {
        logService.log('错误: API文档为空', level: LogLevel.error);
        throw Exception('请先输入API文档');
      }

      // 调用AI处理消息 - 处理过程只在控制台显示
      final response = await _processMessageWithAI(message, apiDocs);

      // 只在消息框显示最终结果
      await chatProvider.addMessage(response, false, apiDocs: apiDocs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '历史记录',
                    style: GoogleFonts.orbitron(
                      color: Theme.of(context).primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 历史记录列表
            Expanded(
              child: HistorySidebar(
                scrollController: ScrollController(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.api,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            const Text('AI API Assistant'),
          ],
        ),
        actions: [
          _buildHistoryButton(),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E21),
                  const Color(0xFF1D1E33),
                  Colors.cyanAccent.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Column(
            children: [
              _buildApiDocSection(),
              const Expanded(
                child: ChatArea(),
              ),
              _buildInputArea(),
            ],
          ),
          const ConsolePanel(),
        ],
      ),
    );
  }

  Widget _buildApiDocSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        leading: Icon(
          Icons.description,
          color: Theme.of(context).primaryColor,
        ),
        title: const Text(
          'API Documentation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: const [ApiDocInput()],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          Icons.history,
          color: Theme.of(context).primaryColor,
        ),
        onPressed: () => _showHistory(context),
        tooltip: '历史记录',
      ),
    );
  }

  Widget _buildInputArea() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '输入你的问题...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
}
