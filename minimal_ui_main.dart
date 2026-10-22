import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() => runApp(const MinimalApp());

class MinimalApp extends StatelessWidget {
  const MinimalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QustDesk 极简控制台',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Segoe UI'),
      home: const MinimalHomePage(),
    );
  }
}

class MinimalHomePage extends StatefulWidget {
  const MinimalHomePage({Key? key}) : super(key: key);
  @override
  State<MinimalHomePage> createState() => _MinimalHomePageState();
}

class _MinimalHomePageState extends State<MinimalHomePage> {
  String myId = "682 913 405";
  String myPassword = "Qq123456";
  String hostServer = "rustdesk.bjthua.cn";
  String serverKey = "qCYNyPS97UcaoJVwwo2wRAC6AOvm3umFYam82p5hBIQ=";

  final TextEditingController _targetIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  File _getConfigFile() {
    final appData = Platform.environment['APPDATA'] ?? '';
    return File('$appData/RustDesk/config/RustDesk2.toml');
  }

  void _loadConfig() {
    try {
      final file = _getConfigFile();
      if (file.existsSync()) {
        final lines = file.readAsLinesSync();
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('permanent-password')) {
            final match = RegExp(r"permanent-password\s*=\s*['\"](.*?)['\"]").firstMatch(trimmed);
            if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
              myPassword = match.group(1)!;
            }
          } else if (trimmed.startsWith('custom-rendezvous-server') || (trimmed.startsWith('rendezvous_server') && hostServer == "rustdesk.bjthua.cn")) {
            final match = RegExp(r"=\s*['\"](.*?)['\"]").firstMatch(trimmed);
            if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
              hostServer = match.group(1)!.replaceAll(':21116', '');
            }
          } else if (trimmed.startsWith('key')) {
            final match = RegExp(r"key\s*=\s*['\"](.*?)['\"]").firstMatch(trimmed);
            if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
              serverKey = match.group(1)!;
            }
          }
        }
        setState(() {});
      }
    } catch (_) {}
  }

  void _saveConfig(String newPassword, String newServer, String newKey) {
    try {
      final file = _getConfigFile();
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      
      String content = '';
      if (file.existsSync()) {
        content = file.readAsStringSync();
      } else {
        content = '''rendezvous_server = '$newServer:21116'
nat_type = 2
serial = 0
unlock_pin = ''
trusted_devices = ''

[options]
av1-test = 'Y'
permanent-password = '$newPassword'
stop-service = 'N'
custom-rendezvous-server = '$newServer'
allow-elevate = 'N'
enable-remote-mouse = 'Y'
enable-remote-keyboard = 'Y'
key = '$newKey'
enable-clipboard = 'Y'
verification-method = 'use-permanent-password'
allow-single-use-password = 'N'
''';
      }

      content = _updateTomlVal(content, 'permanent-password', newPassword);
      content = _updateTomlVal(content, 'custom-rendezvous-server', newServer);
      content = _updateTomlVal(content, 'key', newKey);
      content = _updateTomlVal(content, 'rendezvous_server', '$newServer:21116');

      file.writeAsStringSync(content);

      setState(() {
        myPassword = newPassword;
        hostServer = newServer;
        serverKey = newKey;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已成功保存生效！'), backgroundColor: Colors.green, duration: Duration(seconds: 2))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存配置失败: $e'), backgroundColor: Colors.red)
      );
    }
  }

  String _updateTomlVal(String text, String key, String val) {
    final reg = RegExp(r'^[\t ]*' + RegExp.escape(key) + r'[\t ]*=.*$', multiLine: true);
    if (reg.hasMatch(text)) {
      return text.replaceAllMapped(reg, (match) => "$key = '$val'");
    } else {
      return "$text\n$key = '$val'";
    }
  }

  void _showEditDialog() {
    final passCtrl = TextEditingController(text: myPassword);
    final serverCtrl = TextEditingController(text: hostServer);
    final keyCtrl = TextEditingController(text: serverKey);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('修改固定密码与服务器配置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('固定密码 (Permanent Password)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: '如: Qq123456',
                ),
              ),
              const SizedBox(height: 14),
              const Text('ID / 中继服务器 (Host Server)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: serverCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: '如: rustdesk.bjthua.cn',
                ),
              ),
              const SizedBox(height: 14),
              const Text('通信公钥 Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              TextField(
                controller: keyCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  hintText: '公钥 Key 字符串',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final np = passCtrl.text.trim();
              final ns = serverCtrl.text.trim();
              final nk = keyCtrl.text.trim();
              if (np.isEmpty || ns.isEmpty || nk.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('各项参数不能为空！')));
                return;
              }
              Navigator.pop(ctx);
              _saveConfig(np, ns, nk);
            },
            child: const Text('保存配置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label 已复制到剪贴板！'), duration: const Duration(seconds: 1)));
  }

  void _connect() async {
    String targetId = _targetIdController.text.replaceAll(' ', '').trim();
    if (targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入远程设备 ID！')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('正在调起远程会话: $targetId ...')));
    try {
      await Process.start('rustdesk_driver.exe', [targetId]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('调起远程会话失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('QustDesk 远程控制台', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            tooltip: '修改密码与服务器',
            onPressed: _showEditDialog,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. 本机信息卡片
          _card('本机受控信息', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本机 ID', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(myId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.copy, color: Colors.blueAccent), onPressed: () => _copy(myId.replaceAll(' ', ''), '本机 ID')),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('固定密码 (点击右侧图标可修改)', style: TextStyle(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(myPassword, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent), tooltip: '修改密码', onPressed: _showEditDialog),
                IconButton(icon: const Icon(Icons.copy, size: 20, color: Colors.blueAccent), tooltip: '复制密码', onPressed: () => _copy(myPassword, '固定密码')),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('● 就绪 · 自建服务已接入', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            )
          ]),
          const SizedBox(height: 14),

          // 2. 服务器配置卡片
          _card('服务器与公钥配置 (可修改)', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID 服务器', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(hostServer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent), onPressed: () => _copy(hostServer, 'ID 服务器')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('通信公钥 Key', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(serverKey.length > 20 ? '${serverKey.substring(0, 18)}...' : serverKey, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.copy, size: 18, color: Colors.blueAccent), onPressed: () => _copy(serverKey, '公钥 Key')),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('修改服务器与通信公钥 Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blueAccent,
                  side: const BorderSide(color: Colors.blueAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showEditDialog,
              ),
            )
          ]),
          const SizedBox(height: 14),

          // 3. 控制远程桌面卡片
          _card('控制远程桌面', [
            TextField(
              controller: _targetIdController,
              decoration: InputDecoration(
                hintText: '请输入对方设备 ID...',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _connect,
                child: const Text('立即连接远程桌面', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ]),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }
}
