import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _prefs = SharedPreferences.getInstance();
  bool _isLoading = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await _prefs;
    setState(() {
      _notifications = prefs.getBool('notifications') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await _prefs;
    await prefs.setBool('notifications', _notifications);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('通知'),
                  subtitle: const Text('接收推荐和更新通知'),
                  value: _notifications,
                  onChanged: (value) {
                    setState(() {
                      _notifications = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('关于'),
                  subtitle: const Text('寻味 v1.0.0'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '寻味',
                      applicationVersion: '1.0.0',
                      applicationIcon: const FlutterLogo(size: 64),
                      children: [
                        const Text('一个基于大模型的美食推荐应用，结合用户个性化需求推荐美食，并提供制作和就餐解决方案。'),
                      ],
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 显示隐私政策
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('用户协议'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // 显示用户协议
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 