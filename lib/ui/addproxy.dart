import 'package:flutter/material.dart';

class AddProxyWidget extends StatefulWidget {
  AddProxyWidget({super.key, required this.onDataFetched, required this.onData});

  final Function(Map<String, dynamic>, {bool isAdd}) onDataFetched;
  Map<String, dynamic> onData = {};

  @override
  State<AddProxyWidget> createState() => _AddProxyWidgetState();
}

bool isNullOrEmpty(Map<String, String> map, List<String> requiredKeys) {
  if (map.isEmpty) return true;
  for (var key in requiredKeys) {
    if (!map.containsKey(key) || map[key] == null || map[key]!.isEmpty) {
      return true;
    }
  }
  return false;
}

class _AddProxyWidgetState extends State<AddProxyWidget> {
  var proxyConfig = <String, String>{};
  
  final TextEditingController _controllerProxyName = TextEditingController();
  final TextEditingController _controllerServerAddr = TextEditingController();
  final TextEditingController _controllerListenAddr = TextEditingController();
  final TextEditingController _controllerPreferredIP = TextEditingController();
  final TextEditingController _controllerToken = TextEditingController();
  final TextEditingController _controllerDnsServer = TextEditingController();
  final TextEditingController _controllerEchDomain = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.onData.isNotEmpty) {
      _controllerProxyName.text = widget.onData['proxyName'] ?? '';
      _controllerServerAddr.text = widget.onData['serverAddr'] ?? '';
      _controllerListenAddr.text = widget.onData['listenAddr'] ?? '127.0.0.1:1080';
      _controllerPreferredIP.text = widget.onData['preferredIP'] ?? '';
      _controllerToken.text = widget.onData['token'] ?? '';
      _controllerDnsServer.text = widget.onData['dnsServer'] ?? 'https://1.1.1.1/dns-query';
      _controllerEchDomain.text = widget.onData['echDomain'] ?? 'cloudflare-ech.com';
    } else {
      _controllerListenAddr.text = '127.0.0.1:1080';
      _controllerDnsServer.text = 'https://1.1.1.1/dns-query';
      _controllerEchDomain.text = 'cloudflare-ech.com';
    }
  }

  @override
  void dispose() {
    _controllerProxyName.dispose();
    _controllerServerAddr.dispose();
    _controllerListenAddr.dispose();
    _controllerPreferredIP.dispose();
    _controllerToken.dispose();
    _controllerDnsServer.dispose();
    _controllerEchDomain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onData.isEmpty ? '添加配置' : '编辑配置'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 20.0),
            icon: const Icon(Icons.save),
            onPressed: () {
              proxyConfig['proxyName'] = _controllerProxyName.text.trim();
              proxyConfig['proxyType'] = 'echproxy';
              proxyConfig['serverAddr'] = _controllerServerAddr.text.trim();
              proxyConfig['listenAddr'] = _controllerListenAddr.text.trim();
              proxyConfig['preferredIP'] = _controllerPreferredIP.text.trim();
              proxyConfig['token'] = _controllerToken.text.trim();
              proxyConfig['dnsServer'] = _controllerDnsServer.text.trim();
              proxyConfig['echDomain'] = _controllerEchDomain.text.trim();

              if (isNullOrEmpty(proxyConfig, ['proxyName', 'serverAddr', 'listenAddr'])) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('请填写配置名称、Workers地址和监听地址'),
                    backgroundColor: Colors.purple.withOpacity(0.4),
                  ),
                );
                return;
              }

              if (!proxyConfig['serverAddr']!.contains(':')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Workers地址格式错误，应为 domain:port'),
                    backgroundColor: Colors.purple.withOpacity(0.4),
                  ),
                );
                return;
              }

              if (!proxyConfig['listenAddr']!.contains(':')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('监听地址格式错误，应为 IP:端口'),
                    backgroundColor: Colors.purple.withOpacity(0.4),
                  ),
                );
                return;
              }

              if (widget.onData.isNotEmpty) {
                widget.onDataFetched(proxyConfig, isAdd: true);
              } else {
                widget.onDataFetched(proxyConfig);
              }
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Container(
        color: Theme.of(context).canvasColor,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                readOnly: widget.onData.isNotEmpty,
                controller: _controllerProxyName,
                decoration: const InputDecoration(
                  labelText: '配置名称 *',
                  hintText: '例如：我的Workers',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                onTap: () {
                  if (widget.onData.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('配置名称不可修改'),
                        backgroundColor: Colors.purple.withOpacity(0.4),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerServerAddr,
                decoration: const InputDecoration(
                  labelText: 'Workers 地址 *',
                  hintText: 'worker.example.workers.dev:443',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cloud),
                ),
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerListenAddr,
                decoration: const InputDecoration(
                  labelText: '监听地址',
                  hintText: '127.0.0.1:1080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.settings_ethernet),
                  helperText: '本地 SOCKS5 监听地址和端口',
                ),
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerPreferredIP,
                decoration: const InputDecoration(
                  labelText: '优选 IP (可选)',
                  hintText: '例如：162.159.128.1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                  helperText: '优选的 Workers IP 地址',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && !RegExp(r'^[0-9.:a-zA-Z]+$').hasMatch(value)) {
                    _controllerPreferredIP.text = value.substring(0, value.length - 1);
                    _controllerPreferredIP.selection = TextSelection.fromPosition(
                      TextPosition(offset: _controllerPreferredIP.text.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerToken,
                decoration: const InputDecoration(
                  labelText: '认证 Token (可选)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerDnsServer,
                decoration: const InputDecoration(
                  labelText: 'DNS 服务器',
                  hintText: 'https://1.1.1.1/dns-query',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.public),
                  helperText: '支持 DoH 或传统 DNS',
                ),
              ),
              const SizedBox(height: 10.0),
              
              Wrap(
                spacing: 8.0,
                children: [
                  ChoiceChip(
                    label: const Text('Cloudflare DoH'),
                    selected: _controllerDnsServer.text == 'https://1.1.1.1/dns-query',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _controllerDnsServer.text = 'https://1.1.1.1/dns-query';
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Google DoH'),
                    selected: _controllerDnsServer.text == 'https://8.8.8.8/dns-query',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _controllerDnsServer.text = 'https://8.8.8.8/dns-query';
                        });
                      }
                    },
                  ),
                  ChoiceChip(
                    label: const Text('DNSPod'),
                    selected: _controllerDnsServer.text == '119.29.29.29:53',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _controllerDnsServer.text = '119.29.29.29:53';
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              
              TextField(
                controller: _controllerEchDomain,
                decoration: const InputDecoration(
                  labelText: 'ECH 域名',
                  hintText: 'cloudflare-ech.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
              ),
              const SizedBox(height: 20.0),
              
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('配置说明', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Workers 地址：Cloudflare Workers 的完整地址（域名:端口）\n'
                      '• 监听地址：本地 SOCKS5 服务监听的地址和端口\n'
                      '• 优选 IP：可选，Workers 的优选 IP 地址\n'
                      '• Token：如果 Workers 需要认证则填写\n'
                      '• DNS：推荐使用 DoH 提高隐私性\n'
                      '• ECH：用于加密 SNI，提高安全性',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
