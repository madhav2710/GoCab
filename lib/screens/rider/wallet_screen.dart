import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../services/payment_service.dart';
import '../../services/auth_provider.dart';
import '../../widgets/wallet_recharge_widget.dart';
import '../../widgets/payment_history_widget.dart';
import '../../widgets/custom_button.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PaymentService _paymentService = PaymentService();
  WalletModel? _wallet;
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      // Load wallet
      final wallet = await _paymentService.getWallet(user.uid);
      setState(() {
        _wallet = wallet;
      });

      // Listen to wallet updates
      _paymentService.getWalletStream(user.uid).listen((wallet) {
        setState(() {
          _wallet = wallet;
        });
      });

      // Listen to payment history
      _paymentService.getPaymentHistory(user.uid).listen((payments) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      });
    }
  }

  Future<void> _handleRecharge(double amount, PaymentMethod method) async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    try {
      final payment = await _paymentService.rechargeWallet(
        userId: user.uid,
        amount: amount,
        paymentMethod: method,
      );

      if (payment != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet recharged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to recharge wallet. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wallet',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Wallet Balance Card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Available Balance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Recharge Wallet',
                          onPressed: () => _showRechargeDialog(),
                          isLoading: false,
                          backgroundColor: Colors.white,
                          textColor: Colors.blue[600]!,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.blue[600],
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Transactions'),
                      Tab(text: 'Payment Methods'),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Transactions Tab
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: PaymentHistoryWidget(payments: _payments),
                      ),

                      // Payment Methods Tab
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: _buildPaymentMethodsTab(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentMethodsTab() {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<SavedPaymentMethod>>(
      stream: _paymentService.getSavedPaymentMethods(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final paymentMethods = snapshot.data ?? [];

        if (paymentMethods.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No saved payment methods',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a payment method for faster checkout',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Add Payment Method',
                  onPressed: () => _showAddPaymentMethodDialog(),
                  isLoading: false,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  return _buildPaymentMethodCard(method);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Add New Payment Method',
                onPressed: () => _showAddPaymentMethodDialog(),
                isLoading: false,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodCard(SavedPaymentMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method.isDefault ? Colors.blue : Colors.grey[300]!,
          width: method.isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPaymentMethodColor(method.paymentMethod).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPaymentMethodIcon(method.paymentMethod),
              color: _getPaymentMethodColor(method.paymentMethod),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getPaymentMethodText(method.paymentMethod),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getPaymentMethodDetails(method),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deletePaymentMethod(method.id),
            icon: Icon(
              Icons.delete_outline,
              color: Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return Colors.blue;
      case PaymentMethod.upi:
        return Colors.purple;
      case PaymentMethod.card:
        return Colors.orange;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethod.upi:
        return Icons.phone_android;
      case PaymentMethod.card:
        return Icons.credit_card;
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
    }
  }

  String _getPaymentMethodDetails(SavedPaymentMethod method) {
    switch (method.paymentMethod) {
      case PaymentMethod.wallet:
        return 'GoCab Wallet';
      case PaymentMethod.upi:
        return method.upiId ?? 'UPI ID';
      case PaymentMethod.card:
        return '•••• ${method.cardLast4 ?? '****'}';
    }
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: WalletRechargeWidget(
            currentBalance: _wallet?.balance ?? 0.0,
            onRecharge: _handleRecharge,
          ),
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    // TODO: Implement add payment method dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add payment method feature coming soon!'),
      ),
    );
  }

  void _deletePaymentMethod(String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Payment Method',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this payment method?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              _paymentService.deleteSavedPaymentMethod(methodId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
