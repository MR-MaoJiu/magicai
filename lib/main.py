try:
    import tkinter as tk
    from tkinter import scrolledtext, messagebox, ttk
    import threading
    from openai import OpenAI
    import httpx
    from queue import Queue
    import time
    import json
    import re
    import logging
    import os
    import markdown
    from tkinter import font as tkfont
except ImportError as e:
    print(f"请先安装所需依赖: {str(e)}")
    print("运行以下命令安装依赖:")
    print("pip install openai httpx markdown")
    exit(1)

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

class APIExecutor:
    def __init__(self):
        self.http_client = httpx.Client(timeout=30.0, follow_redirects=True)
    
    def execute_api_call(self, method, url, headers=None, params=None, json_data=None):
        try:
            # 记录完整的请求信息
            logging.info("========== API请求开始 ==========")
            logging.info(f"请求URL: {url}")
            logging.info(f"请求方法: {method}")
            logging.info(f"请求头: \n{json.dumps(headers, ensure_ascii=False, indent=2)}")
            logging.info(f"查询参数: \n{json.dumps(params, ensure_ascii=False, indent=2)}")
            logging.info(f"请求体: \n{json.dumps(json_data, ensure_ascii=False, indent=2)}")
            
            # 记录发送请求的时间
            start_time = time.time()
            logging.info("正在发送请求...")
            
            response = self.http_client.request(
                method=method.upper(),
                url=url,
                headers=headers,
                params=params,
                json=json_data
            )
            
            # 记录响应时间
            elapsed_time = time.time() - start_time
            logging.info(f"请求耗时: {elapsed_time:.2f}秒")
            
            # 记录完整的响应信息
            logging.info("========== API响应开始 ==========")
            logging.info(f"状态码: {response.status_code}")
            logging.info(f"响应头: \n{json.dumps(dict(response.headers), ensure_ascii=False, indent=2)}")
            
            # 检查响应内容类型
            content_type = response.headers.get('content-type', '').lower()
            logging.info(f"响应类型: {content_type}")
            
            if 'application/javascript' in content_type or 'text/javascript' in content_type:
                logging.info("到JSONP响应，正在解析...")
                text = response.text
                logging.info(f"原始响应: \n{text}")
                match = re.search(r'[^(]*\((.*)\)[^)]*$', text.strip())
                if match:
                    json_str = match.group(1)
                    response_data = json.loads(json_str)
                    logging.info("JSONP解析成功")
                else:
                    raise ValueError("无法解析JSONP响应")
            else:
                try:
                    response_data = response.json() if response.text else None
                    logging.info("JSON解析成功")
                except json.JSONDecodeError:
                    response_data = {"text": response.text}
                    logging.info("非JSON响应，使用文本格式")
            
            logging.info(f"响应数据: \n{json.dumps(response_data, ensure_ascii=False, indent=2)}")
            logging.info("========== API调用结束 ==========\n")
            
            return response_data
            
        except Exception as e:
            error_msg = f"API调用出错: {str(e)}"
            logging.error(f"========== API调用错误 ==========")
            logging.error(error_msg)
            logging.error(f"错误类型: {type(e).__name__}")
            logging.error("========== 错误详情结束 ==========\n")
            return {"error": str(e)}

class MarkdownText(scrolledtext.ScrolledText):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        
        # 创建标签
        self.tag_configure("bold", font=("TkDefaultFont", 10, "bold"))
        self.tag_configure("italic", font=("TkDefaultFont", 10, "italic"))
        self.tag_configure("code", font=("Courier", 9), background="#f6f8fa")
        self.tag_configure("heading", font=("TkDefaultFont", 12, "bold"))
        self.tag_configure("user", foreground="#0366d6", spacing1=10, spacing3=5)
        self.tag_configure("ai", foreground="#28a745", spacing1=10, spacing3=5)
        self.tag_configure("error", foreground="#cb2431", spacing1=10, spacing3=5)
        
        # 配置代码块样式
        self.tag_configure("codeblock", 
            font=("Courier", 9),
            background="#f6f8fa",
            spacing1=10,
            spacing3=10,
            lmargin1=20,
            lmargin2=20
        )
        
        self.configure(
            font=("TkDefaultFont", 10),
            wrap=tk.WORD,
            padx=10,
            pady=10
        )

    def append_markdown(self, text, role="ai"):
        """添加Markdown格式文本"""
        try:
            # 转换Markdown为HTML
            html = markdown.markdown(
                text,
                extensions=['fenced_code', 'tables']
            )
            
            # 在文本末尾添加分隔符
            self.insert(tk.END, "\n")
            
            # 添加发送者标识
            sender = "You: " if role == "user" else "AI: "
            self.insert(tk.END, sender, role)
            self.insert(tk.END, "\n")
            
            # 处理代码块
            parts = re.split(r'(```.*?\n.*?```)', text, flags=re.DOTALL)
            for part in parts:
                if part.startswith('```'):
                    # 处理代码块
                    code = part.strip('`').strip()
                    if '\n' in code:
                        lang, *code_lines = code.split('\n')
                        code = '\n'.join(code_lines)
                    self.insert(tk.END, code + "\n", "codeblock")
                else:
                    # 处理普通文本
                    lines = part.split('\n')
                    for line in lines:
                        if line.startswith('#'):
                            # 处理标题
                            self.insert(tk.END, line.lstrip('#').strip() + "\n", "heading")
                        elif line.strip().startswith('- '):
                            # 处理列表
                            self.insert(tk.END, "  • " + line.lstrip('- ').strip() + "\n")
                        elif '`' in line:
                            # 处理行内代码
                            parts = line.split('`')
                            for i, p in enumerate(parts):
                                if i % 2 == 1:
                                    self.insert(tk.END, p, "code")
                                else:
                                    self.insert(tk.END, p)
                            self.insert(tk.END, "\n")
                        else:
                            # 普通文本
                            self.insert(tk.END, line + "\n")
            
            # 添加额外的空行作为分隔
            self.insert(tk.END, "\n")
            
            # 滚动到底部
            self.see(tk.END)
            
        except Exception as e:
            logging.error(f"渲染Markdown失败: {str(e)}")
            # 使用普通文本作为后备方案
            self.insert(tk.END, f"{sender}{text}\n\n", role)
            self.see(tk.END)

