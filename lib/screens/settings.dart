import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsSection(
            title: 'Внешний вид',
            children: [
              _buildSettingsTile(
                icon: Icons.dark_mode,
                title: 'Темная тема',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement theme switching
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            title: 'О приложении',
            children: [
              _buildSettingsTile(
                icon: Icons.info_outline,
                title: 'Версия',
                trailing: const Text('1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6C63FF)),
      title: Text(title),
      trailing: trailing,
    );
  }
} 