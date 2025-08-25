import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionButtonText;
  final IconData? actionIcon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionButtonText,
    this.actionIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add),
                label: Text(actionButtonText ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyListWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRefresh;
  final VoidCallback? onCreate;

  const EmptyListWidget({
    super.key,
    this.title = 'No items found',
    this.message = 'There are no items to display at the moment.',
    this.onRefresh,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: title,
      message: message,
      icon: Icons.inbox_outlined,
      onAction: onCreate ?? onRefresh,
      actionButtonText: onCreate != null ? 'Create New' : 'Refresh',
      actionIcon: onCreate != null ? Icons.add : Icons.refresh,
    );
  }
}
