class Batch {
  final String id;
  final String cropName;
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? buyerId;
  final String? buyerName;
  final String? buyerPhone;
  final double quantityKg;
  final double fairPriceMin;
  final double fairPriceMax;
  final double? currentBidPrice;
  final double distanceKm;
  final String status;
  final DateTime listedAt;
  final String? imageUrl;
  final List<PricePoint> priceHistory;

  Batch({
    required this.id,
    required this.cropName,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.buyerId,
    this.buyerName,
    this.buyerPhone,
    required this.quantityKg,
    required this.fairPriceMin,
    required this.fairPriceMax,
    this.currentBidPrice,
    required this.distanceKm,
    required this.status,
    required this.listedAt,
    this.imageUrl,
    this.priceHistory = const [],
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      sellerPhone: json['sellerPhone'] as String?,
      buyerId: json['buyerId'] as String?,
      buyerName: json['buyerName'] as String?,
      buyerPhone: json['buyerPhone'] as String?,
      quantityKg: (json['quantityKg'] as num).toDouble(),
      fairPriceMin: (json['fairPriceMin'] as num).toDouble(),
      fairPriceMax: (json['fairPriceMax'] as num).toDouble(),
      currentBidPrice: json['currentBidPrice'] != null
          ? (json['currentBidPrice'] as num).toDouble()
          : null,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      status: json['status'] as String,
      listedAt: DateTime.parse(json['listedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      priceHistory: (json['priceHistory'] as List<dynamic>? ?? [])
          .map(
            (e) => PricePoint.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cropName': cropName,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'quantityKg': quantityKg,
        'fairPriceMin': fairPriceMin,
        'fairPriceMax': fairPriceMax,
        'currentBidPrice': currentBidPrice,
        'distanceKm': distanceKm,
        'status': status,
        'listedAt': listedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'priceHistory': priceHistory.map((e) => e.toJson()).toList(),
      };
}

class PricePoint {
  final DateTime time;
  final double price;
  final String label;

  PricePoint({
    required this.time,
    required this.price,
    required this.label,
  });

  factory PricePoint.fromJson(Map<String, dynamic> json) => PricePoint(
        time: DateTime.parse(json['time'] as String),
        price: (json['price'] as num).toDouble(),
        label: json['label'] as String,
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'price': price,
        'label': label,
      };
}

class OrderStep {
  final String label;
  final bool completed;
  final DateTime? timestamp;

  OrderStep({
    required this.label,
    required this.completed,
    this.timestamp,
  });

  factory OrderStep.fromJson(Map<String, dynamic> json) => OrderStep(
        label: json['label'] as String,
        completed: json['completed'] as bool,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : null,
      );
}