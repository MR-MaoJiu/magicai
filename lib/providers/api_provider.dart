import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiProvider with ChangeNotifier {
  String _apiDocs = '';

  String get apiDocs => _apiDocs;

  void updateApiDocs(String docs) {
    _apiDocs = docs;
    notifyListeners();
  }

  Future<void> loadApiDoc(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        _apiDocs = response.body;
        notifyListeners();
      } else if (response.statusCode == 401) {
        // 处理认证
        throw Exception('需要认证');
      } else {
        throw Exception('加载API文档失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> executeApiCall({
    required String method,
    required String url,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Uri uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.Request(method, uri)
        ..headers.addAll(headers ?? {})
        ..body = json.encode(data);

      final streamedResponse = await response.send();
      final responseData = await http.Response.fromStream(streamedResponse);

      if (responseData.statusCode >= 200 && responseData.statusCode < 300) {
        return json.decode(responseData.body);
      } else {
        throw Exception('API调用失败: ${responseData.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
