import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationManager _notificationManager = NotificationManager();

  bool _rideNotifications = true;
  bool _promotionNotifications = true;
  bool _emergencyNotifications = true;
  bool _paymentNotifications = true;
  bool _feedbackNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      // final settings = await _notificationManager.getNotificationSettings();
      final isEnabled = await _notificationManager.areNotificationsEnabled();

      if (mounted) {
        setState(() {
          _isLoading = false;
          // In a real app, you would load these from user preferences
          _rideNotifications = isEnabled;
          _promotionNotifications = isEnabled;
          _emergencyNotifications = isEnabled;
          _paymentNotifications = isEnabled;
          _feedbackNotifications = isEnabled;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateNotificationSetting(String type, bool value) async {
    try {
      // In a real app, you would save this to user preferences
      // For now, we'll just update the local state
      setState(() {
        switch (type) {
          case 'ride':
            _rideNotifications = value;
            break;
          case 'promotion':
            _promotionNotifications = value;
            break;
          case 'emergency':
            _emergencyNotifications = value;
            break;
          case 'payment':
            _paymentNotifications = value;
            break;
          case 'feedback':
            _feedbackNotifications = value;
            break;
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification settings updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notification settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationManager.clearAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required String type,
    required bool value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Switch(
          value: value,
          onChanged: (newValue) => _updateNotificationSetting(type, newValue),
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _clearAllNotifications,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: Colors.blue[600],
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Notifications',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose which notifications you want to receive',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification Types
                  Text(
                    'Notification Types',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildNotificationTile(
                    title: 'Ride Notifications',
                    subtitle:
                        'Get updates about your ride status, driver arrival, and ride completion',
                    type: 'ride',
                    value: _rideNotifications,
                    icon: Icons.local_taxi,
                    iconColor: Colors.green,
                  ),

                  _buildNotificationTile(
                    title: 'Promotional Notifications',
                    subtitle:
                        'Receive offers, discounts, and promotional messages',
                    type: 'promotion',
                    value: _promotionNotifications,
                    icon: Icons.local_offer,
                    iconColor: Colors.orange,
                  ),

                  _buildNotificationTile(
                    title: 'Emergency Alerts',
                    subtitle:
                        'Important safety alerts and emergency notifications',
                    type: 'emergency',
                    value: _emergencyNotifications,
                    icon: Icons.warning,
                    iconColor: Colors.red,
                  ),

                  _buildNotificationTile(
                    title: 'Payment Notifications',
                    subtitle:
                        'Payment confirmations, receipts, and wallet updates',
                    type: 'payment',
                    value: _paymentNotifications,
                    icon: Icons.payment,
                    iconColor: Colors.purple,
                  ),

                  _buildNotificationTile(
                    title: 'Feedback Reminders',
                    subtitle:
                        'Reminders to rate your ride and provide feedback',
                    type: 'feedback',
                    value: _feedbackNotifications,
                    icon: Icons.star,
                    iconColor: Colors.amber,
                  ),

                  const SizedBox(height: 32),

                  // Additional Settings
                  Text(
                    'Additional Settings',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'System Notification Settings',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Manage notification permissions in system settings',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // In a real app, this would open system notification settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Open system notification settings'),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.clear_all,
                          color: Colors.red[600],
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Clear All Notifications',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                      subtitle: Text(
                        'Remove all notification history',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      onTap: _clearAllNotifications,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notification Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• Emergency alerts cannot be disabled for safety reasons\n'
                          '• Ride notifications are essential for a smooth experience\n'
                          '• You can change these settings at any time\n'
                          '• Notifications are sent based on your location and preferences',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
