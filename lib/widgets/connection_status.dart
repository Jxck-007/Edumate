import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../theme/app_theme.dart';

class ConnectionStatus extends StatelessWidget {
  final ConnectivityResult? connectivityResult;
  final bool isConnectedToBackend;
  final VoidCallback onRetry;

  const ConnectionStatus({
    super.key,
    required this.connectivityResult,
    required this.isConnectedToBackend,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (connectivityResult == ConnectivityResult.none) {
      return _buildStatusBar(
        color: AppTheme.errorColor,
        icon: Icons.wifi_off,
        message: 'No internet connection',
        showRetry: true,
      );
    }

    if (!isConnectedToBackend) {
      return _buildStatusBar(
        color: AppTheme.errorColor,
        icon: Icons.cloud_off,
        message: 'Not connected to server',
        showRetry: true,
      );
    }

    return _buildStatusBar(
      color: AppTheme.successColor,
      icon: Icons.cloud_done,
      message: 'Connected',
      showRetry: false,
    );
  }

  Widget _buildStatusBar({
    required Color color,
    required IconData icon,
    required String message,
    required bool showRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showRetry) ...[
            const Spacer(),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}