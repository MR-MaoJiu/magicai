import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';

class ApiDocInput extends StatefulWidget {
  const ApiDocInput({super.key});

  @override
  State<ApiDocInput> createState() => _ApiDocInputState();
}

class _ApiDocInputState extends State<ApiDocInput> {
  final _urlController = TextEditingController();
  final _docController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiDocs = context.read<ApiProvider>().apiDocs;
      if (apiDocs.isNotEmpty) {
        _docController.text = apiDocs;
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _docController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildUrlInput(),
          const SizedBox(height: 16),
          _buildDocInput(),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: '输入API文档URL',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () => _loadApiDoc(context),
            tooltip: '下载文档',
          ),
        ],
      ),
    );
  }

  Widget _buildDocInput() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: _docController,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          hintText: '粘贴API文档内容',
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 14),
        onChanged: (value) {
          context.read<ApiProvider>().updateApiDocs(value);
        },
      ),
    );
  }

  Future<void> _loadApiDoc(BuildContext context) async {
    try {
      final apiProvider = context.read<ApiProvider>();
      await apiProvider.loadApiDoc(_urlController.text);
      _docController.text = apiProvider.apiDocs;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }
}
