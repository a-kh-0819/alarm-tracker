import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// アプリのエントリポイント
void main() {
  runApp(const AlarmTrackerApp());
}

class AlarmTrackerApp extends StatelessWidget {
  const AlarmTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'アラームトラッカー',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const AlarmHomePage(),
    );
  }
}

class AlarmHomePage extends StatefulWidget {
  const AlarmHomePage({Key? key}) : super(key: key);

  @override
  State<AlarmHomePage> createState() => _AlarmHomePageState();
}

class _AlarmHomePageState extends State<AlarmHomePage> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  List<String> _wakeTimes = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadWakeTimes();
  }

  // 通知を初期化する
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings,
        onDidReceiveNotificationResponse: (details) {
      _recordWakeTime();
    });
  }

  // 保存した起床時刻を読み込む
  Future<void> _loadWakeTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _wakeTimes = prefs.getStringList('wake_times') ?? [];
    });
  }

  // 起床時刻を保存する
  Future<void> _saveWakeTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('wake_times', _wakeTimes);
  }

  // 時刻選択ダイアログを表示する
  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // 選択した時刻でアラームを設定する
  Future<void> _setAlarm() async {
    final now = TimeOfDay.now();
    final today = DateTime.now();
    final alarmDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final scheduleTime = alarmDateTime.isAfter(today)
        ? alarmDateTime
        : alarmDateTime.add(const Duration(days: 1));

    // 通知の詳細設定
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'アラーム通知',
      channelDescription: 'アラーム通知用のチャンネル',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.zonedSchedule(
      0,
      'アラーム',
      '起きる時間です！',
      scheduleTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('アラームを${_selectedTime.format(context)}に設定しました'),
      ),
    );
  }

  // アラームを止めた時刻を記録する
  Future<void> _recordWakeTime() async {
    final now = TimeOfDay.now();
    setState(() {
      _wakeTimes.add(now.format(context));
    });
    await _saveWakeTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アラームトラッカー')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'アラーム時刻: ${_selectedTime.format(context)}',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickTime,
                  child: const Text('時刻を選択'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setAlarm,
              child: const Text('アラームを設定'),
            ),
            const SizedBox(height: 24),
            const Text(
              '起床時刻一覧:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _wakeTimes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_wakeTimes[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
