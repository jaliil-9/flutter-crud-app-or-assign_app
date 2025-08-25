import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A reusable confirmation dialog component with Material Design styling
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? confirmButtonColor;
  final Color? confirmTextColor;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.confirmButtonColor,
    this.confirmTextColor,
    this.isDestructive = false,
  });

  /// Factory constructor for delete confirmation dialogs
  factory ConfirmationDialog.delete({
    Key? key,
    required String itemName,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      key: key,
      title: 'Delete $itemName',
      message:
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onConfirm: onConfirm,
      onCancel: onCancel,
      icon: Icons.delete_outline,
      isDestructive: true,
    );
  }

  /// Factory constructor for generic confirmation dialogs
  factory ConfirmationDialog.confirm({
    Key? key,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
  }) {
    return ConfirmationDialog(
      key: key,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine button colors based on destructive action
    final Color effectiveConfirmButtonColor =
        confirmButtonColor ??
        (isDestructive ? colorScheme.error : colorScheme.primary);
    final Color effectiveConfirmTextColor =
        confirmTextColor ??
        (isDestructive ? colorScheme.onError : colorScheme.onPrimary);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDestructive ? colorScheme.error : colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(
            cancelText,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: effectiveConfirmButtonColor,
            foregroundColor: effectiveConfirmTextColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    );
  }

  /// Static method to show a confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  /// Static method to show a delete confirmation dialog
  static Future<bool?> showDelete({
    required BuildContext context,
    required String itemName,
  }) {
    return show(
      context: context,
      title: 'Delete $itemName',
      message:
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDestructive: true,
    );
  }

  /// GetX-based static method to show confirmation dialog
  static Future<bool?> showWithGetX({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    bool isDestructive = false,
  }) {
    return Get.dialog<bool>(
      ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        isDestructive: isDestructive,
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      ),
    );
  }

  /// GetX-based static method to show delete confirmation dialog
  static Future<bool?> showDeleteWithGetX({required String itemName}) {
    return showWithGetX(
      title: 'Delete $itemName',
      message:
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDestructive: true,
    );
  }
}
