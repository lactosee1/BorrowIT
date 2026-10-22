
import 'package:flutter/material.dart';
import '../models/equipment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/borrow_request.dart';

class BorrowRequestScreen extends StatefulWidget {
  final Equipment equipment;

  const BorrowRequestScreen({
    super.key,
    required this.equipment,
  });

  @override
  State<BorrowRequestScreen> createState() =>
      _BorrowRequestScreenState();
}

class _BorrowRequestScreenState
    extends State<BorrowRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _purposeController = TextEditingController();

  DateTime? _borrowDate;
  DateTime? _returnDate;
  bool _isSubmitting = false;

  Future<void> _selectDate({required bool isBorrowDate}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = isBorrowDate
        ? today
        : (_borrowDate ?? today);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isBorrowDate) {
        _borrowDate = selectedDate;

        if (_returnDate != null &&
            _returnDate!.isBefore(selectedDate)) {
          _returnDate = null;
        }
      } else {
        _returnDate = selectedDate;
      }
    });
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    if (_borrowDate == null || _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both borrowing dates.'),
        ),
      );
      return;
    }

    if (!_returnDate!.isAfter(_borrowDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The return date must be after the borrowing date.',
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before submitting a request.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final request = BorrowRequest(
        id: '',
        userId: user.uid,
        equipmentId: widget.equipment.id,
        equipmentName: widget.equipment.name,
        quantity: int.parse(_quantityController.text),
        borrowDate: _borrowDate!,
        returnDate: _returnDate!,
        purpose: _purposeController.text.trim(),
        status: 'Pending',
      );

      await FirebaseFirestore.instance
          .collection('borrowRequests')
          .add(request.toFirestore());

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: ${e.message}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit request: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxQuantity = widget.equipment.quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Equipment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.equipment.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available quantity: $maxQuantity',
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Borrow',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final quantity = int.tryParse(value ?? '');

                if (quantity == null || quantity < 1) {
                  return 'Enter a quantity of at least 1.';
                }

                if (quantity > maxQuantity) {
                  return 'Only $maxQuantity unit(s) are listed.';
                }

                return null;
              },
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Borrow Date'),
              subtitle: Text(
                _borrowDate == null
                    ? 'Choose a date'
                    : MaterialLocalizations.of(context)
                    .formatMediumDate(_borrowDate!),
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () => _selectDate(isBorrowDate: true),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Return Date'),
              subtitle: Text(
                _returnDate == null
                    ? 'Choose a date'
                    : MaterialLocalizations.of(context)
                    .formatMediumDate(_returnDate!),
              ),
              trailing: const Icon(Icons.event_available),
              onTap: _borrowDate == null
                  ? null
                  : () => _selectDate(isBorrowDate: false),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _purposeController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Purpose of Borrowing',
                hintText: 'Explain why you need this equipment.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the purpose of borrowing.';
                }

                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submitRequest,
              icon: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.send),
              label: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  _isSubmitting
                      ? 'Submitting...'
                      : 'Submit Borrow Request',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
