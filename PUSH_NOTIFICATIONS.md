# GoCab Push Notification System

## Overview

The GoCab Push Notification System provides comprehensive real-time notifications for both Android and iOS platforms using Firebase Cloud Messaging (FCM). The system handles ride updates, driver alerts, promotional messages, emergency notifications, and payment confirmations.

## Features

### 🔔 **Notification Types**

1. **Ride Notifications**

   - New ride requests for drivers
   - Ride status updates (accepted, in progress, arrived, completed, cancelled)
   - Driver arrival alerts
   - Ride completion confirmations

2. **Payment Notifications**

   - Payment confirmations
   - Transaction receipts
   - Wallet balance updates
   - Payment failure alerts

3. **Promotional Notifications**

   - Special offers and discounts
   - Promotional campaigns
   - Seasonal deals
   - Referral bonuses

4. **Emergency Alerts**

   - Safety notifications
   - Emergency broadcasts
   - System maintenance alerts
   - Critical updates

5. **Feedback Reminders**
   - Post-ride rating prompts
   - Feedback collection reminders
   - Service improvement requests

### 📱 **Platform Support**

- **Android**: Full support with custom notification channels
- **iOS**: Complete implementation with proper permissions
- **Web**: Background and foreground message handling
- **Cross-platform**: Unified notification experience

### ⚙️ **Advanced Features**

- **Role-based notifications**: Different notifications for riders and drivers
- **Topic subscriptions**: Broadcast notifications to specific user groups
- **Real-time updates**: Instant notification delivery
- **Background processing**: Notifications work when app is closed
- **Custom channels**: Organized notification categories
- **User preferences**: Granular notification control

## Technical Architecture

### **Core Components**

#### **NotificationService**

Primary service for handling FCM integration and local notifications:

```dart
class NotificationService {
  // FCM Integration
  Future<String?> getFCMToken()
  Future<void> updateFCMToken(String userId, String? token)

  // Notification Sending
  Future<void> sendRideRequestNotification({...})
  Future<void> sendRideStatusNotification({...})
  Future<void> sendDriverArrivalNotification({...})
  Future<void> sendPromotionNotification({...})
  Future<void> sendEmergencyAlert({...})
  Future<void> sendPaymentNotification({...})
  Future<void> sendFeedbackReminder({...})

  // Topic Management
  Future<void> subscribeToTopic(String topic)
  Future<void> unsubscribeFromTopic(String topic)
  Future<void> subscribeToRoleTopics(UserRole role)

  // Settings & Management
  Future<bool> areNotificationsEnabled()
  Future<void> clearAllNotifications()
  Future<NotificationSettings> getNotificationSettings()
}
```

#### **NotificationManager**

High-level manager for coordinating notifications across the app:

```dart
class NotificationManager {
  // User Management
  Future<void> updateUserFCMToken(String userId, String? token)

  // Ride Notifications
  Future<void> sendRideRequestToDrivers(RideModel ride, String riderName)
  Future<void> sendRideStatusToRider({...})
  Future<void> sendRideStatusToDriver({...})
  Future<void> sendDriverArrivalNotification({...})
  Future<void> sendRideCompletionNotification({...})

  // Other Notifications
  Future<void> sendPaymentNotification({...})
  Future<void> sendFeedbackReminder({...})
  Future<void> sendPromotionToAllUsers({...})
  Future<void> sendEmergencyAlert({...})

  // Status Change Handling
  Future<void> handleRideStatusChange({...})
}
```

### **Notification Channels (Android)**

1. **Ride Notifications** (`ride_notifications`)

   - High importance
   - Sound, vibration, and lights enabled
   - For ride-related updates

2. **Promotional Notifications** (`promotion_notifications`)

   - Default importance
   - Sound enabled, no vibration
   - For marketing and promotional content

3. **Emergency Alerts** (`emergency_notifications`)
   - Maximum importance
   - Sound, vibration, and lights enabled
   - For critical safety notifications

## Setup Instructions

### 1. **Firebase Configuration**

#### **Android Setup**

1. Add `google-services.json` to `android/app/`
2. Update `android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

3. Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.2.1'
}
```

#### **iOS Setup**

1. Add `GoogleService-Info.plist` to iOS project
2. Update `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

3. Add capabilities in Xcode:
   - Push Notifications
   - Background Modes (Remote notifications)

### 2. **Dependencies**

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^14.6.5
  flutter_local_notifications: ^15.1.0+1
  firebase_core: ^2.15.1
```

### 3. **Firebase Console Setup**

1. **Create Firebase Project**

   - Go to Firebase Console
   - Create new project or use existing
   - Enable Cloud Messaging

2. **Add Apps**

   - Add Android app with package name
   - Add iOS app with bundle ID
   - Download configuration files

3. **Generate Server Key**
   - Go to Project Settings
   - Cloud Messaging tab
   - Copy Server Key for backend integration

### 4. **Firestore Security Rules**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to update their own FCM token
    match /users/{userId} {
      allow update: if request.auth != null &&
        request.auth.uid == userId &&
        request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['fcmToken', 'lastTokenUpdate']);
    }
  }
}
```

## Implementation Guide

### **1. Initialize Notifications**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification services
  final notificationService = NotificationService();
  final notificationManager = NotificationManager();
  await notificationService.initialize();
  await notificationManager.initialize();

  runApp(const MyApp());
}
```

