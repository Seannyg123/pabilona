import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/friend.dart';
import '../models/transaction.dart';

class AddTransactionDialog extends StatefulWidget {
  final Friend friend;

  const AddTransactionDialog({
    super.key,
    required this.friend,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _type = TransactionType.debt;
  bool _isFullPayment = false;
  bool _youOweThemMode = false;

  @override
  void initState() {
    super.initState();
    // Set initial amount to total debt for payments
    if (widget.friend.totalDebt != 0) {
      _amountController.text = widget.friend.totalDebt.abs().toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleFullPaymentToggle(bool? value) {
    setState(() {
      _isFullPayment = value ?? false;
      if (_isFullPayment) {
        // Set amount to total outstanding debt
        _amountController.text = widget.friend.totalDebt.abs().toStringAsFixed(2);
      }
    });
  }

  void _handleTypeChange(Set<TransactionType> selected) {
    setState(() {
      _type = selected.first;
      if (_type == TransactionType.payment && widget.friend.totalDebt != 0) {
        // Pre-fill with total debt amount for payments
        _amountController.text = widget.friend.totalDebt.abs().toStringAsFixed(2);
        // Show full payment option only for payments
        _isFullPayment = true;
      } else {
        _isFullPayment = false;
      }
    });
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final transactionsBox = Hive.box<Transaction>('transactions');
      final amount = double.parse(_amountController.text);
      
      // Validate payment amount doesn't exceed debt
      if (_type == TransactionType.payment) {
        final totalDebt = widget.friend.totalDebt.abs();
        if (amount > totalDebt) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment amount (₱${amount.toStringAsFixed(2)}) cannot exceed '
                'total debt (₱${totalDebt.toStringAsFixed(2)})',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final transaction = Transaction(
        friendId: widget.friend.id,
        amount: amount,
        type: _type,
        description: _descriptionController.text.trim(),
        youOweThemMode: _youOweThemMode,
      );
      
      // Update friend's total debt
      // For debt: positive means they owe you, negative means you owe them
      if (_type == TransactionType.debt) {
        widget.friend.updateTotalDebt(_youOweThemMode ? -amount : amount);
      } else {
        // For payments: reverse the sign based on who owes whom
        widget.friend.updateTotalDebt(_youOweThemMode ? amount : -amount);
      }
      
      transactionsBox.add(transaction);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == TransactionType.debt
                ? _youOweThemMode 
                    ? 'Added: You owe ₱${amount.toStringAsFixed(2)}'
                    : 'Added: They owe ₱${amount.toStringAsFixed(2)}'
                : _isFullPayment
                    ? 'Recorded full payment of ₱${amount.toStringAsFixed(2)}'
                    : 'Recorded partial payment of ₱${amount.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDebt = widget.friend.totalDebt != 0;
    final isPaymentDisabled = !hasDebt;

    return AlertDialog(
      title: Text('Add Transaction with ${widget.friend.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDebt) ...[
                Text(
                  'Current debt: ₱${widget.friend.totalDebt.abs().toStringAsFixed(2)}\n'
                  '${widget.friend.totalDebt > 0 ? 'They owe you' : 'You owe them'}',
                  style: TextStyle(
                    color: widget.friend.totalDebt > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_type == TransactionType.debt) ...[
                SwitchListTile(
                  title: Text(
                    _youOweThemMode ? 'You Owe Them' : 'They Owe You',
                    style: TextStyle(
                      color: _youOweThemMode ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _youOweThemMode,
                  onChanged: (value) => setState(() => _youOweThemMode = value),
                ),
                const SizedBox(height: 16),
              ],
              SegmentedButton<TransactionType>(
                segments: [
                  ButtonSegment(
                    value: TransactionType.debt,
                    label: Text(_youOweThemMode ? 'You Borrowed' : 'They Borrowed'),
                    icon: const Icon(Icons.arrow_circle_down),
                  ),
                  ButtonSegment(
                    value: TransactionType.payment,
                    label: const Text('Payment Made'),
                    icon: const Icon(Icons.arrow_circle_up),
                    enabled: !isPaymentDisabled,
                  ),
                ],
                selected: {_type},
                onSelectionChanged: _handleTypeChange,
              ),
              const SizedBox(height: 16),
              if (_type == TransactionType.payment && hasDebt) ...[
                CheckboxListTile(
                  title: const Text('Full Payment'),
                  subtitle: Text(
                    'Mark this as a complete payment of ₱${widget.friend.totalDebt.abs().toStringAsFixed(2)}',
                  ),
                  value: _isFullPayment,
                  onChanged: _handleFullPaymentToggle,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱',
                  icon: const Icon(Icons.currency_rupee),
                  helperText: _type == TransactionType.payment
                      ? 'Maximum: ₱${widget.friend.totalDebt.abs().toStringAsFixed(2)}'
                      : null,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                enabled: !(_type == TransactionType.payment && _isFullPayment),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (_type == TransactionType.payment && 
                      amount > widget.friend.totalDebt.abs()) {
                    return 'Payment cannot exceed the total debt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  icon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: const Text('Save Transaction'),
        ),
      ],
    );
  }
} 