import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';

import '../cubit/partner_auth_cubit.dart';

class PendingApprovalScreen extends StatefulWidget {
  final PartnerPendingApproval state;

  const PendingApprovalScreen({super.key, required this.state});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  Timer? _pollTimer;
  bool _isChecking = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkStatus(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool silent = false}) async {
    if (_isChecking || !mounted) return;
    setState(() {
      _isChecking = true;
      if (!silent) _status = null;
    });
    try {
      final approved =
          await context.read<PartnerAuthCubit>().refreshApprovalStatus();
      if (mounted && !approved) {
        setState(
          () => _status = 'Still pending. We will check again automatically.',
        );
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(
          () => _status = 'Could not check right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 64,
                  color: AppColors.primaryGoldDark,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Approval pending',
                  style: AppTypography.screenTitle,
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.state.salonName} is waiting for admin approval. Booking and salon management will become available after approval.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isChecking ? null : _checkStatus,
                  icon: _isChecking
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('Check approval status'),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<PartnerAuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