### **2. Update FCM Token on Login**

```dart
class AuthProvider extends ChangeNotifier {
  Future<void> _updateFCMToken(String uid) async {
    try {
      final notificationService = NotificationService();
      final token = await notificationService.getFCMToken();
      await _notificationManager.updateUserFCMToken(uid, token);
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}
```

### **3. Send Ride Request Notification**

```dart
// In your ride booking service
await notificationManager.sendRideRequestToDrivers(
  ride: rideModel,
  riderName: userModel.name,
);
```

### **4. Handle Ride Status Changes**

```dart
// In your ride tracking service
await notificationManager.handleRideStatusChange(
  ride: ride,
  oldStatus: RideStatus.pending,
  newStatus: RideStatus.accepted,
);
```

### **5. Send Custom Notifications**

```dart
// Send promotion to all users
await notificationManager.sendPromotionToAllUsers(
  title: 'Special Offer!',
  body: 'Get 20% off your next ride',
  promotionId: 'promo_001',
);

// Send emergency alert
await notificationManager.sendEmergencyAlert(
  title: 'Emergency Alert',
  body: 'Service temporarily unavailable',
  alertType: 'maintenance',
);
```

## Notification Flow

### **Ride Request Flow**

1. Rider books a ride
2. System finds available drivers
3. Send ride request notification to drivers
4. Driver accepts ride
5. Send confirmation to rider
6. Send ride details to driver

### **Ride Status Flow**

1. Driver starts ride → Notify rider
2. Driver arrives → Notify rider
3. Ride in progress → Update both users
4. Ride completed → Send completion notifications
5. Request feedback → Send reminder to rider

### **Payment Flow**

1. Payment processed → Send confirmation
2. Payment failed → Send retry notification
3. Wallet updated → Send balance notification

## User Experience Features

### **Notification Settings Screen**

- Toggle different notification types
- Clear notification history
- Access system notification settings
- View notification information

### **Smart Notifications**

- Context-aware messaging
- Personalized content
- Location-based alerts
- Time-sensitive notifications

### **Background Handling**

- Notifications work when app is closed
- Proper handling of notification taps
- Deep linking to relevant screens
- State restoration on app launch

## Testing

### **Local Testing**

```dart
// Test local notification
await notificationService._showLocalNotification(
  title: 'Test Notification',
  body: 'This is a test notification',
  channelId: 'ride_notifications',
);
```

### **FCM Testing**

1. Use Firebase Console to send test messages
2. Test with different notification types
3. Verify background and foreground handling
4. Test notification tap behavior

### **Device Testing**

- Test on both Android and iOS devices
- Verify notification permissions
- Test with different app states
- Check notification channels (Android)

## Troubleshooting

### **Common Issues**

1. **Notifications Not Appearing**

   - Check notification permissions
   - Verify FCM token is generated
   - Ensure Firebase is properly configured
   - Check notification channels (Android)

2. **Background Notifications Not Working**

   - Verify iOS capabilities are enabled
   - Check Android manifest permissions
   - Ensure background handler is registered
   - Test with real device (not simulator)

3. **FCM Token Issues**
   - Check Firebase configuration
   - Verify internet connectivity
   - Ensure Firebase project is active
   - Check app signing (Android)

### **Debug Mode**

Enable debug logging:

```dart
// In notification service
static const bool _debugMode = true;

if (_debugMode) {
  print('FCM Token: $token');
  print('Notification sent: $title');
}
```

## Performance Optimization

### **Token Management**

- Update tokens only when necessary
- Handle token refresh properly
- Clean up invalid tokens
- Optimize token storage

### **Notification Batching**

- Group similar notifications
- Avoid notification spam
- Implement rate limiting
- Use notification channels effectively

### **Battery Optimization**

- Minimize background processing
- Use efficient notification delivery
- Implement smart scheduling
- Respect user preferences

## Security Considerations

### **Token Security**

- Store FCM tokens securely
- Validate token authenticity
- Handle token expiration
- Implement token rotation

### **Content Security**

- Validate notification content
- Sanitize user data
- Prevent notification injection
- Implement content filtering

### **Privacy Protection**

- Respect user preferences
- Minimize data collection
- Secure data transmission
- Comply with privacy regulations

## Future Enhancements

### **Planned Features**

1. **Rich Notifications**: Images, actions, and custom layouts
2. **In-App Messaging**: Real-time chat between users
3. **Smart Scheduling**: Intelligent notification timing
4. **Analytics Integration**: Notification performance tracking
5. **A/B Testing**: Notification content optimization

### **Technical Improvements**

1. **Offline Support**: Queue notifications when offline
2. **Advanced Targeting**: Location and behavior-based notifications
3. **Machine Learning**: Smart notification personalization
4. **Multi-language Support**: Localized notification content
5. **Accessibility**: Enhanced support for accessibility features

## Support

### **Documentation**

- Comprehensive API documentation
- Integration guides
- Troubleshooting guides
- Best practices

### **Technical Support**

- Error reporting system
- Debug logging capabilities
- Performance monitoring
- Security audit tools

### **Contact Information**

For technical support or questions about the notification system:

1. Check the error logs in the console
2. Verify Firebase configuration
3. Review notification permissions
4. Contact the development team

## License

This push notification system is part of the GoCab application and follows the same licensing terms.
