import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:poolqapp/constants/app_theme.dart';
import 'package:poolqapp/utils/web_platform.dart';

/// In-Flutter install prompt — needed because Flutter's canvas covers the
/// HTML `pwa_install.js` chip on iPhone Safari / Chrome.
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  static const _dismissKey = 'pwa_install_dismissed_ms';
  static const _dismissTtl = Duration(days: 14);

  bool _visible = false;
  bool _expanded = false;
  Timer? _showTimer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb || isWebStandalone || !_shouldShowForPlatform()) return;
    if (_isDismissed()) return;
    _showTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  bool _shouldShowForPlatform() {
    // iOS never gets beforeinstallprompt — always need manual A2HS help.
    return isIosWebBrowser;
  }

  bool _isDismissed() {
    try {
      final raw = GetStorage().read(_dismissKey);
      if (raw == null) return false;
      final ms = raw is int ? raw : int.tryParse('$raw');
      if (ms == null) return false;
      return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms)) <
          _dismissTtl;
    } catch (_) {
      return false;
    }
  }

  void _dismiss() {
    try {
      GetStorage().write(_dismissKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final bottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 12,
      right: 12,
      bottom: bottom + 64,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/poolq12.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Install PoolQ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _expanded
                              ? '1. Tap Share (□↑) at the bottom of Safari\n'
                                  '2. Scroll and tap Add to Home Screen\n'
                                  '3. Tap Add'
                              : 'Add to your Home Screen for the best experience',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    tooltip: 'Dismiss',
                    onPressed: _dismiss,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _expanded = !_expanded),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8F00),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _expanded ? 'Hide steps' : 'Show steps',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _expanded = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'How to install',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
