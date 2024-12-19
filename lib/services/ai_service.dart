import 'package:http/http.dart' as http;
import 'dart:convert';
import 'log_service.dart';
import 'config_service.dart';

class AIService {
  final http.Client _client;
  final LogService _logService;
  final ConfigService _configService;

  AIService({
    required LogService logService,
    required ConfigService configService,
  })  : _logService = logService,
        _configService = configService,
        _client = http.Client();

  String _formatJson(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  // 调用实际API
  Future<String> _callActualApi(Map<String, dynamic> apiConfig) async {
    _logService.log('开始调用实际API...', level: LogLevel.info);
    _logService.log('API配置:\n${_formatJson(apiConfig)}', level: LogLevel.info);

    try {
      // 处理查询参数
      final Map<String, String>? queryParams = apiConfig['params'] != null
          ? Map<String, String>.from(apiConfig['params'] as Map)
          : null;

      // 处理请求头
      final Map<String, String> headers = apiConfig['headers'] != null
          ? Map<String, String>.from(apiConfig['headers'] as Map)
          : {};

      // 处理请求体数据
      final dynamic data = apiConfig['data'];

      // 构建URI
      final Uri uri = Uri.parse(apiConfig['url'] as String).replace(
        queryParameters: queryParams,
      );

      // 创建请求
      final request = http.Request(
        (apiConfig['method'] as String).toUpperCase(),
        uri,
      );

      // 设置请求头
      request.headers.addAll(headers);

      // 如果有请求体数据，添加到请求中
      if (data != null) {
        request.body = jsonEncode(data);
      }

      // 发送请求
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();

      _logService.log('API响应:\n$responseBody', level: LogLevel.info);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        throw Exception('API请求失败: ${response.statusCode}\n$responseBody');
      }
    } catch (e) {
      _logService.log('API调用失败: $e', level: LogLevel.error);
      rethrow;
    }
  }

  Future<String> processMessage({
    required String userMessage,
    required String apiDocs,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    try {
      _logService.log('开始处理消息...');
      _logService.updateProgress(0.1, '分析用户输入');

      // 第一步：让AI分析用户需求并生成API调用配置
      final analysisResponse = await _getApiAnalysis(
        userMessage: userMessage,
        apiDocs: apiDocs,
        chatHistory: chatHistory,
      );

      // 尝试从AI响应中提取API配置
      final apiConfig = _extractApiConfig(analysisResponse);
      String apiResult = '';

      if (apiConfig != null) {
        _logService.updateProgress(0.4, '调用实际API');
        // 调用实际API
        apiResult = await _callActualApi(apiConfig);
      }

      // 第二步：让AI整合API结果并生成最终回答
      return await _getFinalResponse(
        userMessage: userMessage,
        apiDocs: apiDocs,
        apiResult: apiResult,
        apiAnalysis: analysisResponse,
      );
    } catch (e) {
      final errorMessage = '处理消息失败: $e';
      _logService.log(errorMessage, level: LogLevel.error);
      rethrow;
    }
  }

  Future<String> _getApiAnalysis({
    required String userMessage,
    required String apiDocs,
    required List<Map<String, String>> chatHistory,
  }) async {
    _logService.log('分析API调用需求...', level: LogLevel.info);
    final systemPrompt = '''你是一个API文档分析专家。���分析用户的需，并提供具体的API调用方案。

当前API文档内容如下：
$apiDocs

请提供：
1. API调用的具体配置（使用JSON格式）
2. 调用原因的解释
3. 预期结果的说明

如果用户的问题不需要调用API，请直接回答问题。
''';

    final response = await _makeAiRequest(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        ...chatHistory,
        {'role': 'user', 'content': userMessage},
      ],
    );

    return response;
  }

  Future<String> _getFinalResponse({
    required String userMessage,
    required String apiDocs,
    required String apiResult,
    required String apiAnalysis,
  }) async {
    _logService.log('生成最终响应...', level: LogLevel.info);
    final systemPrompt = '''你是用户的朋友。请像日常聊天一样简单直接地回答问题。

用户问题：
$userMessage

API分析：
$apiAnalysis

API返回结果：
$apiResult

记住：就像朋友间聊天一样，简单直接地回答，不需要太多解释。用户感兴趣的话会继续追问的。
''';

    final response = await _makeAiRequest(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': '像朋友一样简单回答'},
      ],
    );

    return response;
  }

  Map<String, dynamic>? _extractApiConfig(String aiResponse) {
    try {
      // 查找JSON代码块
      final RegExp regex = RegExp(r'```json\s*([\s\S]*?)\s*```');
      final match = regex.firstMatch(aiResponse);
      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          return jsonDecode(jsonStr);
        }
      }
      return null;
    } catch (e) {
      _logService.log('提取API配置失败: $e', level: LogLevel.warning);
      return null;
    }
  }

  Future<String> _makeAiRequest({
    required List<Map<String, String>> messages,
  }) async {
    final requestData = {
      'model': _configService.apiModel,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
    };

    _logService.log('AI请求数据:\n${_formatJson(requestData)}',
        level: LogLevel.info);

    final response = await _client.post(
      Uri.parse('${_configService.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer ${_configService.apiKey}',
      },
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final responseText = const Utf8Decoder().convert(response.bodyBytes);
      _logService.log('AI响应:\n$responseText', level: LogLevel.info);

      final data = jsonDecode(responseText);
      return data['choices'][0]['message']['content'] as String;
    } else {
      final errorBody = const Utf8Decoder().convert(response.bodyBytes);
      throw Exception('AI服务响应错误: ${response.statusCode}\n$errorBody');
    }
  }

  void dispose() {
    _client.close();
  }
}
