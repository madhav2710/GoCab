import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_model.dart';
import 'payment_method_selector.dart';
import 'custom_button.dart';

class WalletRechargeWidget extends StatefulWidget {
  final double currentBalance;
  final Function(double amount, PaymentMethod method) onRecharge;

  const WalletRechargeWidget({
    super.key,
    required this.currentBalance,
    required this.onRecharge,
  });

  @override
  State<WalletRechargeWidget> createState() => _WalletRechargeWidgetState();
}

class _WalletRechargeWidgetState extends State<WalletRechargeWidget> {
  final List<double> _presetAmounts = [100, 200, 500, 1000, 2000];
  double? _selectedAmount;
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Current Balance',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.currentBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Selection
          Text(
            'Select Amount',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),

          // Preset Amounts
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _presetAmounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amount;
                    _customAmountController.clear();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Custom Amount
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Custom Amount',
              hintText: 'Enter amount',
              prefixText: '₹',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _selectedAmount = double.tryParse(value);
                });
              } else {
                setState(() {
                  _selectedAmount = null;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Payment Method
          PaymentMethodSelector(
            selectedMethod: _selectedPaymentMethod,
            onMethodSelected: (method) {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
            showWallet: false, // Don't show wallet option for recharge
          ),
          const SizedBox(height: 24),

          // Recharge Button
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Recharge Wallet',
              onPressed: _canRecharge() ? _handleRecharge : () {},
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  bool _canRecharge() {
    return _selectedAmount != null &&
        _selectedAmount! > 0 &&
        _selectedPaymentMethod != null;
  }

  void _handleRecharge() {
    if (_canRecharge()) {
      widget.onRecharge(_selectedAmount!, _selectedPaymentMethod!);
    }
  }
}
