import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/theme_extensions.dart';

class ThemeSettingsWidget extends StatelessWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => Card(
        margin: AppDimensions.paddingAllMedium,
        child: Padding(
          padding: AppDimensions.paddingAllMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Theme Settings',
                style: context.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _buildThemeOption(
                context,
                title: 'Light Theme',
                subtitle: 'Use light theme',
                icon: Icons.light_mode,
                isSelected: themeController.themeMode == ThemeMode.light,
                onTap: () => themeController.setLightMode(),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              _buildThemeOption(
                context,
                title: 'Dark Theme',
                subtitle: 'Use dark theme',
                icon: Icons.dark_mode,
                isSelected: themeController.themeMode == ThemeMode.dark,
                onTap: () => themeController.setDarkMode(),
              ),
              const SizedBox(height: AppDimensions.spacingSmall),
              _buildThemeOption(
                context,
                title: 'System Theme',
                subtitle: 'Follow system settings',
                icon: Icons.brightness_auto,
                isSelected: themeController.themeMode == ThemeMode.system,
                onTap: () => themeController.setSystemMode(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      child: Container(
        padding: AppDimensions.paddingAllMedium,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
          color: isSelected
              ? context.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          border: isSelected
              ? Border.all(color: context.colorScheme.primary, width: 2)
              : Border.all(
                  color: context.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
              size: AppDimensions.iconMedium,
            ),
            const SizedBox(width: AppDimensions.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? context.colorScheme.primary
                          : context.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.colorScheme.primary,
                size: AppDimensions.iconSmall,
              ),
          ],
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => IconButton(
        onPressed: () => themeController.toggleTheme(),
        icon: Icon(themeController.themeModeIcon),
        tooltip:
            'Switch to ${themeController.isDarkMode ? 'Light' : 'Dark'} Theme',
      ),
    );
  }
}

class ThemeCycleButton extends StatelessWidget {
  const ThemeCycleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(
      () => IconButton(
        onPressed: () => themeController.cycleTheme(),
        icon: Icon(themeController.themeModeIcon),
        tooltip: 'Current: ${themeController.themeModeDisplayName}',
      ),
    );
  }
}
