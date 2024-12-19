# AI API Assistant

一个基于 Flutter 开发的智能 API 调试助手，可以通过自然语言对话的方式来测试和调用 API。

## 功能特点

- 🤖 智能对话：通过自然语言描述你的需求
- 📚 API 文档解析：自动分析和理解 API 文档
- 🔍 智能调用：自动构建并执行 API 请求
- 📝 历史记录：保存所有的对话和 API 调用记录
- 🎨 科幻界面：现代感十足的深色主题 UI
- 🔧 灵活配置：支持自定义 API 密钥和模型

## 使用方法

1. 配置设置
   - 启动应用后，首次使用需要配置 API 密钥
   - 可选择配置 AI 模型和 API 基础地址

2. 输入 API 文档
   - 点击顶部的 "API Documentation" 展开文档输入区
   - 粘贴你的 API 文档内容

3. 开始对话
   - 在底部输入框中描述你的需求
   - 例如："帮我调用获取用户信息的接口"
   - AI 会自动分析文档并执行相应的 API 调用

4. 查看历史
   - 点击右上角的历史记录按钮
   - 可以查看和恢复之前的对话

## 技术实现

- 🎯 Flutter 框架开发
- 🏗️ Provider 状态管理
- 💾 本地存储历史记录
- 🔄 支持异步 API 调用
- 📋 Markdown 渲染支持
- 🎨 自定义主题和动画

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── screens/              # 页面
│   └── home_screen.dart   # 主页面
├── widgets/              # UI组件
│   ├── api_doc_input.dart # API文档输入
│   ├── chat_area.dart     # 对话区域
│   ├── config_dialog.dart # 配置弹窗
│   └── history_sidebar.dart # 历史记录
├── services/             # 服务
│   ├── ai_service.dart    # AI服务
│   ├── config_service.dart # 配置服务
│   └── log_service.dart   # 日志服务
└── providers/            # 状态管理
    ├── api_provider.dart  # API状态
    └── chat_provider.dart # 对话状态
```

## 配置说明

1. API 密钥 (必填)
   - 用于访问 AI 服务
   - 格式：以 "sk-" 开头的字符串

2. AI 模型 (可选)
   - 默认：gpt-4o
   - 可选其他兼容模型

3. API 地址 (可选)
   - 默认：https://api.xty.app/v1
   - 可配置为其他兼容的端点

## 注意事项

- 请确保 API 文档格式清晰
- API 密钥请妥善保管
- 建议在发送请求前检查文档正确性

## 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的对话和 API 调用
- 实现历史记录功能
- 添加配置管理

## 待优化

- [ ] 支持更多 API 文档格式
- [ ] 添加请求超时处理
- [ ] 优化错误提示
- [ ] 支持导出历史记录
- [ ] 添加更多主题选项

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目！

## 许可证

MIT License
