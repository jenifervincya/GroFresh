import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/api/api_service.dart';
import '../../services/auth_session.dart';
import '../../core/theme/app_theme.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phone;
  final String role;
  const OtpVerifyScreen({super.key, required this.phone, required this.role});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ApiService.instance.requestLoginOtp(widget.phone);
      _startTimer();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP resent')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not resend OTP: $e')));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the OTP')));
      return;
    }
    setState(() => _verifying = true);
    try {
      final result = await ApiService.instance.verifyLoginOtp(widget.phone, otp);
      // TODO(WIRING): confirm response field names with Jeni (token/userId).
      final token = result['token'] as String?;
      AuthSession.instance.authToken = token;
      AuthSession.instance.userId ??= result['userId'] as String?;
      if (token != null) ApiService.instance.setAuthToken(token);

      if (!mounted) return;

      // TODO: once KYC screen is built, route farmers there before the app
      // instead of straight to ProfileSwitcherScreen (buyers can skip KYC).
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProfileSwitcherScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text('Enter the code sent to +91 ${widget.phone}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),
            const SizedBox(height: 16),
            Center(
              child: _secondsLeft > 0
                  ? Text('Resend OTP in ${_secondsLeft}s', style: const TextStyle(color: AppColors.textMuted))
                  : TextButton(
                      onPressed: _resending ? null : _resend,
                      child: _resending ? const Text('Resending...') : const Text('Resend OTP'),
                    ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Verify & Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
