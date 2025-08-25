import 'package:get/get.dart';
import '../models/api_object.dart';
import '../services/api_service.dart';
import '../services/navigation_service.dart';

class ObjectController extends GetxController {
  final ApiService _apiService;

  final RxList<ApiObject> objects = <ApiObject>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool hasMore = true.obs;
  final RxInt currentPage = 0.obs;
  final RxBool isLoadingMore = false.obs;
  final Rxn<ApiObject> selectedObject = Rxn<ApiObject>();

  static const int _pageSize = 20;
  int _nextDisplayId = 1;

  ObjectController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchObjects();
  }

  Future<void> fetchObjects({bool refresh = false}) async {
    if (refresh) {
      isRefreshing.value = true;
      currentPage.value = 0;
      hasMore.value = true;
      objects.clear();
    } else if (isLoading.value || isLoadingMore.value) {
      return;
    }

    if (currentPage.value == 0) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final int offset = currentPage.value * _pageSize;
      final List<ApiObject> newObjects = await _apiService.getObjects(
        limit: _pageSize,
        offset: offset,
      );

      if (newObjects.isEmpty) {
        hasMore.value = false;
      } else {
        final List<ApiObject> objectsWithDisplayIds = newObjects
            .map((obj) => obj.copyWith(displayId: _getNextDisplayId()))
            .toList();

        if (refresh || currentPage.value == 0) {
          // Reset display IDs for fresh data - ensures sequential numbering from 1
          _nextDisplayId = 1;
          final List<ApiObject> refreshedObjects = newObjects
              .asMap()
              .entries
              .map((entry) => entry.value.copyWith(displayId: entry.key + 1))
              .toList();
          objects.assignAll(refreshedObjects);
          _nextDisplayId = refreshedObjects.length + 1;
        } else {
          // Append to existing list while maintaining sequential display IDs
          objects.addAll(objectsWithDisplayIds);
        }
        currentPage.value++;

        if (newObjects.length < _pageSize) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch objects. Please try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMore() async {
    if (hasMore.value && !isLoadingMore.value && !isLoading.value) {
      isLoadingMore.value = true;

      try {
        final int offset = currentPage.value * _pageSize;
        final List<ApiObject> newObjects = await _apiService.getObjects(
          limit: _pageSize,
          offset: offset,
        );

        if (newObjects.isEmpty) {
          hasMore.value = false;
        } else {
          final List<ApiObject> objectsWithDisplayIds = newObjects
              .map((obj) => obj.copyWith(displayId: _getNextDisplayId()))
              .toList();
          objects.addAll(objectsWithDisplayIds);
          currentPage.value++;

          if (newObjects.length < _pageSize) {
            hasMore.value = false;
          }
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to load more objects. Please try again.',
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      } finally {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> refreshObjects() async {
    await fetchObjects(refresh: true);
  }

  Future<void> createObject(ApiObject object) async {
    isLoading.value = true;

    try {
      final ApiObject createdObject = await _apiService.createObject(object);

      final ApiObject objectWithDisplayId = createdObject.copyWith(
        displayId: _getNextDisplayId(),
      );

      objects.insert(0, objectWithDisplayId);

      Get.snackbar(
        'Success',
        'Object created successfully',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      if (!Get.testMode) {
        NavigationService.toObjectList();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create object. Please try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateObject(String id, ApiObject object) async {
    isLoading.value = true;

    // Store original state for rollback on failure
    final int originalIndex = objects.indexWhere((obj) => obj.id == id);
    final ApiObject? originalObject = originalIndex != -1
        ? objects[originalIndex]
        : null;

    // Optimistic update - show changes immediately while API call is in progress
    if (originalIndex != -1) {
      objects[originalIndex] = object.copyWith(
        id: id,
        displayId: originalObject?.displayId,
      );
    }

    try {
      final ApiObject updatedObject = await _apiService.updateObject(
        id,
        object,
      );

      if (originalIndex != -1) {
        objects[originalIndex] = updatedObject.copyWith(
          displayId: originalObject?.displayId,
        );
      }

      // Sync selected object with updated data to maintain UI consistency
      if (selectedObject.value?.id == id) {
        selectedObject.value = updatedObject.copyWith(
          displayId: selectedObject.value?.displayId,
        );
      }

      Get.snackbar(
        'Success',
        'Object updated successfully',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Navigate to object list after successful update
      if (!Get.testMode) {
        NavigationService.toObjectList();
      }
    } catch (e) {
      if (originalIndex != -1 && originalObject != null) {
        objects[originalIndex] = originalObject;
      }
      Get.snackbar(
        'Error',
        'Failed to update object. Please try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteObject(String id) async {
    isLoading.value = true;

    // Find the object to delete for potential rollback
    final int originalIndex = objects.indexWhere((obj) => obj.id == id);
    final ApiObject? originalObject = originalIndex != -1
        ? objects[originalIndex]
        : null;

    if (originalIndex == -1) {
      Get.snackbar(
        'Error',
        'Object not found.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      isLoading.value = false;
      return;
    }

    // Optimistic update - remove from list immediately
    objects.removeAt(originalIndex);

    try {
      await _apiService.deleteObject(id);

      // Clear selected object if it was the deleted one
      if (selectedObject.value?.id == id) {
        selectedObject.value = null;
      }

      Get.snackbar(
        'Success',
        'Object deleted successfully',
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Navigate to object list after successful deletion
      if (!Get.testMode) {
        NavigationService.toObjectList();
      }
    } catch (e) {
      if (originalObject != null) {
        objects.insert(originalIndex, originalObject);
      }
      Get.snackbar(
        'Error',
        'Failed to delete object. Please try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<ApiObject?> getObjectById(String id) async {
    // First check if the object is already in our local list
    final ApiObject? localObject = objects.firstWhereOrNull(
      (obj) => obj.id == id,
    );
    if (localObject != null) {
      selectedObject.value = localObject;
      return localObject;
    }

    // If not found locally, fetch from API
    isLoading.value = true;

    try {
      final ApiObject object = await _apiService.getObjectById(id);

      // Try to find display ID from existing objects
      final ApiObject? existingObject = objects.firstWhereOrNull(
        (obj) => obj.id == id,
      );

      final ApiObject objectWithDisplayId = object.copyWith(
        displayId: existingObject?.displayId,
      );

      selectedObject.value = objectWithDisplayId;
      return objectWithDisplayId;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch object details. Please try again.',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void setSelectedObject(ApiObject? object) {
    selectedObject.value = object;
  }

  void clearSelectedObject() {
    selectedObject.value = null;
  }

  List<ApiObject> searchObjects(String query) {
    if (query.isEmpty) return objects;
    return objects
        .where(
          (object) =>
              object.name.toLowerCase().contains(query.toLowerCase()) ||
              (object.id?.toLowerCase().contains(query.toLowerCase()) ?? false),
        )
        .toList();
  }

  int _getNextDisplayId() {
    return _nextDisplayId++;
  }

  Future<void> retry() async {
    await fetchObjects(refresh: true);
  }

  @override
  void onClose() {
    // Clean up any subscriptions or resources
    super.onClose();
  }
}
