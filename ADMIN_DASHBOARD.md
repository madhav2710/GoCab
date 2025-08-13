# GoCab Admin Dashboard

## Overview

The GoCab Admin Dashboard is a comprehensive web-based administration panel built with Flutter Web that provides administrators with powerful tools to manage the GoCab platform, monitor rides, handle user accounts, and configure system settings.

## Features

### 🔐 **Admin Authentication**

- Secure login system with Firebase Authentication
- Role-based access control (Super Admin, Admin, Moderator)
- Session management and automatic logout
- Admin privilege validation

### 👥 **User Management**

- View all riders and drivers in the system
- Search and filter users by name, email, and role
- Activate/deactivate user accounts
- Delete user accounts with confirmation
- Real-time user status updates

### 📊 **Ride Analytics**

- Comprehensive ride statistics and metrics
- Real-time ride monitoring
- Revenue tracking and analysis
- Completion rate calculations
- Ride status breakdown (completed, cancelled, pending)
- Recent activity feed

### ⚙️ **System Configuration**

- Platform settings management
- Dynamic configuration updates
- Categorized configuration options
- Real-time configuration changes
- Configuration history tracking

### 📈 **Dashboard Overview**

- Key performance indicators (KPIs)
- User statistics (total users, riders, drivers)
- Ride statistics (total rides, completion rate)
- Revenue metrics
- Feedback and rating analytics

## Technical Architecture

### **Frontend (Flutter Web)**

- **Framework**: Flutter Web with Material Design 3
- **State Management**: Provider pattern
- **UI Components**: Custom widgets with responsive design
- **Navigation**: Tab-based navigation with routing

### **Backend Integration**

- **Firebase Authentication**: Secure admin login
- **Cloud Firestore**: Real-time data synchronization
- **Firebase Security Rules**: Role-based data access
- **Real-time Updates**: Live data streaming

### **Key Components**

#### **AdminService**

Core service for all admin operations:

```dart
class AdminService {
  // Authentication
  Future<bool> isAdmin(String email)
  Future<Map<String, dynamic>?> getAdminData(String email)

  // User Management
  Stream<List<UserModel>> getAllUsers()
  Future<void> updateUserStatus(String userId, bool isActive)
  Future<void> deleteUser(String userId)

  // Analytics
  Stream<QuerySnapshot> getRidesStream()
  Future<Map<String, dynamic>> getRideAnalytics()
  Future<Map<String, dynamic>> getDashboardStats()

  // System Configuration
  Future<List<Map<String, dynamic>>> getSystemConfigs()
  Future<void> updateSystemConfig(String configId, dynamic value, String updatedBy)
}
```

#### **Screens**

- **AdminLoginScreen**: Secure authentication interface
- **AdminDashboardScreen**: Main dashboard with overview and quick actions
- **UserManagementScreen**: Comprehensive user management interface
- **RideAnalyticsScreen**: Detailed ride analytics and reporting
- **SystemConfigScreen**: System configuration management

## Setup Instructions

### 1. **Firebase Configuration**

Ensure your Firebase project is properly configured:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

### 2. **Admin Collection Setup**

Create the `admins` collection in Firestore with the following structure:

```json
{
  "email": "admin@gocab.com",
  "name": "Admin User",
  "role": "super_admin",
  "permissions": [
    "manage_users",
    "view_analytics",
    "manage_config",
    "delete_users"
  ],
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z",
  "isActive": true
}
```

### 3. **System Configurations**

Create the `system_configs` collection with default configurations:

```json
{
  "key": "max_ride_distance",
  "value": 50.0,
  "description": "Maximum allowed ride distance in kilometers",
  "category": "Ride Settings",
  "updatedAt": "2024-01-01T00:00:00Z",
  "updatedBy": "system"
}
```

### 4. **Firebase Security Rules**

