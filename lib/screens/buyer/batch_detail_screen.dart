import 'package:flutter/material.dart';
import '../../models/batch.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/price_graph.dart';
import '../shared/call_button.dart';
import '../shared/chat_screen.dart';
import '../shared/order_tracking_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final String batchId;
  const BatchDetailScreen({super.key, required this.batchId});

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  late Future<Batch> _future;
  final _bidCtrl = TextEditingController();
  bool _placingBid = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchBatchDetail(widget.batchId);
  }

  Future<void> _placeBid() async {
    final amount = double.tryParse(_bidCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid bid amount')));
      return;
    }
    setState(() => _placingBid = true);
    try {
      await ApiService.instance.placeBid(widget.batchId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed')));
        setState(() => _future = ApiService.instance.fetchBatchDetail(widget.batchId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _placingBid = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Details')),
      body: FutureBuilder<Batch>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final batch = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(batch.cropName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Sold by ${batch.sellerName} · ${batch.quantityKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                      label: const Text('Message seller'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            thread: ChatThread(
                              batchId: batch.id,
                              otherPartyId: batch.sellerId,
                              otherPartyName: batch.sellerName,
                              otherPartyPhone: batch.sellerPhone,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (batch.sellerPhone != null) ...[
                    const SizedBox(width: 10),
                    CallButton(phoneNumber: batch.sellerPhone!),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price Journey', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      PriceGraph(
                        points: batch.priceHistory,
                        fairMin: batch.fairPriceMin,
                        fairMax: batch.fairPriceMax,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (batch.status == 'in_transit' || batch.status == 'accepted')
                ElevatedButton.icon(
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Track this order'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderTrackingScreen(batchId: batch.id)),
                  ),
                )
              else ...[
                TextField(
                  controller: _bidCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Your bid (₹) — fair range ₹${batch.fairPriceMin.toStringAsFixed(0)}-${batch.fairPriceMax.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _placingBid ? null : _placeBid,
                  child: _placingBid
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Place Bid'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}