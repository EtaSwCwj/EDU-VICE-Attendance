import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeySettingsPage extends StatefulWidget {
  const ApiKeySettingsPage({super.key});

  @override
  State<ApiKeySettingsPage> createState() => _ApiKeySettingsPageState();
}

class _ApiKeySettingsPageState extends State<ApiKeySettingsPage> {
  final _storage = const FlutterSecureStorage();
  final _controller = TextEditingController();
  bool _isObscured = true;
  bool _hasKey = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await _storage.read(key: 'claude_api_key');
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      if (_hasKey) {
        _controller.text = '••••••••••••••••';
      }
    });
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty || key == '••••••••••••••••') return;

    await _storage.write(key: 'claude_api_key', value: key);
    setState(() => _hasKey = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 저장되었습니다'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteKey() async {
    await _storage.delete(key: 'claude_api_key');
    setState(() {
      _hasKey = false;
      _controller.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 키가 삭제되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API 키 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Claude API 키',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              obscureText: _isObscured,
              decoration: InputDecoration(
                hintText: 'sk-ant-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _saveKey,
                  child: const Text('저장'),
                ),
                const SizedBox(width: 8),
                if (_hasKey)
                  TextButton(
                    onPressed: _deleteKey,
                    child: const Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '* API 키는 안전하게 암호화되어 저장됩니다.\n'
              '* https://console.anthropic.com 에서 발급받을 수 있습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}