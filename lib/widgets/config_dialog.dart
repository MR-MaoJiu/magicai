import 'package:flutter/material.dart';
import '../services/config_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';

class ConfigDialog extends StatefulWidget {
  final ConfigService configService;

  const ConfigDialog({super.key, required this.configService});

  @override
  State<ConfigDialog> createState() => _ConfigDialogState();
}

class _ConfigDialogState extends State<ConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _baseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _modelController.text = widget.configService.apiModel;
    _baseUrlController.text = widget.configService.baseUrl;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.3),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              Colors.cyanAccent.withOpacity(0.05),
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildForm(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Colors.cyanAccent,
                  Colors.pinkAccent.withOpacity(0.8),
                ],
              ).createShader(bounds),
              child: const Icon(
                Icons.hub,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'MAGIC AI INTERFACE',
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.pinkAccent.withOpacity(0.8),
                    ],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildInputField(
            controller: _apiKeyController,
            label: 'API KEY',
            hint: '输入你的密钥',
            icon: Icons.key,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _modelController,
            label: 'AI MODEL',
            hint: '选择模型',
            icon: Icons.psychology,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _baseUrlController,
            label: 'API URL',
            hint: '输入API地址',
            icon: Icons.link,
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.sourceCodePro(
          color: Colors.cyanAccent,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.cyanAccent,
                Colors.pinkAccent.withOpacity(0.8),
              ],
            ).createShader(bounds),
            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(
            color: Colors.cyanAccent.withOpacity(0.7),
          ),
          hintStyle: TextStyle(
            color: Colors.cyanAccent.withOpacity(0.3),
          ),
        ),
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '此字段不能为空';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent,
            Colors.pinkAccent.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveConfig,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'INITIALIZE SYSTEM',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      await widget.configService.saveConfig(
        apiKey: _apiKeyController.text,
        apiModel: _modelController.text,
        baseUrl: _baseUrlController.text,
      );
      if (mounted) {
        runApp(MyApp(configService: widget.configService));
      }
    }
  }
}
