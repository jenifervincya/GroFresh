import 'package:flutter/material.dart';
import '../../models/batch.dart';
import '../../models/chat.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../shared/call_button.dart';
import '../shared/chat_screen.dart';
import '../shared/order_tracking_screen.dart';
import 'add_batch_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String sellerId;
  const SellerDashboardScreen({super.key, required this.sellerId});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late Future<List<Batch>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ApiService.instance.fetchMyBatches(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Batches')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Batch'),
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddBatchScreen()),
          );
          if (added == true) setState(_load);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: FutureBuilder<List<Batch>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load: ${snapshot.error}'));
            }
            final batches = snapshot.data ?? [];
            if (batches.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No batches listed yet', style: TextStyle(color: AppColors.textMuted))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: batches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _SellerBatchCard(batch: batches[i]),
            );
          },
        ),
      ),
    );
  }
}

class _SellerBatchCard extends StatelessWidget {
  final Batch batch;
  const _SellerBatchCard({required this.batch});

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return AppColors.success;
      case 'in_transit':
        return AppColors.warning;
      case 'bidding':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(batch.cropName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(batch.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    batch.status.replaceAll('_', ' '),
                    style: TextStyle(color: _statusColor(batch.status), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('${batch.quantityKg.toStringAsFixed(0)} kg · fair price ₹${batch.fairPriceMin.toStringAsFixed(0)}-${batch.fairPriceMax.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            if (batch.currentBidPrice != null) ...[
              const SizedBox(height: 4),
              Text('Best bid: ₹${batch.currentBidPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
            if (batch.buyerId != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.primary),
                      label: Text('Message ${batch.buyerName ?? 'buyer'}'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            thread: ChatThread(
                              batchId: batch.id,
                              otherPartyId: batch.buyerId!,
                              otherPartyName: batch.buyerName ?? 'Buyer',
                              otherPartyPhone: batch.buyerPhone,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (batch.buyerPhone != null) ...[
                    const SizedBox(width: 8),
                    CallButton(phoneNumber: batch.buyerPhone!, label: 'Call'),
                  ],
                ],
              ),
            ],
            if (batch.status == 'in_transit' || batch.status == 'accepted') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('View tracking'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderTrackingScreen(batchId: batch.id)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}