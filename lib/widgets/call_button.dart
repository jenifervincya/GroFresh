import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';

/// Opens the phone's native dialer pre-filled with [phoneNumber]. No
/// in-app/VoIP calling — this is intentional: real in-app calling needs a
/// telephony backend (Twilio/Exotel-style) which isn't wired yet.
/// TODO(FUTURE): swap to an in-app VoIP call once backend telephony exists,
/// if the team wants call recording / masked numbers for trust reasons.
Future<void> _launchDialer(BuildContext context, String phoneNumber) async {
  final uri = Uri(scheme: 'tel', path: phoneNumber);
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open dialer for $phoneNumber')),
    );
  }
}

/// Compact icon-only call button, for app bars.
class CallIconButton extends StatelessWidget {
  final String phoneNumber;
  const CallIconButton({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.call_outlined),
      tooltip: 'Call',
      onPressed: () => _launchDialer(context, phoneNumber),
    );
  }
}

/// Full-width labeled call button, for detail screens.
class CallButton extends StatelessWidget {
  final String phoneNumber;
  final String label;
  const CallButton({super.key, required this.phoneNumber, this.label = 'Call'});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _launchDialer(context, phoneNumber),
      icon: const Icon(Icons.call_outlined, color: AppColors.primary),
      label: Text(label),
    );
  }
}
