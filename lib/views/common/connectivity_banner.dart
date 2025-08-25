import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/connectivity_helper.dart';

/// Banner widget that shows connectivity status
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          if (!ConnectivityHelper.isConnected) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Theme.of(context).colorScheme.error,
              child: Row(
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.wifi_off,
                      color: Theme.of(context).colorScheme.onError,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No internet connection',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (ConnectivityHelper.isChecking)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        Expanded(child: child),
      ],
    );
  }
}
