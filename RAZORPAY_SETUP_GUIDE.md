# 🚀 Razorpay Integration Setup Guide

## 📋 **Step-by-Step Process**

### **Step 1: Create Razorpay Account**

1. **Visit Razorpay**: Go to https://razorpay.com/
2. **Sign Up**: Click "Sign Up" and create your account
3. **Verify Email**: Complete email verification
4. **Business Details**: Fill in your business information
5. **Account Verification**: Complete KYC process

### **Step 2: Get API Keys**

1. **Login to Dashboard**: Access your Razorpay dashboard
2. **Navigate to Settings**: Go to "Settings" → "API Keys"
3. **Generate Keys**: Click "Generate Key Pair"
4. **Copy Keys**: Save both **Key ID** and **Key Secret**

### **Step 3: Configure Payment Methods**

1. **Payment Methods**: Go to "Settings" → "Payment Methods"
2. **Enable Methods**:
   - ✅ UPI
   - ✅ Credit/Debit Cards
   - ✅ Digital Wallets (Paytm, PhonePe, Google Pay)
3. **Save Settings**: Apply the changes

### **Step 4: Update Configuration**

1. **Open Config File**: Edit `lib/config/razorpay_config.dart`
2. **Replace Placeholders**:

```dart
// Replace these with your actual keys
static const String testKeyId = 'rzp_test_YOUR_ACTUAL_TEST_KEY_ID';
static const String testKeySecret = 'YOUR_ACTUAL_TEST_KEY_SECRET';
```

### **Step 5: Test Integration**

1. **Run the App**: `flutter run`
2. **Test Wallet Recharge**: Try recharging wallet with ₹10
3. **Test Ride Payment**: Book a ride and test payment
4. **Check Logs**: Monitor console for payment logs

---

## 🔧 **Configuration Details**

### **Environment Setup**

```dart
// Development (Test Mode)
static const bool isProduction = false;

// Production (Live Mode)
static const bool isProduction = true;
```

### **API Keys Structure**

```dart
// Test Keys (for development)
static const String testKeyId = 'rzp_test_...';
static const String testKeySecret = '...';

// Live Keys (for production)
static const String liveKeyId = 'rzp_live_...';
static const String liveKeySecret = '...';
```

---

## 🧪 **Testing Process**

### **1. Test Wallet Recharge**

```dart
// Test with small amount
final payment = await paymentService.rechargeWallet(
  userId: user.uid,
  amount: 10.0, // ₹10
  paymentMethod: PaymentMethod.upi,
);
```

### **2. Test Ride Payment**

```dart
// Test ride payment
final payment = await paymentService.processRidePayment(
  userId: user.uid,
  rideId: ride.id,
  amount: 50.0, // ₹50
  paymentMethod: PaymentMethod.wallet,
);
```

### **3. Monitor Debug Logs**

Look for these logs in console:

```
✅ Razorpay initialized successfully
💰 Starting wallet recharge: ₹10.0 via upi
📝 Payment record created: abc123
📋 Razorpay order created: order_xyz
✅ Payment completed and wallet updated
```

---

## 🚨 **Common Issues & Solutions**

### **Issue 1: "Invalid API Key"**

**Solution**:

- Check if you've replaced the placeholder keys
- Verify the key format (starts with `rzp_test_` or `rzp_live_`)
- Ensure you're using test keys for development

### **Issue 2: "Payment Failed"**

**Solution**:

- Check internet connectivity
- Verify Razorpay account status
- Check payment method configuration
- Review error logs in console

### **Issue 3: "Order Creation Failed"**

**Solution**:

- Verify API key permissions
- Check amount format (should be in paise)
- Ensure proper authentication headers

### **Issue 4: "Callback Not Working"**

**Solution**:

- Check callback function setup
- Verify payment status updates
- Monitor Firestore for payment records

---

## 📱 **Payment Flow Testing**

### **Complete Payment Flow**

1. **User selects payment method**
2. **System creates payment record**
3. **Razorpay order is created**
4. **Payment gateway opens**
5. **User completes payment**
6. **Success callback triggered**
7. **Payment status updated**
8. **Wallet balance updated**
9. **Transaction recorded**

### **Error Handling Flow**

1. **Payment validation**
2. **API error handling**
3. **Network error recovery**
4. **User-friendly error messages**
5. **Payment status tracking**

---

## 🔒 **Security Best Practices**

### **1. Key Management**

- ✅ Never commit real keys to version control
- ✅ Use environment variables for production
- ✅ Rotate keys regularly
- ✅ Use test keys for development

### **2. Payment Validation**

- ✅ Validate amounts before processing
- ✅ Check user authentication
- ✅ Verify payment method
- ✅ Handle edge cases

### **3. Error Handling**

- ✅ Comprehensive error messages
- ✅ Graceful failure recovery
- ✅ User-friendly notifications
- ✅ Detailed logging for debugging

---

## 📊 **Monitoring & Analytics**

### **Payment Metrics to Track**

- Total transactions
- Success rate
- Average transaction value
- Payment method distribution
- Error rates

### **Debug Information**

- Payment initiation logs
- API response logs
- Callback execution logs
- Error details

---

## 🚀 **Production Deployment**

### **Before Going Live**

1. ✅ Complete Razorpay KYC
2. ✅ Switch to live API keys
3. ✅ Test with real payments
4. ✅ Set up webhook endpoints
5. ✅ Configure monitoring
6. ✅ Set up error alerts

### **Live Configuration**

```dart
// Set to true for production
static const bool isProduction = true;
```

---

## 📞 **Support & Troubleshooting**

### **Razorpay Support**

- Documentation: https://razorpay.com/docs/
- Support Email: help@razorpay.com
- Developer Community: https://razorpay.com/community/

### **Common Debug Commands**

```bash
# Check payment logs
flutter logs

# Test payment flow
flutter run --debug

# Monitor network requests
flutter run --verbose
```

---

## ✅ **Checklist**

### **Setup Complete When:**

- [ ] Razorpay account created
- [ ] API keys generated
- [ ] Configuration updated
- [ ] Test payment successful
- [ ] Error handling working
- [ ] Debug logs showing
- [ ] Wallet recharge working
- [ ] Ride payment working

---

**🎉 Your Razorpay integration is now ready!**

Follow this guide step by step and your payment system will be fully functional with proper error handling and debugging capabilities.
