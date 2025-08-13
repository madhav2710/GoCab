# 🔥 Firebase Setup Guide for GoCab

## **Step 1: Create Firebase Project**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `gocab-app`
4. Enable Google Analytics (optional)
5. Click "Create project"

## **Step 2: Add Android App**

1. In Firebase Console, click "Add app" → "Android"
2. Package name: `com.example.gocab`
3. App nickname: `GoCab`
4. Click "Register app"
5. Download `google-services.json`
6. Place it in `android/app/google-services.json`

## **Step 3: Enable Authentication**

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password"
5. Click "Save"

## **Step 4: Create Firestore Database**

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select location closest to your users
5. Click "Done"

## **Step 5: Set Security Rules**

1. In Firestore Database, go to "Rules" tab
2. Replace the rules with the content from `firestore.rules` file
3. Click "Publish"

## **Step 6: Create Required Indexes**

### **Rides Collection Indexes:**
1. Go to "Indexes" tab in Firestore
2. Click "Create index"
3. Collection ID: `rides`
4. Fields:
   - `riderId` (Ascending)
   - `status` (Ascending)
   - `createdAt` (Descending)
5. Click "Create"

### **Feedback Collection Indexes:**
1. Collection ID: `feedback`
2. Fields:
   - `toUserId` (Ascending)
   - `createdAt` (Descending)
3. Click "Create"

4. Collection ID: `feedback`
5. Fields:
   - `fromUserId` (Ascending)
   - `createdAt` (Descending)
6. Click "Create"

## **Step 7: Enable Cloud Messaging**

1. In Firebase Console, go to "Cloud Messaging"
2. Click "Get started"
3. Note down the Server key (you'll need this for notifications)

## **Step 8: Update Firebase Options**

1. Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project values
2. You can get these values from the Firebase Console under Project Settings

## **Step 9: Test the Setup**

1. Run the app: `flutter run`
2. Try to sign up a new user
3. Check if the user appears in Firebase Authentication
4. Check if user data appears in Firestore

## **Troubleshooting**

### **If you get permission errors:**
- Make sure Firestore rules are published
- Check if the user is authenticated
- Verify collection names match exactly

### **If you get index errors:**
- Create the required indexes as shown above
- Wait for indexes to build (can take a few minutes)
- The app will work with fallback queries while indexes are building

### **If authentication doesn't work:**
- Verify `google-services.json` is in the correct location
- Check if Email/Password authentication is enabled
- Make sure the package name matches exactly

## **Production Considerations**

Before going to production:
1. Update Firestore rules to be more restrictive
2. Set up proper authentication methods
3. Configure Cloud Functions for server-side logic
4. Set up monitoring and analytics
5. Configure proper error handling and logging
