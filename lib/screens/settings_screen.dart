import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_info.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';

/// Configura o lembrete diário de motivação (notificação).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final time = TimeOfDay(hour: state.reminderHour, minute: state.reminderMin);

    return Scaffold(
      appBar: AppBar(title: const Text('Lembrete diário')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded),
            title: const Text('Frase do dia'),
            subtitle: const Text(
                'Receba uma frase todo dia no horário escolhido'),
            value: state.reminderOn,
            onChanged: (v) async {
              final st = context.read<AppState>();
              if (v) {
                final ok =
                    await NotificationService.instance.requestPermission();
                if (!ok) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text('Ative a permissão de notificações pra usar')));
                  }
                  return;
                }
                await NotificationService.instance
                    .scheduleDaily(st.reminderHour, st.reminderMin);
              } else {
                await NotificationService.instance.cancelDaily();
              }
              st.setReminder(on: v);
            },
          ),
          const Divider(height: 1),
          ListTile(
            enabled: state.reminderOn,
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('Horário do lembrete'),
            subtitle: Text(time.format(context)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked =
                  await showTimePicker(context: context, initialTime: time);
              if (picked == null || !context.mounted) return;
              context
                  .read<AppState>()
                  .setReminder(on: true, hour: picked.hour, minute: picked.minute);
              await NotificationService.instance
                  .scheduleDaily(picked.hour, picked.minute);
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'A notificação chega uma vez por dia com uma mensagem nova.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ),
          const Divider(height: 8),
          ListTile(
            leading: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
            title: const Text('Avaliar na Play Store'),
            subtitle: const Text('Sua nota ajuda muito 💛'),
            onTap: () => _open(AppInfo.playUrl),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Compartilhar o app'),
            onTap: () => Share.share(
                'Conheça o ${AppInfo.appName}! ${AppInfo.playUrl}'),
          ),
          ListTile(
            leading: const Icon(Icons.apps_rounded),
            title: const Text('Outros apps'),
            subtitle: const Text('Veja todos os nossos apps'),
            onTap: () => _open(AppInfo.devUrl),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('By: ${AppInfo.developer}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
