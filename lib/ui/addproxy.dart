import 'dart:io';

import 'package:appproxy/events/debounce.dart';
import 'package:appproxy/generated/l10n.dart';
import 'package:flutter/material.dart';

class AddProxyWidget extends StatefulWidget {
  AddProxyWidget({super.key, required this.onDataFetched, required this.onData});

  // 定义一个回调，用于处理读取到的数据
  final Function(Map<String, dynamic>, {bool isAdd}) onDataFetched;
  Map<String, dynamic> onData = {};

  @override
  State<AddProxyWidget> createState() => _AddProxyWidgetState();
}

// 定义全局函数用于校验Map中必填字段
bool isNullOrEmpty(Map<String, String> map, List<String> requiredKeys) {
  if (map.isEmpty) {
    return true;
  }
  for (var key in requiredKeys) {
    if (!map.containsKey(key) || map[key] == null || map[key]!.isEmpty) {
      return true;
    }
  }
  return false;
}

class _AddProxyWidgetState extends State<AddProxyWidget> {
  var proxyConfig = <String, String>{};
  
  // 新的配置字段控制器
  final TextEditingController _controller_proxyName = TextEditingController();
  final TextEditingController _controller_serverAddr = TextEditingController();
  final TextEditingController _controller_listenAddr = TextEditingController();
  final TextEditingController _controller_preferredIP = TextEditingController();
  final TextEditingController _controller_token = TextEditingController();
  final TextEditingController _controller_dnsServer = TextEditingController();
  final TextEditingController _controller_echDomain = TextEditingController();

  final Debounce _debounce = Debounce(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();

    if (widget.onData.isNotEmpty) {
      // 编辑模式 - 加载现有配置
      _controller_proxyName.text = widget.onData['proxyName'] ?? '';
      _controller_serverAddr.text = widget.onData['serverAddr'] ?? '';
      _controller_listenAddr.text = widget.onData['listenAddr'] ?? '127.0.0.1:1080';
      _controller_preferredIP.text = widget.onData['preferredIP'] ?? '';
      _controller_token.text = widget.onData['token'] ?? '';
      _controller_dnsServer.text = widget.onData['dnsServer'] ?? 'https://1.1.1.1/dns-query';
      _controller_echDomain.text = widget.onData['echDomain'] ?? 'cloudflare-ech.com';
    } else {
      // 新建模式 - 设置默认值
      _controller_listenAddr.text = '127.0.0.1:1080';
      _controller_dnsServer.text = 'https://1.1.1.1/dns-query';
      _controller_echDomain.text = 'cloudflare-ech.com';
    }
  }

