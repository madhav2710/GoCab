# 🔥 Firebase Setup Instructions - FIX PERMISSIONS

## **URGENT: Fix Firestore Permissions**

Your app is working correctly, but Firebase Firestore permissions are blocking all operations. Follow these steps to fix it:

### **Step 1: Update Firestore Security Rules**

1. **Go to your Firebase Console:**

   - Visit: https://console.firebase.google.com/
   - Select your project: `go--cab`

2. **Navigate to Firestore Database:**

   - Click on "Firestore Database" in the left sidebar
   - Click on the "Rules" tab

3. **Replace the current rules with the permissive rules:**
   - Copy the content from `firestore_test.rules` file
   - Paste it into the rules editor
   - Click "Publish"

### **Step 2: Create Required Firestore Indexes**

The app also needs some composite indexes. Create these in your Firebase Console:

1. **Go to Firestore Database → Indexes**
2. **Click "Create Index" and add these indexes:**

#### **Index 1: Rides Collection**

- Collection ID: `rides`
- Fields:
  - `riderId` (Ascending)
  - `status` (Ascending)
  - `createdAt` (Descending)

#### **Index 2: Payments Collection**

- Collection ID: `payments`
- Fields:
  - `userId` (Ascending)
  - `createdAt` (Descending)

#### **Index 3: Feedback Collection (Received)**

- Collection ID: `feedback`
- Fields:
  - `toUserId` (Ascending)
  - `createdAt` (Descending)

#### **Index 4: Feedback Collection (Given)**

- Collection ID: `feedback`
- Fields:
  - `fromUserId` (Ascending)
  - `createdAt` (Descending)

### **Step 3: Test the App**

After updating the rules and creating indexes:

1. **Hot reload the app** (press 'r' in the terminal)
2. **Try booking a ride again**
3. **Select a payment method**
4. **Confirm the ride**

The payment should now work without permission errors!

### **Step 4: Security Note**

The `firestore_test.rules` file contains permissive rules for testing. For production, you should use the more secure rules in `firestore.rules` file.

---

## **Quick Fix Commands**

If you want to quickly test with permissive rules, copy this to your Firebase Console Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

This will allow all authenticated users to read/write all documents, which is perfect for testing.
