import 'package:flutter/material.dart';
import '../../models/batch.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import 'batch_detail_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  late Future<List<Batch>> _batchesFuture;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    // TODO(WIRING): replace with real device location. Placeholder coords
    // used until location permission flow is wired.
    _batchesFuture = ApiService.instance.fetchNearbyBatches(lat: 0, lng: 0);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _batchesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GroFresh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {}, // TODO: navigate to profile
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Batch>>(
          future: _batchesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _errorState(snapshot.error.toString());
            }
            final batches = (snapshot.data ?? [])
                .where((b) => b.cropName.toLowerCase().contains(_query.toLowerCase()))
                .toList()
              ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _searchBar(),
                const SizedBox(height: 16),
                if (batches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('No batches nearby yet', style: TextStyle(color: AppColors.textMuted))),
                  )
                else
                  ...batches.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BatchCard(batch: b),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      decoration: const InputDecoration(
        hintText: 'Search crop (e.g. Tomato, Wheat)',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _errorState(String message) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Center(child: Text('Could not load batches', style: Theme.of(context).textTheme.titleMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        Center(
          child: TextButton(onPressed: _refresh, child: const Text('Retry')),
        ),
      ],
    );
  }
}

class _BatchCard extends StatelessWidget {
  final Batch batch;
  const _BatchCard({required this.batch});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BatchDetailScreen(batchId: batch.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.border,
                  child: batch.imageUrl != null
                      ? Image.network(batch.imageUrl!, fit: BoxFit.cover)
                      : const Icon(Icons.eco, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.cropName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${batch.quantityKg.toStringAsFixed(0)} kg · ${batch.sellerName}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.accent),
                        Text('${batch.distanceKm.toStringAsFixed(1)} km away',
                            style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${batch.fairPriceMin.toStringAsFixed(0)}-${batch.fairPriceMax.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  const Text('fair price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
