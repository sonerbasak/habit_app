import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Bildirim sistemi başlatılır ve zaman dilimi ayarlanır
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Kullanıcı bildirime tıkladığında çalışacak kod buraya gelir
      },
    );

    await requestNotificationPermission();
  }

  /// Bildirim gönderme iznini ister
  static Future<void> requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Belirlenen saatte günlük tekrarlayan planlanmış bildirim gösterir
  static Future<void> showScheduledNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Geçmiş tarih kontrolü (Eğer geçmişteyse, planlamayı denemez)
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel', // Benzersiz kanal ID'si
          'Habit Notifications', // Kanal adı
          channelDescription: 'Bildirimler alışkanlık hatırlatmaları içindir',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Bu ayar, bildirimin her gün aynı saatte tekrarlamasını sağlar
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Belirli bir ID'ye sahip planlanmış bildirimi iptal eder
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