Configure Firestore security rules for admin access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admin access
    match /admins/{adminId} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    // User management
    match /users/{userId} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }

    // System configurations
    match /system_configs/{configId} {
      allow read, write: if request.auth != null &&
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
  }
}
```

### 5. **Running the Admin Dashboard**

#### **Development Mode**

```bash
# Run Flutter Web
flutter run -d chrome --web-port 8080

# Or run the admin-specific entry point
flutter run -d chrome --web-port 8080 -t lib/main_admin.dart
```

#### **Production Build**

```bash
# Build for web
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

## Usage Guide

### **Admin Login**

1. Navigate to the admin dashboard URL
2. Enter admin email and password
3. System validates admin privileges
4. Redirect to main dashboard on successful login

### **User Management**

1. **View Users**: Browse all users with search and filter options
2. **Filter by Role**: Toggle between riders and drivers
3. **Search Users**: Search by name or email address
4. **Manage Status**: Activate/deactivate user accounts
5. **Delete Users**: Remove users with confirmation dialog

### **Ride Analytics**

1. **Overview Tab**: View key metrics and recent activity
2. **Detailed Tab**: Access detailed analytics and charts
3. **Reports Tab**: Generate and export reports
4. **Real-time Updates**: Live data streaming from Firestore

### **System Configuration**

1. **Browse Configs**: View all system configurations by category
2. **Edit Values**: Click on configuration values to edit
3. **Save Changes**: Press Enter or click outside to save
4. **Category Filter**: Configurations are organized by category

## Security Features

### **Authentication & Authorization**

- Firebase Authentication integration
- Role-based access control
- Session management
- Secure token handling

### **Data Protection**

- Firestore security rules
- Admin-only data access
- Input validation and sanitization
- Secure API communication

### **Audit Trail**

- Configuration change tracking
- Admin action logging
- User modification history
- System access monitoring

## Performance Optimization

### **Real-time Updates**

- Firestore streams for live data
- Efficient data synchronization
- Optimized query patterns
- Minimal network requests

### **UI/UX Optimization**

- Responsive design for all screen sizes
- Fast loading times
- Smooth animations
- Intuitive navigation

### **Data Management**

- Efficient data pagination
- Smart caching strategies
- Optimized database queries
- Minimal memory usage

## Troubleshooting

### **Common Issues**

1. **Admin Login Fails**

   - Verify admin account exists in Firestore
   - Check Firebase Authentication setup
   - Ensure admin account is active

2. **Data Not Loading**

   - Check Firestore security rules
   - Verify Firebase configuration
   - Check network connectivity

3. **Configuration Updates Fail**
   - Verify admin permissions
   - Check Firestore write permissions
   - Validate configuration data format

### **Debug Mode**

Enable debug logging by setting:

```dart
static const bool _debugMode = true;
```

### **Error Handling**

- Comprehensive error messages
- User-friendly error displays
- Graceful fallback mechanisms
- Detailed error logging

## Future Enhancements

### **Planned Features**

1. **Advanced Analytics**: Machine learning insights
2. **User Communication**: In-app messaging system
3. **Bulk Operations**: Mass user management
4. **Export Functionality**: Data export capabilities
5. **Notification System**: Real-time admin notifications

### **Technical Improvements**

1. **Offline Support**: Offline data access
2. **Advanced Filtering**: Complex search and filter options
3. **Data Visualization**: Interactive charts and graphs
4. **API Integration**: Third-party service integration
5. **Mobile Responsiveness**: Enhanced mobile experience

## Support

### **Documentation**

- Comprehensive API documentation
- User guides and tutorials
- Video demonstrations
- FAQ section

### **Technical Support**

- Error reporting system
- Debug logging capabilities
- Performance monitoring
- Security audit tools

### **Contact Information**

For technical support or questions about the admin dashboard:

1. Check the error logs in the console
2. Verify Firebase configuration
3. Review security rules
4. Contact the development team

## License

This admin dashboard is part of the GoCab application and follows the same licensing terms.
