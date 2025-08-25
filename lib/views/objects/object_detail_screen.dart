import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../services/navigation_service.dart';
import '../../services/feedback_service.dart';
import '../../services/logging_service.dart';
import 'widgets/loading_widget.dart';
import '../common/confirmation_dialog.dart';
import '../common/empty_state_widget.dart';

class ObjectDetailScreen extends StatelessWidget {
  const ObjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ObjectController controller = Get.find<ObjectController>();
    final String objectId = Get.parameters['id'] ?? '';

    // Load object details if not already loaded
    if (controller.selectedObject?.id != objectId) {
      controller.getObjectById(objectId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          Obx(() {
            final object = controller.selectedObject;
            if (object != null) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      NavigationService.toObjectEdit(object.id ?? '');
                      break;
                    case 'delete':
                      _showDeleteConfirmation(
                        context,
                        controller,
                        object.id ?? '',
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        // Show loading state
        if (controller.isLoading && controller.selectedObject == null) {
          return const LoadingWidget(message: 'Loading object details...');
        }

        // Show error state
        if (controller.errorMessage.isNotEmpty &&
            controller.selectedObject == null) {
          return EmptyStateWidget(
            title: 'Error Loading Details',
            message: controller.errorMessage,
            icon: Icons.error_outline,
            onAction: () => controller.getObjectById(objectId),
            actionButtonText: 'Try Again',
          );
        }

        final object = controller.selectedObject;
        if (object == null) {
          return const EmptyStateWidget(
            title: 'Object Not Found',
            message: 'The requested object could not be found.',
            icon: Icons.search_off,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Object ID Card
              if (object.id != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tag,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Object ID',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    object.friendlyId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (object.id != null &&
                                      object.displayId != null)
                                    Text(
                                      'API ID: ${object.id}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Copy to clipboard functionality could be added here
                            FeedbackService.showCopySuccess('Object ID');
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy ID',
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Object Name Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.label,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              object.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Object Data Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.data_object,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Data',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (object.data == null || object.data!.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'No data available',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: object.data!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        entry.value.toString(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.toNamed(
                          AppRoutes.objectEdit.replaceAll(
                            ':id',
                            object.id ?? '',
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Object'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(
                          context,
                          controller,
                          object.id ?? '',
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    ObjectController controller,
    String objectId,
  ) {
    LoggingService.info(
      '🗑️ Delete confirmation requested',
      tag: 'ObjectDetailScreen',
      data: {'objectId': objectId},
    );

    ConfirmationDialog.showDeleteWithGetX(itemName: 'object').then((confirmed) {
      LoggingService.info(
        '🗑️ Delete confirmation result',
        tag: 'ObjectDetailScreen',
        data: {'confirmed': confirmed, 'objectId': objectId},
      );

      if (confirmed == true) {
        LoggingService.info(
          '🗑️ Calling controller.deleteObject',
          tag: 'ObjectDetailScreen',
          data: {'objectId': objectId},
        );
        controller.deleteObject(objectId);
      }
    });
  }
}
