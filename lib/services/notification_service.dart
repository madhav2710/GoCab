import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../models/user_model.dart';

enum NotificationType {
  rideRequest,
  rideStatus,
  driverArrival,
  rideCompleted,
  promotion,
  emergency,
  payment,
  feedback,
  system,
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      print('User granted permission: ${settings.authorizationStatus}');

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial notification if app was terminated
      RemoteMessage? initialMessage = await _firebaseMessaging
          .getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel rideChannel = AndroidNotificationChannel(
      'ride_notifications',
      'Ride Notifications',
      description: 'Notifications for ride-related updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel promotionChannel =
        AndroidNotificationChannel(
          'promotion_notifications',
          'Promotions',
          description: 'Promotional notifications and offers',
          importance: Importance.low,
          playSound: true,
          enableVibration: false,
        );

    const AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
          'emergency_notifications',
          'Emergency Alerts',
          description: 'Emergency and safety notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(rideChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(promotionChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(emergencyChannel);
  }

  // Get FCM token for the current user
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Update FCM token in Firestore
  Future<void> updateFCMToken(String userId, String? token) async {
    try {
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('FCM token updated for user: $userId');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Send ride request notification to driver
  Future<void> sendRideRequestNotification({
    required String driverFCMToken,
    required RideModel ride,
    required String riderName,
  }) async {
    try {
      await _sendFCMNotification(
        token: driverFCMToken,
        title: 'New Ride Request',
        body: 'You have a new ride request from $riderName',
        data: {
          'type': NotificationType.rideRequest.name,
          'rideId': ride.id,
          'riderId': ride.riderId,
          'riderName': riderName,
          'pickupAddress': ride.pickupAddress,
          'dropoffAddress': ride.dropoffAddress,
          'estimatedFare': ride.estimatedFare.toString(),
          'rideType': ride.rideType.name,
        },
        channelId: 'ride_notifications',
      );
    } catch (e) {
      print('Error sending ride request notification: $e');
    }
  }

  // Send ride status update notification
  Future<void> sendRideStatusNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String rideId,
    required NotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> data = {
        'type': type.name,
        'rideId': rideId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (additionalData != null) {
        data.addAll(additionalData);
      }

      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
        channelId: 'ride_notifications',
      );
    } catch (e) {
      print('Error sending ride status notification: $e');
    }
  }

  // Send driver arrival notification
  Future<void> sendDriverArrivalNotification({
    required String riderFCMToken,
    required String driverName,
    required String rideId,
    required String pickupAddress,
  }) async {
    try {
      await _sendFCMNotification(
        token: riderFCMToken,
        title: 'Driver Arrived',
        body: '$driverName has arrived at your pickup location',
        data: {
          'type': NotificationType.driverArrival.name,
          'rideId': rideId,
          'driverName': driverName,
          'pickupAddress': pickupAddress,
        },
        channelId: 'ride_notifications',
      );
    } catch (e) {
      print('Error sending driver arrival notification: $e');
    }
  }

