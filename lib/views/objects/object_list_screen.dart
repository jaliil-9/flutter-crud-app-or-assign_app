import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/object_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/navigation_service.dart';
import 'widgets/object_card.dart';
import 'widgets/loading_widget.dart';
import '../common/empty_state_widget.dart';
import '../common/theme_settings_widget.dart';

class ObjectListScreen extends StatelessWidget {
  const ObjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ObjectController controller = Get.put(ObjectController());
    final ScrollController scrollController = ScrollController();

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        controller.loadMore();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Objects'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshObjects(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final AuthController authController = Get.find<AuthController>();
              await authController.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.objects.isEmpty) {
          return const LoadingWidget(message: 'Loading objects...');
        }

        if (controller.objects.isEmpty) {
          return EmptyStateWidget(
            title: 'No Objects Found',
            message:
                'There are no objects to display.\nTap the + button to create your first object.',
            icon: Icons.inbox_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshObjects(),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index < controller.objects.length) {
                    final object = controller.objects[index];
                    return ObjectCard(
                      object: object,
                      onTap: () {
                        controller.setSelectedObject(object);
                        NavigationService.toObjectDetail(object.id ?? '');
                      },
                    );
                  }
                  return null;
                }, childCount: controller.objects.length),
              ),

              if (controller.isLoadingMore.value)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingWidget(
                      message: 'Loading more objects...',
                      size: 24,
                    ),
                  ),
                ),

              if (!controller.isLoadingMore.value &&
                  controller.hasMore.value &&
                  controller.objects.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.loadMore(),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Load More'),
                      ),
                    ),
                  ),
                ),

              if (!controller.hasMore.value && controller.objects.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No more objects to load',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationService.toObjectForm();
        },
        tooltip: 'Create Object',
        child: const Icon(Icons.add),
      ),
    );
  }
}
