import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/log_service.dart';
import 'dart:math' as math;

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  Offset _position = const Offset(16, 200);
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final GlobalKey _consoleKey = GlobalKey();
  Size _screenSize = Size.zero;

  // 控制台展开时的尺寸
  static const double _expandedWidth = 400;
  static const double _expandedHeight = 300;
  // 悬浮球尺寸
  static const double _collapsedSize = 48;
  // 边距
  static const double _padding = 16;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery.of(context).size;
      _adjustPosition();
    });
  }

  void _adjustPosition() {
    if (_screenSize == Size.zero) return;

    final size = _isExpanded
        ? const Size(_expandedWidth, _expandedHeight)
        : const Size(_collapsedSize, _collapsedSize);

    // 计算安全边界
    final minX = _padding;
    final maxX = math.max(minX, _screenSize.width - size.width - _padding);
    final minY = _padding;
    final maxY = math.max(minY, _screenSize.height - size.height - _padding);

    setState(() {
      double x = _position.dx;
      double y = _position.dy;

      // 确保在安全边界内
      if (x < minX) x = minX;
      if (x > maxX) x = maxX;
      if (y < minY) y = minY;
      if (y > maxY) y = maxY;

      _position = Offset(x, y);
    });
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _adjustPosition();
    });
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      _adjustPosition();
    });
  }

  // 根据可用空间计算实际展开尺寸
  Size _calculateExpandedSize() {
    final availableWidth = _screenSize.width - 2 * _padding;
    final availableHeight = _screenSize.height - 2 * _padding;

    return Size(
      math.min(_expandedWidth, availableWidth),
      math.min(_expandedHeight, availableHeight),
    );
  }

  // 计算展开方向和位置
  Offset _calculateExpandedPosition() {
    if (_screenSize == Size.zero) return _position;

    // 获取实际展开尺寸
    final expandedSize = _calculateExpandedSize();

    double x = _position.dx;
    double y = _position.dy;

    // 计算各个方向的可用空间
    final rightSpace = _screenSize.width - (x + _collapsedSize);
    final leftSpace = x;
    final bottomSpace = _screenSize.height - (y + _collapsedSize);
    final topSpace = y;

    // 优先选择空间更大的方向展开
    if (rightSpace >= expandedSize.width) {
      // 右侧空间足够，保持原位置
      x = x;
    } else if (leftSpace >= expandedSize.width) {
      // 左侧空间足够，向左展开
      x = x - expandedSize.width + _collapsedSize;
    } else {
      // 两侧空间都不够，居中显示
      x = (_screenSize.width - expandedSize.width) / 2;
    }

    if (bottomSpace >= expandedSize.height) {
      // 下方空间足够，保持原位置
      y = y;
    } else if (topSpace >= expandedSize.height) {
      // 上方空间足够，向上展开
      y = y - expandedSize.height + _collapsedSize;
    } else {
      // 上下空间都不够，居中显示
      y = (_screenSize.height - expandedSize.height) / 2;
    }

    // 确保在安全边界内
    x = x.clamp(_padding, _screenSize.width - expandedSize.width - _padding);
    y = y.clamp(_padding, _screenSize.height - expandedSize.height - _padding);

    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final expandedPosition = _calculateExpandedPosition();
    final expandedSize = _calculateExpandedSize();

    return Positioned(
      left: _isExpanded ? expandedPosition.dx : _position.dx,
      top: _isExpanded ? expandedPosition.dy : _position.dy,
      child: GestureDetector(
        onPanUpdate: _handleDrag,
        child: AnimatedContainer(
          key: _consoleKey,
          duration: const Duration(milliseconds: 300),
          width: _isExpanded ? expandedSize.width : _collapsedSize,
          height: _isExpanded ? expandedSize.height : _collapsedSize,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(_isExpanded ? 16 : 24),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child:
              _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleExpanded,
        customBorder: const CircleBorder(),
        child: Center(
          child: Consumer<LogService>(
            builder: (context, logService, _) {
              final hasError = logService.logs.any(
                (log) => log.level == LogLevel.error,
              );
              return Stack(
                children: [
                  Icon(
                    Icons.terminal,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  if (hasError)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        _buildConsoleHeader(),
        Expanded(child: _buildConsoleContent()),
      ],
    );
  }

  Widget _buildConsoleHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal,
            color: Theme.of(context).primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Console',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Consumer<LogService>(
            builder: (context, logService, _) => IconButton(
              icon: const Icon(Icons.clear_all, size: 18),
              onPressed: logService.clearLogs,
              tooltip: '清除日志',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _toggleExpanded,
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleContent() {
    return Consumer<LogService>(
      builder: (context, logService, _) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: logService.logs.length,
                itemBuilder: (context, index) {
                  final log = logService.logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${_formatTime(log.timestamp)}]',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.message,
                            style: TextStyle(
                              color: _getLogColor(log.level),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (logService.progress > 0) _buildProgressBar(logService),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(LogService logService) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            logService.currentStep,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: logService.progress,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.white.withOpacity(0.8);
      case LogLevel.warning:
        return Colors.amber.withOpacity(0.8);
      case LogLevel.error:
        return Colors.red.withOpacity(0.8);
    }
  }
}
