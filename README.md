# GoCab - Taxi Booking App

A Flutter-based taxi booking application similar to Uber, with Firebase authentication and role-based user management.

## Features

- **Email Authentication**: Sign up and login using email/password
- **Role-Based Access**: Register as either a Rider or Driver
- **Firebase Integration**: User data stored in Firestore
- **Modern UI**: Clean and intuitive user interface
- **Responsive Design**: Works on various screen sizes

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── user_model.dart       # User data model
├── services/
│   ├── auth_service.dart     # Firebase authentication
│   └── auth_provider.dart    # State management
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── rider/
│   │   └── rider_home_screen.dart
│   └── driver/
│       └── driver_home_screen.dart
└── widgets/
    ├── custom_button.dart
    └── custom_text_field.dart
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project

### 1. Clone the Repository

```bash
git clone <repository-url>
cd gocab
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. **Create a Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one
   - Enable Authentication with Email/Password
   - Create a Firestore database

2. **Configure Android**:
   - Download `google-services.json` from Firebase Console
   - Replace the placeholder file in `android/app/google-services.json`
   - Update the package name in `android/app/build.gradle.kts` if needed

3. **Configure iOS** (if needed):
   - Download `GoogleService-Info.plist` from Firebase Console
   - Add it to your iOS project

### 4. Run the App

```bash
flutter run
```

## Usage

### For Riders:
1. Sign up with email, password, name, phone, and select "Rider" role
2. Login with your credentials
3. Access the rider dashboard with booking options

### For Drivers:
1. Sign up with email, password, name, phone, and select "Driver" role
2. Login with your credentials
3. Access the driver dashboard with online/offline toggle

## Dependencies

- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database operations
- `provider`: State management
- `google_fonts`: Custom typography
- `flutter_svg`: SVG support
- `shared_preferences`: Local storage
- `image_picker`: Image selection
- `geolocator`: Location services
- `geocoding`: Address geocoding

## Firebase Configuration

The app uses the following Firebase services:
- **Authentication**: Email/password sign-in
- **Firestore**: User data storage
- **Security Rules**: Configure appropriate read/write permissions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please open an issue in the repository or contact the development team.
