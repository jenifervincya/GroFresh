import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class AddBatchScreen extends StatefulWidget {
  const AddBatchScreen({super.key});

  @override
  State<AddBatchScreen> createState() => _AddBatchScreenState();
}

class _AddBatchScreenState extends State<AddBatchScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cropCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  String? _imagePath;
  bool _submitting = false;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final cropName = _cropCtrl.text.trim();
      final quantityKg = double.parse(_qtyCtrl.text.trim());

      await ApiService.instance.createBatch(
        batchData: {
          'cropName': cropName,
          'quantityKg': quantityKg,
          'imageUrl': _imagePath,
          'status': 'listed',
          'listedAt': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.instance.isDevMode
                ? 'Demo batch added successfully'
                : 'Batch listed successfully',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not add batch: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Batch'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ======================================================
              // PHOTO
              // ======================================================

              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Image picker will be connected later.',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Add batch photo',
                          style: TextStyle(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // CROP NAME
              // ======================================================

              TextFormField(
                controller: _cropCtrl,
                decoration: const InputDecoration(
                  labelText: 'Crop name',
                  hintText: 'e.g. Tomato',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter crop name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ======================================================
              // QUANTITY
              // ======================================================

              TextFormField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  hintText: 'e.g. 100',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter quantity';
                  }

                  final quantity =
                      double.tryParse(value.trim());

                  if (quantity == null) {
                    return 'Enter a valid number';
                  }

                  if (quantity <= 0) {
                    return 'Quantity must be greater than 0';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 8),

              const Text(
                'AI fair-price band will be estimated automatically after listing.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // ======================================================
              // SUBMIT
              // ======================================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('List Batch'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}