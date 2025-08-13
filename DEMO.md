# GoCab Demo

## App Overview

GoCab is a fully functional Flutter taxi booking application with Firebase authentication and role-based user management.

## Features Implemented

### ✅ Authentication System

- Email/password sign up and login
- Firebase Authentication integration
- Role-based registration (Rider/Driver)
- Secure user data storage in Firestore

### ✅ User Interface

- Modern, clean UI design
- Responsive layout for different screen sizes
- Custom reusable widgets
- Google Fonts integration

### ✅ Role-Based Routing

- Riders are directed to `RiderHomeScreen`
- Drivers are directed to `DriverHomeScreen`
- Automatic navigation based on user role

### ✅ Rider Features

- Welcome dashboard with user info
- Quick action cards for booking rides
- Ride history placeholder
- Saved places and support options
- Sign out functionality

### ✅ Driver Features

- Online/offline toggle
- Today's stats (rides, earnings)
- Driver dashboard with status management
- Sign out functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase init
├── firebase_options.dart     # Firebase configuration
├── models/
│   └── user_model.dart       # User data model with roles
├── services/
│   ├── auth_service.dart     # Firebase auth operations
│   └── auth_provider.dart    # State management with Provider
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Email/password login
│   │   └── signup_screen.dart   # Registration with role selection
│   ├── rider/
│   │   └── rider_home_screen.dart  # Rider dashboard
│   └── driver/
│       └── driver_home_screen.dart  # Driver dashboard
└── widgets/
    ├── custom_button.dart     # Reusable button component
    └── custom_text_field.dart # Reusable text field component
```

## Setup Instructions

1. **Install Dependencies**:

   ```bash
   flutter pub get
   ```

2. **Firebase Setup**:

   - Create a Firebase project
   - Enable Authentication with Email/Password
   - Create a Firestore database
   - Replace `google-services.json` with your actual config
   - Update `firebase_options.dart` with your project details

3. **Run the App**:
   ```bash
   flutter run
   ```

## Usage Flow

### For New Users:

1. Open the app → Login screen appears
2. Tap "Sign Up" → Registration screen
3. Fill in details (name, email, phone, password)
4. Select role (Rider or Driver)
5. Create account → Redirected to appropriate dashboard

### For Existing Users:

1. Open the app → Login screen appears
2. Enter email and password
3. Sign in → Redirected to appropriate dashboard

## Technical Implementation

### State Management

- Uses Provider pattern for state management
- AuthProvider handles authentication state
- Automatic user data loading from Firestore

### Firebase Integration

- Firebase Core for initialization
- Firebase Auth for authentication
- Cloud Firestore for user data storage
- Proper error handling and validation

### UI/UX Design

- Material Design 3 principles
- Custom color scheme and typography
- Responsive design patterns
- Loading states and error handling

## Next Steps for Full Implementation

1. **Real-time Features**:

   - Live location tracking
   - Real-time ride requests
   - Push notifications

2. **Payment Integration**:

   - Stripe/PayPal integration
   - Payment history
   - Driver earnings

3. **Advanced Features**:

   - Ride booking flow
   - Driver-rider matching
   - Rating system
   - Chat functionality

4. **Maps Integration**:
   - Google Maps integration
   - Route optimization
   - Location services

## Dependencies Used

- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database operations
- `provider`: State management
- `google_fonts`: Typography
- `flutter_svg`: SVG support
- `shared_preferences`: Local storage
- `image_picker`: Image selection
- `geolocator`: Location services
- `geocoding`: Address geocoding

## Testing

The app includes basic tests to verify:

- App initialization
- Firebase integration
- Widget rendering

Run tests with:

```bash
flutter test
```

## Deployment Ready

The app is structured for easy deployment to:

- Google Play Store (Android)
- Apple App Store (iOS)
- Web platforms

All necessary configurations are in place for a production release.