  // Send promotion notification
  Future<void> sendPromotionNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String promotionId,
    String? imageUrl,
  }) async {
    try {
      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'type': NotificationType.promotion.name,
          'promotionId': promotionId,
          'imageUrl': imageUrl,
        },
        channelId: 'promotion_notifications',
      );
    } catch (e) {
      print('Error sending promotion notification: $e');
    }
  }

  // Send emergency alert
  Future<void> sendEmergencyAlert({
    required String fcmToken,
    required String title,
    required String body,
    required String alertType,
    Map<String, dynamic>? emergencyData,
  }) async {
    try {
      Map<String, dynamic> data = {
        'type': NotificationType.emergency.name,
        'alertType': alertType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (emergencyData != null) {
        data.addAll(emergencyData);
      }

      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
        channelId: 'emergency_notifications',
      );
    } catch (e) {
      print('Error sending emergency alert: $e');
    }
  }

  // Send payment notification
  Future<void> sendPaymentNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String paymentId,
    required double amount,
    required String status,
  }) async {
    try {
      await _sendFCMNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'type': NotificationType.payment.name,
          'paymentId': paymentId,
          'amount': amount.toString(),
          'status': status,
        },
        channelId: 'ride_notifications',
      );
    } catch (e) {
      print('Error sending payment notification: $e');
    }
  }

  // Send feedback reminder
  Future<void> sendFeedbackReminder({
    required String fcmToken,
    required String rideId,
    required String driverName,
  }) async {
    try {
      await _sendFCMNotification(
        token: fcmToken,
        title: 'Rate Your Ride',
        body: 'How was your ride with $driverName?',
        data: {
          'type': NotificationType.feedback.name,
          'rideId': rideId,
          'driverName': driverName,
        },
        channelId: 'ride_notifications',
      );
    } catch (e) {
      print('Error sending feedback reminder: $e');
    }
  }

  // Send FCM notification (in real app, this would go through your backend)
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String channelId,
  }) async {
    try {
      // In a real implementation, you would send this through your backend
      // For now, we'll show a local notification to simulate the FCM
      await _showLocalNotification(
        title: title,
        body: body,
        payload: json.encode(data),
        channelId: channelId,
      );

      // Log the notification for debugging
      print('Notification sent to token: $token');
      print('Title: $title');
      print('Body: $body');
      print('Data: $data');
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'ride_notifications',
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getChannelImportance(channelId),
      priority: _getChannelPriority(channelId),
      showWhen: true,
      enableVibration: channelId == 'emergency_notifications',
      enableLights: channelId == 'emergency_notifications',
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Get channel name based on channel ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'ride_notifications':
        return 'Ride Notifications';
      case 'promotion_notifications':
        return 'Promotions';
      case 'emergency_notifications':
        return 'Emergency Alerts';
      default:
        return 'GoCab Notifications';
    }
  }

  // Get channel description based on channel ID
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'ride_notifications':
        return 'Notifications for ride-related updates';
      case 'promotion_notifications':
        return 'Promotional notifications and offers';
      case 'emergency_notifications':
        return 'Emergency and safety notifications';
      default:
        return 'General GoCab notifications';
    }
  }

  // Get channel importance based on channel ID
  Importance _getChannelImportance(String channelId) {
    switch (channelId) {
      case 'emergency_notifications':
        return Importance.max;
      case 'ride_notifications':
        return Importance.high;
      case 'promotion_notifications':
        return Importance.low;
      default:
        return Importance.high;
    }
  }

  // Get channel priority based on channel ID
  Priority _getChannelPriority(String channelId) {
    switch (channelId) {
      case 'emergency_notifications':
        return Priority.max;
      case 'ride_notifications':
        return Priority.high;
      case 'promotion_notifications':
        return Priority.low;
      default:
        return Priority.high;
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.data}');
    print('Message title: ${message.notification?.title}');
    print('Message body: ${message.notification?.body}');

    String channelId = 'ride_notifications';
    if (message.data['type'] == NotificationType.promotion.name) {
      channelId = 'promotion_notifications';
    } else if (message.data['type'] == NotificationType.emergency.name) {
      channelId = 'emergency_notifications';
    }

    _showLocalNotification(
      title: message.notification?.title ?? 'GoCab Notification',
      body: message.notification?.body ?? 'You have a new notification',
      payload: json.encode(message.data),
      channelId: channelId,
    );
  }

  // Handle message opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened from background: ${message.data}');
    _handleNotificationData(message.data);
  }

  // Handle initial message when app was terminated
  void _handleInitialMessage(RemoteMessage message) {
    print('Initial message: ${message.data}');
    _handleNotificationData(message.data);
  }

  // Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    String type = data['type'] ?? '';

    switch (type) {
      case 'ride_request':
        // Handle ride request notification
        print('Handling ride request notification');
        break;
      case 'ride_status':
        // Handle ride status notification
        print('Handling ride status notification');
        break;
      case 'driver_arrival':
        // Handle driver arrival notification
        print('Handling driver arrival notification');
        break;
      case 'promotion':
        // Handle promotion notification
        print('Handling promotion notification');
        break;
      case 'emergency':
        // Handle emergency notification
        print('Handling emergency notification');
        break;
      case 'payment':
        // Handle payment notification
        print('Handling payment notification');
        break;
      case 'feedback':
        // Handle feedback notification
        print('Handling feedback notification');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  // Handle local notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationData(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Handle local notification for iOS
  void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('Local notification received: $title - $body');
  }

  // Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Subscribe user to role-based topics
  Future<void> subscribeToRoleTopics(UserRole role) async {
    try {
      await subscribeToTopic(role.name); // 'rider' or 'driver'
      await subscribeToTopic('all_users');

      if (role == UserRole.driver) {
        await subscribeToTopic('drivers');
      } else {
        await subscribeToTopic('riders');
      }
    } catch (e) {
      print('Error subscribing to role topics: $e');
    }
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    NotificationSettings settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.data}');

  // Initialize Firebase if needed
  // await Firebase.initializeApp();

  // You can perform background tasks here
  // For example, updating local storage, syncing data, etc.
}
