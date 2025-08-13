// Razorpay Configuration
// Updated with real Razorpay API keys

class RazorpayConfig {
  // Test Keys (for development) - REAL KEYS
  static const String testKeyId = 'rzp_test_R4wE6pF8Yl194x';
  static const String testKeySecret = 'kdC7Hk5YgJkOZ54ZzS2TcdwD';
  
  // Live Keys (for production) - Replace with live keys when ready
  static const String liveKeyId = 'rzp_live_REPLACE_WITH_YOUR_LIVE_KEY_ID';
  static const String liveKeySecret = 'REPLACE_WITH_YOUR_LIVE_KEY_SECRET';
  
  // Current environment
  static const bool isProduction = false; // Set to true for production
  
  // Get current keys based on environment
  static String get razorpayKeyId => isProduction ? liveKeyId : testKeyId;
  static String get razorpayKeySecret =>
      isProduction ? liveKeySecret : testKeySecret;
  
  // API Base URL
  static const String baseUrl = 'https://api.razorpay.com/v1';
  
  // Currency
  static const String currency = 'INR';
  
  // Company details
  static const String companyName = 'GoCab';
  static const String companyDescription = 'Your trusted ride partner';
  
  // Theme colors
  static const String primaryColor = '#3399cc';
  static const String secondaryColor = '#2c3e50';
  
  // Supported payment methods
  static const List<String> supportedWallets = [
    'paytm',
    'phonepe',
    'gpay',
    'amazonpay',
    'freecharge',
  ];
  
  // Debug mode - Disabled for production
  static const bool debugMode = false;
}
