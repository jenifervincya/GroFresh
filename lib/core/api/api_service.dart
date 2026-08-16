import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/batch.dart';
import '../../models/chat.dart';


/// Single source of truth for backend communication.
///
/// SCOPE NOTE FOR TAMIL: This is the ONLY file that should change when
/// wiring real endpoints. Every screen calls through here — never call
/// `http` directly from a screen widget.
///
/// TODO(WIRING): Replace [baseUrl] with the real backend URL from Jeni
/// once available. TODO(WIRING): confirm auth header format (Bearer JWT
/// assumed below) — update [_headers] if different.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // TODO(WIRING): set real base URL, e.g. https://api.farmora.app/v1
  String baseUrl = 'https://TODO-REPLACE-WITH-BACKEND-URL/v1';

  /// True while [baseUrl] is still the placeholder — i.e. no real backend
  /// connected yet. Used to enable the dev OTP bypass below so the app is
  /// demoable before Jeni's backend is live.
  /// REMOVE THIS FLAG (and the bypass block below) once baseUrl is real.
  bool get isDevMode => baseUrl.contains('TODO-REPLACE');
  bool get _isDevMode => isDevMode;
  static const String devOtpCode = '123456';

  String? _authToken;

  void setAuthToken(String token) => _authToken = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ---------------- AUTH / REGISTRATION / KYC ----------------

  /// TODO(WIRING): confirm endpoint path + payload shape with Jeni.
  Future<Map<String, dynamic>> registerUser({
    required String phone,
    required String name,
    required String role, // 'farmer' | 'buyer'
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'name': name, 'role': role}),
    );
    _checkOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Sends OTP to phone for login/registration verification.
  /// TODO(WIRING): confirm this reuses the delivery-OTP service or is separate.
  Future<void> requestLoginOtp(String phone) async {
    if (_isDevMode) {
      // DEV BYPASS: no backend/SMS gateway connected yet. Pretend the OTP
      // was sent — real code is [devOtpCode]. Remove once baseUrl is real.
      await Future.delayed(const Duration(milliseconds: 400));
      return;
    }
    final res = await http.post(
      Uri.parse('$baseUrl/auth/otp/request'),
      headers: _headers,
      body: jsonEncode({'phone': phone}),
    );
    _checkOk(res);
  }

  Future<Map<String, dynamic>> verifyLoginOtp(String phone, String otp) async {
    if (_isDevMode) {
      // DEV BYPASS: accept the fixed dev code without hitting a backend.
      // Remove once baseUrl is real.
      await Future.delayed(const Duration(milliseconds: 400));
      if (otp != devOtpCode) {
        throw ApiException(401, 'Invalid OTP (dev mode: use $devOtpCode)');
      }
      return {
        'token': 'dev-token',
        'userId': 'dev-user-${phone.hashCode}',
      };
    }
    final res = await http.post(
      Uri.parse('$baseUrl/auth/otp/verify'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    _checkOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// KYC document submission (ID proof, land record etc for farmers).
  /// TODO(WIRING): confirm file upload mechanism — multipart vs base64 vs
  /// pre-signed URL. Stubbed as multipart here.
  Future<Map<String, dynamic>> submitKyc({
    required String userId,
    required String idType,
    required String idNumber,
    String? documentFilePath,
  }) async {
    final uri = Uri.parse('$baseUrl/kyc/submit');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers..remove('Content-Type'));
    request.fields['userId'] = userId;
    request.fields['idType'] = idType;
    request.fields['idNumber'] = idNumber;
    if (documentFilePath != null) {
      request.files.add(await http.MultipartFile.fromPath('document', documentFilePath));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------- BATCHES (BUYER BROWSE) ----------------

  /// TODO(WIRING): confirm query params for nearest-first sort (lat/lng vs
  /// server-side geo lookup by user id).
  Future<List<Batch>> fetchNearbyBatches({
    required double lat,
    required double lng,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/batches?lat=$lat&lng=$lng&sort=nearest'),
      headers: _headers,
    );
    _checkOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Batch.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Batch> fetchBatchDetail(String batchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/batches/$batchId'),
      headers: _headers,
    );
    _checkOk(res);
    return Batch.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> placeBid(String batchId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/batches/$batchId/bids'),
      headers: _headers,
      body: jsonEncode({'amount': amount}),
    );
    _checkOk(res);
  }

  // ---------------- SELLER ----------------

  Future<List<Batch>> fetchMyBatches(String sellerId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/sellers/$sellerId/batches'),
      headers: _headers,
    );
    _checkOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Batch.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// TODO(WIRING): confirm field names for AI fair-price band request —
  /// depends on Neha's pricing engine contract.
  Future<Map<String, dynamic>> addBatch({
    required String cropName,
    required double quantityKg,
    String? imageFilePath,
  }) async {
    final uri = Uri.parse('$baseUrl/batches');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers..remove('Content-Type'));
    request.fields['cropName'] = cropName;
    request.fields['quantityKg'] = quantityKg.toString();
    if (imageFilePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imageFilePath));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> acceptBid(String batchId, String bidId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/batches/$batchId/bids/$bidId/accept'),
      headers: _headers,
    );
    _checkOk(res);
  }

  // ---------------- ORDER TRACKING / DELIVERY OTP ----------------

  Future<List<OrderStep>> fetchOrderSteps(String batchId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/batches/$batchId/tracking'),
      headers: _headers,
    );
    _checkOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => OrderStep.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Submits the delivery OTP entered in-app. On success, backend triggers
  /// escrow release (Jeni's EscrowService / PAYMENT_RELEASED event).
  /// TODO(WIRING): confirm response shape — does it return updated order
  /// steps directly, or should we re-fetch?
  Future<bool> submitDeliveryOtp(String batchId, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/batches/$batchId/delivery/verify-otp'),
      headers: _headers,
      body: jsonEncode({'otp': otp}),
    );
    _checkOk(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['success'] == true;
  }

  // ---------------- SMS / IVR TRIGGERS ----------------

  /// Fires a templated SMS/IVR notification. Template keys should match
  /// what's registered server-side (or with the SMS gateway) — see
  /// lib/services/notification_templates.dart for the multilingual key list.
  /// TODO(WIRING): confirm whether SMS sending is triggered by the backend
  /// automatically on events (bid placed, delivery done) or whether the app
  /// must explicitly call this for certain flows (e.g. manual reminder).
  Future<void> triggerNotification({
    required String userId,
    required String templateKey,
    required String languageCode,
    Map<String, String> params = const {},
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/notifications/trigger'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'templateKey': templateKey,
        'language': languageCode,
        'params': params,
      }),
    );
    _checkOk(res);
  }

  // ---------------- CHAT (BUYER \u2194 SELLER) ----------------

  /// In-memory dev store so chat is demoable before the real backend/socket
  /// channel exists. Keyed by batchId. REMOVE once real endpoints are wired.
  final Map<String, List<ChatMessage>> _devChatStore = {};

  /// Fetches message history for a batch-scoped conversation.
  /// TODO(WIRING): confirm endpoint + whether this should be a websocket
  /// stream instead of polling, for real-time delivery.
  Future<List<ChatMessage>> fetchMessages(String batchId) async {
    if (_isDevMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      return List.unmodifiable(_devChatStore[batchId] ?? []);
    }
    final res = await http.get(
      Uri.parse('$baseUrl/batches/$batchId/messages'),
      headers: _headers,
    );
    _checkOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessage> sendMessage(String batchId, String senderId, String text) async {
    if (_isDevMode) {
      await Future.delayed(const Duration(milliseconds: 200));
      final msg = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        senderId: senderId,
        text: text,
        sentAt: DateTime.now(),
      );
      _devChatStore.putIfAbsent(batchId, () => []).add(msg);
      return msg;
    }
    final res = await http.post(
      Uri.parse('$baseUrl/batches/$batchId/messages'),
      headers: _headers,
      body: jsonEncode({'text': text}),
    );
    _checkOk(res);
    return ChatMessage.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode): $body';
}