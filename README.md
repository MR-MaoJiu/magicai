# AI API Assistant

AI API Assistant 是一个智能的 API 文档分析和调用助手，它可以帮助用户理解 API 文档、生成调用示例，并实际执行 API 调用。

## 功能特点

1. **API 文档管理**
   - 支持直接输入或粘贴 API 文档
   - 支持通过 URL 加载 API 文档
   - 自动保存文档内容

2. **智能分析**
   - 自动分析用户需求
   - 生成 API 调用配置
   - 提供调用原因解释
   - 预测可能的结果

3. **API 调用**
   - 自动执行 API 调用
   - 支持多种 HTTP 方法
   - 处理请求头和请求体
   - 实时显示调用过程

4. **结果分析**
   - 智能解析 API 响应
   - 提供清晰的结果说明
   - 错误分析和解决方案
   - Markdown 格式展示

5. **调试功能**
   - 实时控制台输出
   - 详细的日志记录
   - 进度条显示
   - 错误追踪

6. **历史记录**
   - 保存聊天历史
   - 记录 API 调用
   - 快速回顾之前的操作

## 技术栈

- Flutter
- Provider (状态管理)
- HTTP (网络请求)
- Markdown 渲染
- JSON 处理
- UTF-8 编码支持

## 开始使用

1. **安装依赖**
```bash
flutter pub get
```

2. **配置 AI API**
在 `lib/services/ai_service.dart` 中设置你的 API 密钥：
```dart
static const String _apiKey = "你的API密钥";
```

3. **运行应用**
```bash
flutter run
```

## 使用方法

1. **输入 API 文档**
   - 点击顶部的 "API文档" 展开输入区域
   - 直接粘贴文档内容或输入文档 URL
   - 点击下载按钮从 URL 加载文档

2. **发送请求**
   - 在底部输入框输入你的问题
   - 点击发送按钮或按回车键
   - 等待 AI 分析和处理

3. **查看结果**
   - 在聊天区域查看 AI 的回答
   - 在控制台查看详细的处理过程
   - 查看 API 调用结果和解释

4. **使用历史记录**
   - 点击右上角的历史按钮
   - 查看之前的对话记录
   - 点击记录可以回顾详情

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── screens/              
│   └── home_screen.dart   # 主界面
├── widgets/               # UI组件
│   ├── api_doc_input.dart # API文档输入
│   ├── chat_area.dart     # 聊天区域
│   ├── console_panel.dart # 控制台面板
│   └── history_sidebar.dart # 历史记录侧边栏
├── services/              # 服务层
│   ├── ai_service.dart    # AI服务
│   └── log_service.dart   # 日志服务
└── providers/            # 状态管理
    ├── api_provider.dart  # API文档状态
    └── chat_provider.dart # 聊天状态
```

## 注意事项

1. 确保有稳定的网络连接
2. API 文档需要是结构化的文本
3. 大型 API 文档可能需要较长处理时间
4. 建议保持控制台打开以监控处理过程

## 常见问题

1. **API 调用失败**
   - 检查网络连接
   - 验证 API 文档格式
   - 查看控制台错误信息

2. **中文显示乱码**
   - 确保文档使用 UTF-8 编码
   - 检查请求和响应的字符集设置

3. **响应较慢**
   - 这是正常的，AI 需要时间处理
   - 可以在控制台查看处理进度

## 后续计划

1. 支持更多 API 文档格式
2. 添加批量 API 调用功能
3. 优化 AI 响应速度
4. 添加更多自定义选项
5. 支持导出调用记录

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