# 添加新的进度条类
class LoadingProgressbar(ttk.Progressbar):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.animation_speed = 5
        self.is_animating = False
        
    def start_animation(self):
        """开始加载动画"""
        self.is_animating = True
        self.animation_step()
    
    def stop_animation(self):
        """停止加载动画"""
        self.is_animating = False
        self.pack_forget()
    
    def animation_step(self):
        """进度条动画步骤"""
        if not self.is_animating:
            return
            
        current = self['value']
        if current >= 100:
            current = 0
        self['value'] = current + self.animation_speed
        
        # 20毫秒后继续动画
        self.after(20, self.animation_step)

class AIAssistantGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("AI接口调用助手")
        self.root.geometry("1000x700")
        
        # 创建主分割面板
        self.main_paned = ttk.PanedWindow(root, orient=tk.HORIZONTAL)
        self.main_paned.pack(fill=tk.BOTH, expand=True)
        
        # 左侧历史记录面板
        self.history_frame = ttk.LabelFrame(self.main_paned, text="历史记录")
        self.main_paned.add(self.history_frame, weight=1)
        
        # 历史记录列表
        self.history_list = tk.Listbox(self.history_frame, width=20)
        self.history_list.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        self.history_list.bind('<<ListboxSelect>>', self.on_history_select)
        
        # 历史记录操作按钮
        self.history_buttons = tk.Frame(self.history_frame)
        self.history_buttons.pack(fill=tk.X, padx=5, pady=5)
        
        self.clear_history_btn = tk.Button(self.history_buttons, text="清除历史", command=self.clear_history)
        self.clear_history_btn.pack(side=tk.RIGHT)
        
        # 右侧主界面
        self.main_frame = ttk.Frame(self.main_paned)
        self.main_paned.add(self.main_frame, weight=3)
        
        # 初始API执行器
        self.api_executor = APIExecutor()
        
        # 初始化OpenAI客户端
        try:
            self.client = OpenAI(
                base_url="https://api.xty.app/v1",
                api_key="sk-bYiSagTwA8sgWyQzF6Ab2dAc55B54e9bBd6bD8D2C413D9A8",
                http_client=httpx.Client(
                    base_url="https://api.xty.app/v1",
                    follow_redirects=True,
                    timeout=30.0
                ),
            )
        except Exception as e:
            messagebox.showerror("错误", f"初始化AI客户��失败: {str(e)}")
            root.destroy()
            return
            
        # API文档输入区
        self.doc_frame = tk.LabelFrame(self.main_frame, text="API文档输入", padx=5, pady=5)
        self.doc_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # URL输入
        self.url_frame = tk.Frame(self.doc_frame)
        self.url_frame.pack(fill=tk.X, pady=2)
        
        self.doc_entry = tk.Entry(self.url_frame)
        self.doc_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        self.load_doc_button = tk.Button(self.url_frame, text="从URL加载", command=self.load_api_doc)
        self.load_doc_button.pack(side=tk.RIGHT, padx=5)
        
        # 文件选择
        self.file_frame = tk.Frame(self.doc_frame)
        self.file_frame.pack(fill=tk.X, pady=2)
        
        self.file_path_var = tk.StringVar()
        self.file_path_label = tk.Label(self.file_frame, textvariable=self.file_path_var, anchor='w')
        self.file_path_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        self.choose_file_button = tk.Button(self.file_frame, text="选择文件", command=self.choose_file)
        self.choose_file_button.pack(side=tk.RIGHT, padx=5)
        
        # 文档预览和编辑区
        self.doc_preview = scrolledtext.ScrolledText(self.main_frame, height=8)
        self.doc_preview.pack(padx=10, pady=5, fill=tk.X)
        
        # 添加提示文本
        self.doc_preview.insert(tk.END, "在此处粘贴API文档或使用上方的URL/文件加载方式...")
        self.doc_preview.bind('<FocusIn>', self.on_preview_focus_in)
        self.doc_preview.bind('<FocusOut>', self.on_preview_focus_out)
        
        # 对话区
        self.chat_frame = ttk.Frame(self.main_frame)
        self.chat_frame.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)
        
        # 使用自定义的MarkdownText替代原来的ScrolledText
        self.chat_text = MarkdownText(self.chat_frame, height=15)
        self.chat_text.pack(fill=tk.BOTH, expand=True)
        
        # 设置HTML样式
        self.html_style = """
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 10px;
            }
            .user-message {
                background-color: #e3f2fd;
                padding: 10px;
                margin: 5px 0;
                border-radius: 5px;
            }
            .ai-message {
                background-color: #f5f5f5;
                padding: 10px;
                margin: 5px 0;
                border-radius: 5px;
            }
            code {
                background-color: #f8f9fa;
                padding: 2px 4px;
                border-radius: 3px;
                font-family: monospace;
            }
            pre {
                background-color: #f8f9fa;
                padding: 10px;
                border-radius: 5px;
                overflow-x: auto;
            }
            table {
                border-collapse: collapse;
                width: 100%;
                margin: 10px 0;
            }
            th, td {
                border: 1px solid #ddd;
                padding: 8px;
                text-align: left;
            }
            th {
                background-color: #f5f5f5;
            }
        </style>
        """
        
        # 用户输入区（放在对话区下方）
        self.input_frame = tk.Frame(self.main_frame)
        self.input_frame.pack(fill=tk.X, padx=10, pady=5)
        
        self.input_text = tk.Entry(self.input_frame)
        self.input_text.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        # 绑定回车键
        self.input_text.bind('<Return>', lambda e: self.send_message())
        
        self.send_button = tk.Button(self.input_frame, text="发送", command=self.send_message)
        self.send_button.pack(side=tk.RIGHT, padx=5)
        
        # 分隔线
        separator = ttk.Separator(self.main_frame, orient='horizontal')
        separator.pack(fill=tk.X, padx=10, pady=5)
        
        # 替换原有的进度条
        self.progress_var = tk.DoubleVar()
        self.progress = LoadingProgressbar(
            self.main_frame,
            mode='indeterminate',
            maximum=100
        )
        
        # 添加停止按钮
        self.stop_button = tk.Button(
            self.input_frame,
            text="停止",
            command=self.stop_conversation,
            state=tk.DISABLED
        )
        self.stop_button.pack(side=tk.RIGHT, padx=5)
        
        # 添加对话控制变量
        self.conversation_active = False
        self.current_thread = None
        
        # 控制台日志区
        self.log_label = tk.Label(self.main_frame, text="控制台日志:")
        self.log_label.pack(pady=2)
        
        self.log_text = scrolledtext.ScrolledText(self.main_frame, height=8)
        self.log_text.pack(padx=10, pady=5, fill=tk.X)
        
        # 配置日志颜色标��
        self.log_text.tag_configure('INFO', foreground='green')
        self.log_text.tag_configure('ERROR', foreground='red')
        self.log_text.tag_configure('WARNING', foreground='orange')
        self.log_text.tag_configure('DEBUG', foreground='blue')
        
        # 创建自定义日志处理器
        class GUILogHandler(logging.Handler):
            def __init__(self, text_widget):
                logging.Handler.__init__(self)
                self.text_widget = text_widget
                
            def emit(self, record):
                msg = self.format(record)
                def append():
                    self.text_widget.insert(tk.END, msg + '\n', record.levelname)
                    self.text_widget.see(tk.END)
                self.text_widget.after(0, append)
        
        # 添加GUI日志处理器
        gui_handler = GUILogHandler(self.log_text)
        gui_handler.setFormatter(
            logging.Formatter('%(asctime)s [%(levelname)s] %(message)s', 
                            datefmt='%H:%M:%S')
        )
        logging.getLogger().addHandler(gui_handler)
        
        # 用于存储API文档
        self.api_docs = ""
        
        # 创建消息队列
        self.message_queue = Queue()
        
        # 启动消息处理线程
        self.processing = True
        self.message_thread = threading.Thread(target=self.process_messages, daemon=True)
        self.message_thread.start()
        
        # 初始化历史记录存储
        self.history = []
        self.current_history_index = None
        
        # 加载历史记录
        self.load_history()
        
        # 添加对话历史存储
        self.conversation_history = []
        self.last_api_results = None  # 存储最近一次的API调用结果
        
        # 添加上次调用状态跟踪
        self.last_call_status = {
            'success': True,
            'error_message': None,
            'original_request': None
        }

    def update_progress(self, show=True):
        """显示或隐藏进度条动画"""
        if show:
            if not self.progress.winfo_viewable():
                self.progress.pack(fill=tk.X, padx=10, pady=5)
            self.progress.start_animation()
        else:
            self.progress.stop_animation()

    def stop_conversation(self):
        """停止当前对话"""
        if self.conversation_active:
            self.conversation_active = False
            if self.current_thread and self.current_thread.is_alive():
                # 等待线程结束
                self.current_thread.join(timeout=1.0)
            
            self.update_progress(False)
            self.send_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
            self.add_message("对话已停止", is_user=False)

    def add_message(self, message, is_user=False, show_analysis=True):
        """添加消息到对话区，支持Markdown格式"""
        try:
            # 如果是用户消息，先添加到对话历史
            if is_user:
                self.conversation_history.append({
                    "role": "user",
                    "content": message
                })
            
            # 添加消息到对话框
            self.chat_text.append_markdown(message, "user" if is_user else "ai")
            
            # 如果是AI响应，添加到对话历史
            if not is_user:
                self.conversation_history.append({
                    "role": "assistant",
                    "content": message
                })
            
        except Exception as e:
            logging.error(f"添加消息失败: {str(e)}")
            # 使用普通文本作为后备方案
            fallback_message = f"{'You' if is_user else 'AI'}: {message}\n\n"
            self.chat_text.insert(tk.END, fallback_message, "user" if is_user else "ai")

    def send_message(self):
        try:
            doc_content = self.doc_preview.get("1.0", tk.END).strip()
            if doc_content == "在此处粘贴API文档或使用上方的URL/文件加载方式...":
                doc_content = ""
            
            self.api_docs = doc_content
            user_input = self.input_text.get().strip()
            
            if not self.api_docs:
                messagebox.showwarning("警告", "请先输入API文档")
                return
            
            if not user_input:
                messagebox.showwarning("警告", "请输入您的需求")
                return
            
            # 禁用发送按钮，启用停止按钮
            self.send_button.config(state=tk.DISABLED)
            self.stop_button.config(state=tk.NORMAL)
            self.conversation_active = True
            
            # 添加用户消息到对话框
            self.add_message(user_input, is_user=True)
            
            # 清空输入框
            self.input_text.delete(0, tk.END)
            
            # 显示进度条
            self.update_progress(True)
            
            # 创建新线程处理请求
            self.current_thread = threading.Thread(
                target=self.process_request,
                args=(user_input,),
                daemon=True
            )
            self.current_thread.start()
            
        except Exception as e:
            messagebox.showerror("错误", f"发送消息失败: {str(e)}")
            self.send_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
            self.update_progress(False)

    def process_request(self, user_input, missing_info=None):
        try:
            if not self.conversation_active:
                return
                
            # 更新进度到10%，表示开始处理
            self.update_progress(True)
            logging.info("开始处理用户请求...")
            
            # 构建上下文提示
            logging.info("构建对话上下文...")
            self.update_progress(True)
            
            # 获取上一次的对话内容和API调用信息
            last_conversation = None
            last_api_call = None
            if self.conversation_history:
                # 获取最近的对话历史，包括用户输入和AI回复
                last_conversation = self.conversation_history[-2:]  # 获取最近一轮对话
                if self.last_api_results:
                    last_api_call = {
                        'api_results': self.last_api_results,
                        'api_url': getattr(self, 'last_api_url', None),
                        'api_method': getattr(self, 'last_api_method', None),
                        'api_params': getattr(self, 'last_api_params', None)
                    }
            
            # 准备上下文分析提示
            context_analysis_prompt = f"""请仔细分析用户输入与上下文的关系。

上一轮对话：
用户: {last_conversation[-2]['content'] if last_conversation and len(last_conversation) >= 2 else '无'}
AI: {last_conversation[-1]['content'] if last_conversation and len(last_conversation) >= 2 else '无'}

上一次API调用：
URL: {last_api_call['api_url'] if last_api_call else '无'}
参数: {json.dumps(last_api_call['api_params'], ensure_ascii=False) if last_api_call else '无'}
结果: {json.dumps(last_api_call['api_results'], ensure_ascii=False) if last_api_call else '无'}

当前用户输入：{user_input}

请分析：
1. 当前输入是否是对上一轮对话的：
   - 补充提问
   - 跟进问题
   - 相关查询
   - 完全无关的新问题
2. 如果相关，具体相关在哪里？
3. 如果��关，上一次的API调用结果是否可以复用？如何复用？
4. 如果是新问题，为什么判断它是新问题？

请用JSON格式返回分析结果：
```json
{{
    "is_new_question": true/false,
    "relation_type": "补充提问|跟进问题|相关查询|新问题",
    "analysis": "详细解释为什么做出这个判断...",
    "should_reuse_api": true/false,
    "reuse_strategy": {{
        "reuse_url": true/false,
        "reuse_params": true/false,
        "param_modifications": [
            {{
                "param": "参数名",
                "old_value": "原值",
                "new_value": "新值",
                "reason": "修改原因"
            }}
        ]
    }}
}}
```
"""
            
            # 进行上下文分析
            logging.info("正在分析对话关联性...")
            completion = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "你是一个专业的对话分析专家，请仔细分析用户输入与上下文的关系。"},
                    {"role": "user", "content": context_analysis_prompt}
                ]
            )
            
            context_analysis = completion.choices[0].message.content
            logging.info(f"对话关联性分析结果: {context_analysis}")
            
            # 解析分析结果
            analysis_result = None
            try:
                match = re.search(r'```json\n(.*?)\n```', context_analysis, re.DOTALL)
                if match:
                    analysis_result = json.loads(match.group(1))
                    logging.info(f"解析到的关联性分析: {json.dumps(analysis_result, ensure_ascii=False, indent=2)}")
            except Exception as e:
                logging.error(f"解析上下文分析结果失败: {str(e)}")
            
            # 根据分析结果构建API调用策略
            if analysis_result and not analysis_result.get('is_new_question'):
                # 这是一个相关问题
                relation_type = analysis_result.get('relation_type', '未知')
                logging.info(f"检测到{relation_type}，准备复用API信息")
                
                if analysis_result.get('should_reuse_api'):
                    # 复用API调用信息
                    reuse_strategy = analysis_result.get('reuse_strategy', {})
                    system_prompt = f"""这是一个{relation_type}。

### 上一次API调用信息
- URL: {last_api_call['api_url'] if reuse_strategy.get('reuse_url') else '需要新URL'}
- 原始参数: 
```json
{json.dumps(last_api_call['api_params'], ensure_ascii=False, indent=2) if last_api_call else '无'}
```

### 参数修改建议
```json
{json.dumps(reuse_strategy.get('param_modifications', []), ensure_ascii=False, indent=2)}
```

请基于上述信息生成新的API调用。
"""
                else:
                    # 相关问题但需要新的API调用
                    system_prompt = f"""这是一个{relation_type}，但需要新的API调用。

### 分析原因
{analysis_result.get('analysis')}

### API文档
{self.api_docs}
"""
            else:
                # 这是一个新问题
                logging.info("检测到新问题，使用新的API调用")
                system_prompt = f"""这是一个全新的问题。

分析原因：{analysis_result.get('analysis') if analysis_result else '无上下文关联'}

请基于API文档选择合适的接口：
{self.api_docs}
"""

            # 添加API调用格式说明
            system_prompt += """
请按以下格式返回API调用信息：
```json
{
    "url": "完整的API地址",
    "method": "GET/POST/PUT/DELETE",
    "headers": {
        "Accept": "application/json"
    },
    "params": {},
    "data": {}
}
```
"""
            
            # 发送AI请求
            logging.info("发送AI分析请求...")
            self.update_progress(True)
            
            completion = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_input}
                ]
            )
            
            ai_response = completion.choices[0].message.content
            logging.info("AI响应已收到，正在分析...")
            self.update_progress(True)
            
            # 提取API调用信息
            logging.info("解析API调用信息...")
            self.update_progress(True)
            
            api_calls = self.extract_api_calls(ai_response)
            if not api_calls:
                self.add_message("我正在分析您的请求，但未能找到有效的API调用信息。\n" + ai_response)
                logging.warning("未能解析出有效的API调用信息")
                self.update_progress(True)
                return
            
            # 执行API调用
            logging.info("开始行API调用...")
            self.update_progress(True)
            
            # 修改API调用结果处理
            for call in api_calls:
                try:
                    # 验证必要参数
                    if not call.get('url'):
                        logging.error("缺少API调用URL")
                        continue
                    
                    result = self.api_executor.execute_api_call(
                        method=call.get('method', 'GET'),
                        url=call['url'],  # 直接使用url，因为已经验证存在
                        headers=call.get('headers', {}),
                        params=call.get('params', {}),
                        json_data=call.get('data', {})
                    )
                    
                    # 检查API调用结果
                    if isinstance(result, dict) and result.get('error'):
                        # 记录错误状态
                        self.last_call_status.update({
                            'success': False,
                            'error_message': result['error'],
                            'original_request': user_input
                        })
                        
                        error_prompt = f"""
                        API调用失败，错误信息：{result['error']}
                        请分析错误原因给出建议。
                        """
                        
                        completion = self.client.chat.completions.create(
                            model="gpt-4o",
                            messages=[
                                {"role": "system", "content": "你是一个API错误分析专家"},
                                {"role": "user", "content": error_prompt}
                            ]
                        )
                        
                        error_analysis = completion.choices[0].message.content
                        self.add_message(f"抱歉，调用遇到了问题。\n{error_analysis}")
                        return
                        
                    else:
                        # 调用成功，更新状态
                        self.last_call_status.update({
                            'success': True,
                            'error_message': None,
                            'original_request': None
                        })
                        self.last_api_results = result
                
                except Exception as e:
                    error_msg = f"API调用失败: {str(e)}"
                    logging.error(error_msg)
                    self.last_call_status.update({
                        'success': False,
                        'error_message': str(e),
                        'original_request': user_input
                    })
                    self.add_message(f"抱歉，调用API时出现错误: {str(e)}")
                    continue
            
            # 生成最终响应
            logging.info("生成最终响应...")
            self.update_progress(True)
            
            # 构建响应提示
            response_context = ""
            if self.conversation_history:
                response_context = "对话历史：\n"
                for msg in self.conversation_history[-6:]:  # 保留最近3轮对话
                    response_context += f"{'用户' if msg['role'] == 'user' else 'AI'}: {msg['content']}\n"
            
            # 生成回复
            response_prompt = f"""基于以下信息生成回复：
            1. API调用结果：
            {json.dumps(self.last_api_results, ensure_ascii=False, indent=2)}
            
            2. 对话历史：
            {response_context}
            
            3. 当前问题类型：
            {analysis_result.get('relation_type') if analysis_result else '新问题'}
            
            请用自然、友好的语言回复用户，注意：
            1. 如果是后续问题，要结合上下文
            2. 如果是新问题，直接回答当前问题
            3. 确保回复的连贯性和完整性
            """
            
            completion = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "你是一个友好的助手，请用自然的语言回答用户"},
                    {"role": "user", "content": response_prompt}
                ]
            )
            
            final_response = completion.choices[0].message.content
            self.add_message(final_response)
            
            # 添加AI响应到对话历史
            self.conversation_history.append({
                "role": "assistant",
                "content": final_response
            })
            
            # 保存本次API调用信息供下次使用
            if api_calls and api_calls[0]:
                self.last_api_url = api_calls[0].get('url')
                self.last_api_method = api_calls[0].get('method')
                self.last_api_params = {
                    'headers': api_calls[0].get('headers'),
                    'params': api_calls[0].get('params'),
                    'data': api_calls[0].get('data')
                }
            
            self.update_progress(True)
            logging.info("请求处理完成")
            
        except Exception as e:
            error_msg = f"处理请求时出错: {str(e)}"
            logging.error(error_msg)
            self.add_message(f"### 错误\n抱歉，处理您的请求时出现了问题: {str(e)}")
            self.update_progress(True)
        finally:
            self.update_progress(False)
            self.send_button.config(state=tk.NORMAL)
            self.stop_button.config(state=tk.DISABLED)
            self.conversation_active = False

    def extract_api_calls(self, ai_response):
        """从AI响应中提取API调用信息"""
        try:
            # 查找JSON格式的API调用信息
            api_calls = re.findall(r'```json\n(.*?)\n```', ai_response, re.DOTALL)
            if not api_calls:
                logging.warning("未找到JSON格式的API调用信息")
                return []
            
            parsed_calls = []
            for call in api_calls:
                try:
                    parsed_call = json.loads(call)
                    # 添加必要字段验证
                    if not parsed_call.get('url'):
                        logging.error("API调用信息缺少URL")
                        continue
                    
                    # 确保必要字段存在
                    parsed_call.setdefault('method', 'GET')
                    parsed_call.setdefault('headers', {})
                    parsed_call.setdefault('params', {})
                    parsed_call.setdefault('data', {})
                    
                    parsed_calls.append(parsed_call)
                except json.JSONDecodeError as e:
                    logging.error(f"JSON解析错误: {str(e)}")
                    continue
                    
            return parsed_calls
            
        except Exception as e:
            logging.error(f"解析API调用信息失败: {str(e)}")
            return []

    def process_messages(self):
        while self.processing:
            try:
                # 从队列获取消息
                if not self.message_queue.empty():
                    message = self.message_queue.get_nowait()
                    # 在GUI中显示消息
                    self.chat_text.insert(tk.END, message)
                    self.chat_text.see(tk.END)
                time.sleep(0.01)
            except Exception as e:
                print(f"处理消息时发生错误: {str(e)}")
                continue

    def on_closing(self):
        try:
            self.processing = False
            
            # 保存当前会话到历史记录
            if self.api_docs and hasattr(self, 'chat_text'):
                chat_content = self.chat_text.get("1.0", tk.END).strip()
                if chat_content:
                    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
                    history_item = {
                        'timestamp': timestamp,
                        'api_docs': self.api_docs,
                        'chat_content': chat_content,
                        'auth_headers': getattr(self, 'auth_headers', None)
                    }
                    self.history.append(history_item)
                    self.save_history_to_file()
            
            # 移除GUI日志处理器
            for handler in logging.getLogger().handlers[:]:
                if isinstance(handler, logging.Handler):
                    logging.getLogger().removeHandler(handler)
            
            if hasattr(self, 'client') and hasattr(self.client, 'close'):
                self.client.close()
            
            self.root.destroy()
            
        except Exception as e:
            print(f"关闭程序时发生错误: {str(e)}")

    def clear_logs(self):
        self.log_text.delete(1.0, tk.END)

    def load_api_doc(self):
        try:
            url = self.doc_entry.get().strip()
            if not url:
                messagebox.showwarning("警告", "请输入API文档地址")
                return
            
            logging.info(f"正在从 {url} 加载API文档...")
            self.update_progress(True)
            
            # 发送请求获取文档
            response = httpx.get(url, follow_redirects=True, timeout=30.0)
            
            if response.status_code == 401:
                self.update_progress(False)
                self.handle_authentication(url)
                return
            
            response.raise_for_status()
            doc_content = response.text
            
            # 解析HTML内容
            from bs4 import BeautifulSoup
            soup = BeautifulSoup(doc_content, 'html.parser')
            
            # 尝试提取API文档相关内容
            api_content = []
            
            # 查找可能包含API信息的元素
            api_elements = soup.find_all(['pre', 'code'])  # 代码块
            api_elements.extend(soup.find_all(class_=lambda x: x and ('api' in x.lower() or 'swagger' in x.lower())))  # API相关类
            api_elements.extend(soup.find_all(id=lambda x: x and ('api' in x.lower() or 'swagger' in x.lower())))  # API相关ID
            
            for element in api_elements:
                api_content.append(element.get_text())
            
            # 如果没找到特定元素，尝试提取主要内容
            if not api_content:
                # 移除无关内容
                for tag in soup(['script', 'style', 'nav', 'footer', 'header']):
                    tag.decompose()
                api_content = [soup.get_text()]
            
            # 合并并清理内容
            cleaned_content = '\n'.join(api_content)
            cleaned_content = re.sub(r'\n{3,}', '\n\n', cleaned_content)  # 删除多余空行
            
            # 更新文档预览
            self.doc_preview.delete(1.0, tk.END)
            self.doc_preview.insert(tk.END, cleaned_content)
            self.api_docs = cleaned_content
            
            logging.info("API文档加载成功")
            self.update_progress(False)
            
        except Exception as e:
            error_msg = f"加载API文档失败: {str(e)}"
            logging.error(error_msg)
            messagebox.showerror("错误", error_msg)
            self.update_progress(False)

    def handle_authentication(self, url):
        auth_window = tk.Toplevel(self.root)
        auth_window.title("认证信息")
        auth_window.geometry("300x150")
        
        tk.Label(auth_window, text="请选择认证方式:").pack(pady=5)
        
        auth_type = tk.StringVar(value="token")
        
        def on_auth_type_change():
            if auth_type.get() == "token":
                password_label.pack_forget()
                password_entry.pack_forget()
                token_label.pack()
                token_entry.pack()
            else:
                token_label.pack_forget()
                token_entry.pack_forget()
                password_label.pack()
                password_entry.pack()
        
        tk.Radiobutton(auth_window, text="Token", variable=auth_type, value="token", command=on_auth_type_change).pack()
        tk.Radiobutton(auth_window, text="用户名密码", variable=auth_type, value="password", command=on_auth_type_change).pack()
        
        username_label = tk.Label(auth_window, text="用户名:")
        username_label.pack()
        username_entry = tk.Entry(auth_window)
        username_entry.pack()
        
        password_label = tk.Label(auth_window, text="密码:")
        password_entry = tk.Entry(auth_window, show="*")
        
        token_label = tk.Label(auth_window, text="Token:")
        token_entry = tk.Entry(auth_window)
        token_label.pack()
        token_entry.pack()
        
        def submit():
            auth_info = {
                "type": auth_type.get(),
                "username": username_entry.get(),
                "password": password_entry.get(),
                "token": token_entry.get()
            }
            auth_window.destroy()
            self.load_api_doc_with_auth(url, auth_info)
        
        tk.Button(auth_window, text="确定", command=submit).pack(pady=10)

    def load_api_doc_with_auth(self, url, auth_info):
        try:
            headers = {}
            if auth_info["type"] == "token":
                headers["Authorization"] = f"Bearer {auth_info['token']}"
            
            # 先尝试登录（如果是用户名密码方式）
            if auth_info["type"] == "password":
                logging.info("正在进行登录...")
                # 这里需要分析API文档中的登录接口
                # 实际实现时需要根据文档格式进行解析
                login_result = self.analyze_and_call_login_api(url, auth_info)
                if login_result.get("token"):
                    headers["Authorization"] = f"Bearer {login_result['token']}"
            
            # 获取文档
            response = httpx.get(url, headers=headers, follow_redirects=True, timeout=30.0)
            response.raise_for_status()
            
            doc_content = response.text
            self.doc_preview.delete(1.0, tk.END)
            self.doc_preview.insert(tk.END, doc_content)
            self.api_docs = doc_content
            
            # 保存认证信息供后续API调用使用
            self.auth_headers = headers
            
            logging.info("API文档加载成功")
            
        except Exception as e:
            error_msg = f"加载API文档失败: {str(e)}"
            logging.error(error_msg)
            messagebox.showerror("错误", error_msg)

    def analyze_and_call_login_api(self, doc_url, auth_info):
        try:
            # 构建分析登录接口的提示
            prompt = f"""分析以下API文档URL: {doc_url}
            用户提供了用户名: {auth_info['username']} 和密码
            请找到登录接口并生成调用信息，返回格式：        ```json
            {{
                "method": "POST",
                "url": "登录接口地址",
                "headers": {{}},
                "data": {{
                    "username": "用户名字段",
                    "password": "密码字段"
                }}
            }}        ```
            """
            
            # 让AI分析登录接口
            completion = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": "你是一个API分析专家"},
                    {"role": "user", "content": prompt}
                ]
            )
            
            # 提取登录接口信息
            login_api = self.extract_api_calls(completion.choices[0].message.content)[0]
            
            # 调用登录接口
            login_api["data"]["username"] = auth_info["username"]
            login_api["data"]["password"] = auth_info["password"]
            
            result = self.api_executor.execute_api_call(**login_api)
            return result
            
        except Exception as e:
            logging.error(f"登录失败: {str(e)}")
            return {}

    def on_preview_focus_in(self, event):
        """当文档预览区获得焦点时，如果是提示文本则清空"""
        if self.doc_preview.get("1.0", tk.END).strip() == "在此处粘贴API文档或使用上方的URL/文件加载方式...":
            self.doc_preview.delete("1.0", tk.END)

    def on_preview_focus_out(self, event):
        """当文档预览区失去焦点时，如果为空则显示提示文本"""
        if not self.doc_preview.get("1.0", tk.END).strip():
            self.doc_preview.insert("1.0", "在此处粘贴API文档或使用上方的URL/文件加载方式...")

    def choose_file(self):
        """选择并加载API文档文件"""
        try:
            file_path = tk.filedialog.askopenfilename(
                title="选择API文档文件",
                filetypes=[
                    ("所有支持的格式", "*.json;*.yaml;*.yml;*.txt;*.md"),
                    ("JSON文件", "*.json"),
                    ("YAML文件", "*.yaml;*.yml"),
                    ("文本文件", "*.txt"),
                    ("Markdown文件", "*.md"),
                    ("所有文件", "*.*")
                ]
            )
            
            if not file_path:
                return
            
            self.file_path_var.set(file_path)
            logging.info(f"正在加载文件: {file_path}")
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.doc_preview.delete("1.0", tk.END)
            self.doc_preview.insert(tk.END, content)
            self.api_docs = content
            
            logging.info("文件加载成功")
            
        except Exception as e:
            error_msg = f"加载文件失败: {str(e)}"
            logging.error(error_msg)
            messagebox.showerror("错误", error_msg)

    def save_history(self):
        """保存当前会话到历史记录"""
        try:
            if self.api_docs and hasattr(self, 'chat_text'):
                chat_content = self.chat_text.get("1.0", tk.END).strip()
                if chat_content:
                    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
                    history_item = {
                        'timestamp': timestamp,
                        'api_docs': self.api_docs,
                        'chat_content': chat_content,
                        'auth_headers': getattr(self, 'auth_headers', None)
                    }
                    self.history.append(history_item)
                    self.update_history_list()
                    self.save_history_to_file()
        except Exception as e:
            logging.error(f"保存历史记录失败: {str(e)}")

    def load_history(self):
        """从文件加载历史记录"""
        try:
            history_file = 'chat_history.json'
            if os.path.exists(history_file):
                with open(history_file, 'r', encoding='utf-8') as f:
                    self.history = json.load(f)
                    self.update_history_list()
        except Exception as e:
            logging.error(f"加载历史记录失败: {str(e)}")
            self.history = []

    def save_history_to_file(self):
        """将历史记录保存到文件"""
        try:
            history_file = 'chat_history.json'
            with open(history_file, 'w', encoding='utf-8') as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
        except Exception as e:
            logging.error(f"保存历史记录文件失败: {str(e)}")

    def update_history_list(self):
        """更新历史记录列表显示"""
        self.history_list.delete(0, tk.END)
        for item in reversed(self.history):  # 最新的记录显示在顶部
            # 只显示日期和时间的简短格式
            timestamp = item['timestamp']
            display_time = timestamp.split()[1]  # 只显示时间部分
            display_date = timestamp.split()[0]  # 日期部分
            
            # 获取对话的第行作为标题
            chat_lines = item['chat_content'].split('\n')
            first_line = next((line for line in chat_lines if line.strip()), "对话")
            title = first_line[:20] + "..." if len(first_line) > 20 else first_line
            
            display_text = f"{display_date}\n{display_time}\n{title}"
            self.history_list.insert(0, display_text)

    def on_history_select(self, event):
        """当选择历史记录时触发"""
        try:
            selection = self.history_list.curselection()
            if not selection:
                return
            
            index = selection[0]
            real_index = len(self.history) - 1 - index  # 因为示顺序是反的
            history_item = self.history[real_index]
            
            # 恢复API文档
            self.doc_preview.delete("1.0", tk.END)
            self.doc_preview.insert(tk.END, history_item['api_docs'])
            self.api_docs = history_item['api_docs']
            
            # 恢复聊天内容
            self.chat_text.delete("1.0", tk.END)
            self.chat_text.insert(tk.END, history_item['chat_content'])
            
            # 恢复认证信息
            if history_item.get('auth_headers'):
                self.auth_headers = history_item['auth_headers']
            
            self.current_history_index = real_index
            logging.info(f"已加载历史记录: {history_item['timestamp']}")
            
        except Exception as e:
            logging.error(f"加载历史记录失败: {str(e)}")

    def clear_history(self):
        """清除所有历史记录"""
        if messagebox.askyesno("确认", "确定要清除所有历史记录吗？"):
            self.history = []
            self.update_history_list()
            self.save_history_to_file()
            logging.info("历史记录已清除")

if __name__ == "__main__":
    try:
        root = tk.Tk()
        app = AIAssistantGUI(root)
        root.protocol("WM_DELETE_WINDOW", app.on_closing)
        root.mainloop()
    except Exception as e:
        print(f"程序启动失败: {str(e)}") 