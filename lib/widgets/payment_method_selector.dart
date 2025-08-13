import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/payment_model.dart';

class PaymentMethodSelector extends StatefulWidget {
  final PaymentMethod? selectedMethod;
  final Function(PaymentMethod) onMethodSelected;
  final double? walletBalance;
  final bool showWallet;

  const PaymentMethodSelector({
    super.key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.walletBalance,
    this.showWallet = true,
  });

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.showWallet) ...[
          _buildPaymentOption(
            PaymentMethod.wallet,
            'Wallet',
            'Pay using your GoCab wallet',
            Icons.account_balance_wallet,
            Colors.blue,
            widget.walletBalance != null ? '₹${widget.walletBalance!.toStringAsFixed(2)}' : null,
          ),
          const SizedBox(height: 12),
        ],
        _buildPaymentOption(
          PaymentMethod.upi,
          'UPI',
          'Pay using UPI apps',
          Icons.phone_android,
          Colors.purple,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          PaymentMethod.card,
          'Card',
          'Credit or Debit card',
          Icons.credit_card,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color color, [
    String? balance,
  ]) {
    final isSelected = widget.selectedMethod == method;
    
    return GestureDetector(
      onTap: () => widget.onMethodSelected(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
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
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (balance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            balance,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
