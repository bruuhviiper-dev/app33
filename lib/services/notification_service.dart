import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/verses.dart';

/// Notificação diária (frase no horário escolhido). Ao TOCAR, abre
/// exatamente a mensagem da notificação (mesmo com o app fechado).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const int _dailyId = 1001;

  void Function(String? payload)? onSelectMessage;

  String? _pendingLaunchPayload;
  String? takePendingLaunchPayload() {
    final p = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return p;
  }

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // mantém o padrão (UTC) se não conseguir detectar
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (resp) =>
          onSelectMessage?.call(resp.payload),
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _pendingLaunchPayload = launch!.notificationResponse?.payload;
    }
    _ready = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> scheduleDaily(int hour, int minute) async {
    await init();
    await _plugin.cancel(_dailyId);
    // Mesma fonte do card do topo (VerseData.ofDay): a notificação e a "frase do
    // dia" na home ficam sempre em sincronia (mesma frase, mesma base de dados).
    final body = VerseData.ofDay();
    await _plugin.zonedSchedule(
      _dailyId,
      'Frases em Inglês 🕊',
      body,
      _nextInstance(hour, minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_frase',
          'Frase do dia',
          channelDescription: 'A sua frase do dia',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: body,
    );
  }

  Future<void> cancelDaily() async {
    await init();
    await _plugin.cancel(_dailyId);
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {}
