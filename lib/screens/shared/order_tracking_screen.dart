import 'package:flutter/material.dart';
import '../../models/batch.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String batchId;
  const OrderTrackingScreen({super.key, required this.batchId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late Future<List<OrderStep>> _future;
  final _otpCtrl = TextEditingController();
  bool _submittingOtp = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiService.instance.fetchOrderSteps(widget.batchId);
  }

  Future<void> _submitOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the OTP shown for delivery')));
      return;
    }
    setState(() => _submittingOtp = true);
    try {
      final ok = await ApiService.instance.submitDeliveryOtp(widget.batchId, otp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Delivery confirmed — payment released' : 'Incorrect OTP, try again')),
        );
        if (ok) setState(_load);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP verification failed: $e')));
    } finally {
      if (mounted) setState(() => _submittingOtp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Tracking')),
      body: FutureBuilder<List<OrderStep>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load tracking: ${snapshot.error}'));
          }
          final steps = snapshot.data ?? [];
          final allDone = steps.isNotEmpty && steps.every((s) => s.completed);
          final atDeliveryStep = steps.isNotEmpty &&
              steps.indexWhere((s) => !s.completed) ==
                  steps.indexWhere((s) => s.label.toLowerCase().contains('deliver'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...List.generate(steps.length, (i) => _stepTile(steps[i], i, steps.length)),
              if (!allDone && atDeliveryStep) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Confirm Delivery', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        const Text(
                          'Enter the OTP to confirm receipt. This releases escrow payment to the farmer.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(labelText: 'Delivery OTP', counterText: ''),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _submittingOtp ? null : _submitOtp,
                          child: _submittingOtp
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirm & Release Payment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (allDone)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text('Order complete — payment released ✅',
                        style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepTile(OrderStep step, int index, int total) {
    final isLast = index == total - 1;
    final color = step.completed ? AppColors.success : AppColors.textMuted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.completed ? AppColors.success : Colors.white,
                  border: Border.all(color: color, width: 2),
                ),
                child: step.completed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.label, style: TextStyle(fontWeight: FontWeight.w700, color: step.completed ? AppColors.textDark : AppColors.textMuted)),
                  if (step.timestamp != null)
                    Text(_formatTs(step.timestamp!), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTs(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
