import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_session.dart';
import 'otp_verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'farmer' | 'buyer'

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    // Validate form first.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final phone = _phoneCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    try {
      /*
       * ============================================================
       * DEV MODE
       * ============================================================
       *
       * Backend is not available yet.
       *
       * IMPORTANT:
       * We do NOT call:
       *   - registerUser()
       *   - requestLoginOtp()
       *
       * Therefore the app will NOT try to connect to:
       * todo-replace-with-backend-url
       *
       * OTP screen will accept:
       * 123456
       */

      if (ApiService.instance.isDevMode) {
        AuthSession.instance
          ..phone = phone
          ..name = name
          ..role = widget.role
          ..userId =
              'dev-user-${DateTime.now().millisecondsSinceEpoch}';

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerifyScreen(
              phone: phone,
              role: widget.role,
            ),
          ),
        );

        return;
      }

      /*
       * ============================================================
       * REAL BACKEND MODE
       * ============================================================
       *
       * This section will execute automatically when the real
       * backend URL replaces the placeholder in ApiService.
       */

      final result = await ApiService.instance.registerUser(
        phone: phone,
        name: name,
        role: widget.role,
      );

      AuthSession.instance
        ..phone = phone
        ..name = name
        ..role = widget.role
        ..userId = result['userId'] as String?;

      // Request real OTP from backend/SMS service.
      await ApiService.instance.requestLoginOtp(phone);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            phone: phone,
            role: widget.role,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
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
    final isFarmer = widget.role == 'farmer';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isFarmer
              ? 'Farmer Registration'
              : 'Buyer Registration',
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,

            child: ListView(
              children: [
                Text(
                  'Enter your details to get started',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 20),

                // --------------------------------------------------
                // NAME
                // --------------------------------------------------

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,

                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),

                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Enter your full name';
                    }

                    if (name.length < 2) {
                      return 'Enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // --------------------------------------------------
                // PHONE
                // --------------------------------------------------

                TextFormField(
                  controller: _phoneCtrl,

                  keyboardType: TextInputType.phone,

                  maxLength: 10,

                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_outlined),
                    counterText: '',
                  ),

                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return 'Enter your mobile number';
                    }

                    if (phone.length != 10) {
                      return 'Enter a valid 10-digit number';
                    }

                    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                      return 'Mobile number must contain only digits';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 6),

                const Text(
                  "We'll send an OTP to verify this number.",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),

                // --------------------------------------------------
                // DEV MODE NOTICE
                // --------------------------------------------------

                if (ApiService.instance.isDevMode) ...[
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.35),
                      ),
                    ),

                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.developer_mode,
                          color: Colors.orange,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DEV MODE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                ),
                              ),

                              SizedBox(height: 4),

                              Text(
                                'Backend is not connected. '
                                'Use OTP 123456 on the next screen.',
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // --------------------------------------------------
                // SEND OTP
                // --------------------------------------------------

                SizedBox(
                  height: 52,

                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : _continue,

                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}