  @override
  void dispose() {
    super.dispose();
    _debounce.dispose();
    _controller_proxyName.dispose();
    _controller_serverAddr.dispose();
    _controller_listenAddr.dispose();
    _controller_preferredIP.dispose();
    _controller_token.dispose();
    _controller_dnsServer.dispose();
    _controller_echDomain.dispose();
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
                // 收集配置数据
                proxyConfig['proxyName'] = _controller_proxyName.text.trim();
                proxyConfig['proxyType'] = 'echproxy'; // 固定类型
                proxyConfig['serverAddr'] = _controller_serverAddr.text.trim();
                proxyConfig['listenAddr'] = _controller_listenAddr.text.trim();
                proxyConfig['preferredIP'] = _controller_preferredIP.text.trim();
                proxyConfig['token'] = _controller_token.text.trim();
                proxyConfig['dnsServer'] = _controller_dnsServer.text.trim();
                proxyConfig['echDomain'] = _controller_echDomain.text.trim();

                // 校验必填项（只需要配置名称和Workers地址）
                if (isNullOrEmpty(proxyConfig, ['proxyName', 'serverAddr', 'listenAddr'])) {
                  debugPrint("proxyConfig: $proxyConfig");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('请填写配置名称、Workers地址和监听地址'),
                      backgroundColor: Colors.purple.withOpacity(0.4)));
                  return;
                }

                // 验证 serverAddr 格式 (应包含端口)
                if (!proxyConfig['serverAddr']!.contains(':')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Workers地址格式错误，应为 domain:port'),
                      backgroundColor: Colors.purple.withOpacity(0.4)));
                  return;
                }

                // 验证 listenAddr 格式
                if (!proxyConfig['listenAddr']!.contains(':')) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('监听地址格式错误，应为 IP:端口'),
                      backgroundColor: Colors.purple.withOpacity(0.4)));
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ========== 配置名称 ==========
                  TextField(
                      readOnly: widget.onData.isNotEmpty,
                      controller: _controller_proxyName,
                      decoration: const InputDecoration(
                        labelText: '配置名称 *',
                        hintText: '例如：我的Workers',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                      onTap: () {
                        if (widget.onData.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Text('配置名称不可修改'),
                              backgroundColor: Colors.purple.withOpacity(0.4)));
                        }
                      }),
                  const SizedBox(height: 20.0),

                  // ========== Workers 地址 ==========
                  TextField(
                    controller: _controller_serverAddr,
                    decoration: const InputDecoration(
                      labelText: 'Workers 地址 *',
                      hintText: 'worker.example.workers.dev:443',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud),
                      helperText: '格式：域名:端口',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 监听地址 ==========
                  TextField(
                    controller: _controller_listenAddr,
                    decoration: const InputDecoration(
                      labelText: '监听地址',
                      hintText: '127.0.0.1:1080',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                      helperText: '本地 SOCKS5 监听地址和端口',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 优选 IP (可选) ==========
                  TextField(
                    controller: _controller_preferredIP,
                    decoration: const InputDecoration(
                      labelText: '优选 IP (可选)',
                      hintText: '例如：162.159.128.1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.star),
                      helperText: '优选的 Workers IP 地址，用于提高连接速度',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 校验只能输入IP地址
                      if (value.isNotEmpty && !RegExp(r'^[0-9.:]+
                  const SizedBox(height: 20.0),

                  // ========== 固定 IP (可选) ==========
                  TextField(
                    controller: _controller_serverIP,
                    decoration: const InputDecoration(
                      labelText: '固定 IP (可选)',
                      hintText: '不填则自动解析',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                      helperText: '用于指定 Workers 的固定 IP 地址',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 校验IP地址格式
                      if (value.isNotEmpty && 
                          !RegExp(r'^[0-9.:]+
                  const SizedBox(height: 20.0),

                  // ========== 认证 Token (可选) ==========
                  TextField(
                    controller: _controller_token,
                    decoration: const InputDecoration(
                      labelText: '认证 Token (可选)',
                      hintText: '不填则无需认证',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== DNS 服务器 ==========
                  TextField(
                    controller: _controller_dnsServer,
                    decoration: const InputDecoration(
                      labelText: 'DNS 服务器',
                      hintText: 'https://1.1.1.1/dns-query',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: '支持 DoH 或传统 DNS (如 119.29.29.29:53)',
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // DNS 预设选项
                  Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Cloudflare DoH'),
                        selected: _controller_dnsServer.text == 'https://1.1.1.1/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://1.1.1.1/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Google DoH'),
                        selected: _controller_dnsServer.text == 'https://8.8.8.8/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://8.8.8.8/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('DNSPod'),
                        selected: _controller_dnsServer.text == '119.29.29.29:53',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = '119.29.29.29:53';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // ========== ECH 域名 ==========
                  TextField(
                    controller: _controller_echDomain,
                    decoration: const InputDecoration(
                      labelText: 'ECH 域名',
                      hintText: 'cloudflare-ech.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      helperText: '用于获取 ECH 配置的域名',
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 说明文字 ==========
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
                            Text(
                              '配置说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
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
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}
).hasMatch(value)) {
                        _controller_preferredIP.text = value.substring(0, value.length - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 固定 IP (可选) ==========
                  TextField(
                    controller: _controller_serverIP,
                    decoration: const InputDecoration(
                      labelText: '固定 IP (可选)',
                      hintText: '不填则自动解析',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                      helperText: '用于指定Workers的IP地址，不填则通过DNS解析',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 校验IP地址格式
                      if (value.isNotEmpty && 
                          !RegExp(r'^[0-9.:]+$').hasMatch(value)) {
                        _controller_serverIP.text = 
                            value.substring(0, value.length - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 认证 Token (可选) ==========
                  TextField(
                    controller: _controller_token,
                    decoration: const InputDecoration(
                      labelText: '认证 Token (可选)',
                      hintText: '不填则无需认证',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== DNS 服务器 ==========
                  TextField(
                    controller: _controller_dnsServer,
                    decoration: const InputDecoration(
                      labelText: 'DNS 服务器',
                      hintText: 'https://1.1.1.1/dns-query',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: '支持 DoH 或传统 DNS (如 119.29.29.29:53)',
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // DNS 预设选项
                  Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Cloudflare DoH'),
                        selected: _controller_dnsServer.text == 'https://1.1.1.1/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://1.1.1.1/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Google DoH'),
                        selected: _controller_dnsServer.text == 'https://8.8.8.8/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://8.8.8.8/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('DNSPod'),
                        selected: _controller_dnsServer.text == '119.29.29.29:53',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = '119.29.29.29:53';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // ========== ECH 域名 ==========
                  TextField(
                    controller: _controller_echDomain,
                    decoration: const InputDecoration(
                      labelText: 'ECH 域名',
                      hintText: 'cloudflare-ech.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      helperText: '用于获取 ECH 配置的域名',
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 说明文字 ==========
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
                            Text(
                              '配置说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Workers 地址：Cloudflare Workers 的完整地址\n'
                          '• 优选 IP：可选，优选的中转节点地址和端口\n'
                          '• 固定 IP：可选，用于绕过 DNS 解析\n'
                          '• Token：如果 Workers 需要认证则填写\n'
                          '• DNS：推荐使用 DoH 提高隐私性\n'
                          '• ECH：用于加密 SNI，提高安全性',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}
).hasMatch(value)) {
                        _controller_serverIP.text = 
                            value.substring(0, value.length - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 认证 Token (可选) ==========
                  TextField(
                    controller: _controller_token,
                    decoration: const InputDecoration(
                      labelText: '认证 Token (可选)',
                      hintText: '不填则无需认证',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== DNS 服务器 ==========
                  TextField(
                    controller: _controller_dnsServer,
                    decoration: const InputDecoration(
                      labelText: 'DNS 服务器',
                      hintText: 'https://1.1.1.1/dns-query',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: '支持 DoH 或传统 DNS (如 119.29.29.29:53)',
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // DNS 预设选项
                  Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Cloudflare DoH'),
                        selected: _controller_dnsServer.text == 'https://1.1.1.1/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://1.1.1.1/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Google DoH'),
                        selected: _controller_dnsServer.text == 'https://8.8.8.8/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://8.8.8.8/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('DNSPod'),
                        selected: _controller_dnsServer.text == '119.29.29.29:53',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = '119.29.29.29:53';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // ========== ECH 域名 ==========
                  TextField(
                    controller: _controller_echDomain,
                    decoration: const InputDecoration(
                      labelText: 'ECH 域名',
                      hintText: 'cloudflare-ech.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      helperText: '用于获取 ECH 配置的域名',
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 说明文字 ==========
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
                            Text(
                              '配置说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Workers 地址：Cloudflare Workers 的完整地址\n'
                          '• 优选 IP：可选，优选的中转节点地址和端口\n'
                          '• 固定 IP：可选，用于绕过 DNS 解析\n'
                          '• Token：如果 Workers 需要认证则填写\n'
                          '• DNS：推荐使用 DoH 提高隐私性\n'
                          '• ECH：用于加密 SNI，提高安全性',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}
).hasMatch(value)) {
                        _controller_preferredIP.text = value.substring(0, value.length - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 固定 IP (可选) ==========
                  TextField(
                    controller: _controller_serverIP,
                    decoration: const InputDecoration(
                      labelText: '固定 IP (可选)',
                      hintText: '不填则自动解析',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns),
                      helperText: '用于指定Workers的IP地址，不填则通过DNS解析',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 校验IP地址格式
                      if (value.isNotEmpty && 
                          !RegExp(r'^[0-9.:]+$').hasMatch(value)) {
                        _controller_serverIP.text = 
                            value.substring(0, value.length - 1);
                      }
                    },
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 认证 Token (可选) ==========
                  TextField(
                    controller: _controller_token,
                    decoration: const InputDecoration(
                      labelText: '认证 Token (可选)',
                      hintText: '不填则无需认证',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== DNS 服务器 ==========
                  TextField(
                    controller: _controller_dnsServer,
                    decoration: const InputDecoration(
                      labelText: 'DNS 服务器',
                      hintText: 'https://1.1.1.1/dns-query',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.public),
                      helperText: '支持 DoH 或传统 DNS (如 119.29.29.29:53)',
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  
                  // DNS 预设选项
                  Wrap(
                    spacing: 8.0,
                    children: [
                      FilterChip(
                        label: const Text('Cloudflare DoH'),
                        selected: _controller_dnsServer.text == 'https://1.1.1.1/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://1.1.1.1/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('Google DoH'),
                        selected: _controller_dnsServer.text == 'https://8.8.8.8/dns-query',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = 'https://8.8.8.8/dns-query';
                            });
                          }
                        },
                      ),
                      FilterChip(
                        label: const Text('DNSPod'),
                        selected: _controller_dnsServer.text == '119.29.29.29:53',
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _controller_dnsServer.text = '119.29.29.29:53';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // ========== ECH 域名 ==========
                  TextField(
                    controller: _controller_echDomain,
                    decoration: const InputDecoration(
                      labelText: 'ECH 域名',
                      hintText: 'cloudflare-ech.com',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                      helperText: '用于获取 ECH 配置的域名',
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // ========== 说明文字 ==========
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
                            Text(
                              '配置说明',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Workers 地址：Cloudflare Workers 的完整地址\n'
                          '• 优选 IP：可选，优选的中转节点地址和端口\n'
                          '• 固定 IP：可选，用于绕过 DNS 解析\n'
                          '• Token：如果 Workers 需要认证则填写\n'
                          '• DNS：推荐使用 DoH 提高隐私性\n'
                          '• ECH：用于加密 SNI，提高安全性',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}