# Google Maps API Key Setup Guide

## 🚨 **CRITICAL: Fix the Google Maps Crash**

The app is crashing because it needs a valid Google Maps API key. Follow these steps to fix it:

## 📋 **Step 1: Get Google Maps API Key**

### 1. Go to Google Cloud Console

- Visit: https://console.cloud.google.com/
- Sign in with your Google account

### 2. Create a New Project (or select existing)

- Click on the project dropdown at the top
- Click "New Project"
- Name it: `gocab-maps`
- Click "Create"

### 3. Enable Maps SDK

- In the left sidebar, click "APIs & Services" → "Library"
- Search for "Maps SDK for Android"
- Click on it and click "Enable"
- Also enable "Places API" and "Directions API" for full functionality

### 4. Create API Key

- Go to "APIs & Services" → "Credentials"
- Click "Create Credentials" → "API Key"
- Copy the generated API key (starts with `AIzaSy...`)

### 5. Restrict the API Key (Recommended)

- Click on the created API key
- Under "Application restrictions", select "Android apps"
- Add your app's package name: `com.example.gocab`
- Add your SHA-1 fingerprint (see step 6)
- Under "API restrictions", select "Restrict key"
- Select: "Maps SDK for Android", "Places API", "Directions API"
- Click "Save"

## 📱 **Step 2: Get SHA-1 Fingerprint**

### For Debug (Development):

```bash
cd android
./gradlew signingReport
```

Look for the SHA-1 value under "debugAndroidTest" or "debug"

### For Release (Production):

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## 🔧 **Step 3: Update AndroidManifest.xml**

Replace the placeholder in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

## 🚀 **Step 4: Test the App**

1. **Hot reload** the app: `flutter run`
2. **Login as a driver**
3. **Accept a ride** - should no longer crash
4. **Navigate to ride screen** - map should load properly

## 💰 **Cost Information**

- **Google Maps API**: Free tier includes $200 credit monthly
- **Typical usage**: ~$5-20/month for a taxi app
- **Billing**: Set up billing in Google Cloud Console

## 🔒 **Security Best Practices**

1. **Restrict API key** to your app only
2. **Set up billing alerts** to avoid unexpected charges
3. **Monitor usage** in Google Cloud Console
4. **Use different keys** for debug and release builds

## 🆘 **Troubleshooting**

### If still crashing:

1. **Check API key** is correctly placed in AndroidManifest.xml
2. **Verify SHA-1 fingerprint** matches your app
3. **Ensure APIs are enabled** in Google Cloud Console
4. **Check billing** is set up in Google Cloud Console

### Common Errors:

- `API key not found`: Check AndroidManifest.xml
- `API key not valid`: Verify key is correct
- `Quota exceeded`: Check billing setup
- `Access denied`: Check API restrictions

## 📞 **Need Help?**

If you're still having issues:

1. Check Google Cloud Console for error messages
2. Verify all steps above are completed
3. Test with a simple map widget first

---

**Once you have your API key, replace the placeholder in AndroidManifest.xml and the app will work perfectly!** 🎉
