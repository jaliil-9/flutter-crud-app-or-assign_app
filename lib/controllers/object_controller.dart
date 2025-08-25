import 'package:get/get.dart';
import '../models/api_object.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';
import '../services/logging_service.dart';
import '../utils/error_handler.dart';
import '../bindings/controller_binding.dart';
import '../services/navigation_service.dart';

/// Controller for managing object state and CRUD operations
class ObjectController extends BaseController {
  final ApiService _apiService;

  // Reactive variables for object state
  final RxList<ApiObject> _objects = <ApiObject>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final RxBool _hasMore = true.obs;
  final RxString _errorMessage = ''.obs;
  final RxInt _currentPage = 0.obs;
  final RxBool _isLoadingMore = false.obs;
  final Rxn<ApiObject> _selectedObject = Rxn<ApiObject>();

  // Pagination settings
  static const int _pageSize = 20;

  // Display ID counter for sequential numbering
  int _nextDisplayId = 1;

  // Getters for reactive variables
  List<ApiObject> get objects => _objects;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  bool get hasMore => _hasMore.value;
  String get errorMessage => _errorMessage.value;
  bool get isLoadingMore => _isLoadingMore.value;
  ApiObject? get selectedObject => _selectedObject.value;

  // Observable getters for reactive programming
  RxList<ApiObject> get objectsObs => _objects;
  RxBool get isLoadingObs => _isLoading;
  RxBool get isRefreshingObs => _isRefreshing;
  RxBool get hasMoreObs => _hasMore;
  RxBool get isLoadingMoreObs => _isLoadingMore;
  Rxn<ApiObject> get selectedObjectObs => _selectedObject;

  ObjectController({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  @override
  void onInit() {
    super.onInit();
    fetchObjects();
  }

  /// Fetch objects from the API with pagination support
  Future<void> fetchObjects({bool refresh = false}) async {
    if (refresh) {
      _setRefreshing(true);
      _currentPage.value = 0;
      _hasMore.value = true;
      _objects.clear();
    } else if (_isLoading.value || _isLoadingMore.value) {
      return; // Prevent multiple simultaneous requests
    }

    if (_currentPage.value == 0) {
      _setLoading(true);
    } else {
      _setLoadingMore(true);
    }

    _clearError();

    try {
      final int offset = _currentPage.value * _pageSize;
      final List<ApiObject> newObjects = await _apiService.getObjects(
        limit: _pageSize,
        offset: offset,
      );

      if (newObjects.isEmpty) {
        _hasMore.value = false;
      } else {
        // Assign display IDs to new objects
        final List<ApiObject> objectsWithDisplayIds = newObjects
            .map((obj) => obj.copyWith(displayId: _getNextDisplayId()))
            .toList();

        if (refresh || _currentPage.value == 0) {
          _nextDisplayId = 1; // Reset display ID counter on refresh
          final List<ApiObject> refreshedObjects = newObjects
              .asMap()
              .entries
              .map((entry) => entry.value.copyWith(displayId: entry.key + 1))
              .toList();
          _objects.assignAll(refreshedObjects);
          _nextDisplayId = refreshedObjects.length + 1;
        } else {
          _objects.addAll(objectsWithDisplayIds);
        }
        _currentPage.value++;

        // Check if we got fewer objects than requested (indicates last page)
        if (newObjects.length < _pageSize) {
          _hasMore.value = false;
        }
      }
    } on ApiException catch (e) {
      LoggingService.error('API error during fetch objects', error: e);
      ErrorHandler.handleApiError(e, context: 'Fetch Objects');
    } catch (e) {
      LoggingService.error('Unexpected error during fetch objects', error: e);
      _handleError('Failed to fetch objects. Please try again.');
    } finally {
      _setLoading(false);
      _setRefreshing(false);
      _setLoadingMore(false);
    }
  }

  /// Load more objects for pagination
  Future<void> loadMore() async {
    if (_hasMore.value && !_isLoadingMore.value && !_isLoading.value) {
      _setLoadingMore(true);
      _clearError();

      try {
        final int offset = _currentPage.value * _pageSize;
        final List<ApiObject> newObjects = await _apiService.getObjects(
          limit: _pageSize,
          offset: offset,
        );

        if (newObjects.isEmpty) {
          _hasMore.value = false;
        } else {
          _objects.addAll(newObjects);
          _currentPage.value++;

          // Check if we got fewer objects than requested (indicates last page)
          if (newObjects.length < _pageSize) {
            _hasMore.value = false;
          }
        }
      } on ApiException catch (e) {
        LoggingService.error('API error during load more', error: e);
        ErrorHandler.handleApiError(e, context: 'Load More Objects');
      } catch (e) {
        LoggingService.error('Unexpected error during load more', error: e);
        _handleError('Failed to load more objects. Please try again.');
      } finally {
        _setLoadingMore(false);
      }
    }
  }

  /// Refresh the object list
  Future<void> refreshObjects() async {
    await fetchObjects(refresh: true);
  }

  /// Create a new object with optimistic updates
  Future<void> createObject(ApiObject object) async {
    _setLoading(true);
    _clearError();

    try {
      final ApiObject createdObject = await _apiService.createObject(object);

      // Add display ID to the created object
      final ApiObject objectWithDisplayId = createdObject.copyWith(
        displayId: _getNextDisplayId(),
      );

      // Add the created object to the beginning of the list
      _objects.insert(0, objectWithDisplayId);

      FeedbackService.showCrudSuccess('create', 'Object');

      // Navigate to object list after successful creation
      if (!Get.testMode) {
        NavigationService.toObjectList();
      }
    } on ApiException catch (e) {
      LoggingService.error('API error during create object', error: e);
      FeedbackService.showCrudError('create', 'Object', e.message);
      ErrorHandler.handleApiError(e, context: 'Create Object');
    } catch (e) {
      LoggingService.error('Unexpected error during create object', error: e);
      FeedbackService.showCrudError('create', 'Object');
      _handleError('Failed to create object. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing object with proper state management
  Future<void> updateObject(String id, ApiObject object) async {
    _setLoading(true);
    _clearError();

    // Find the original object for potential rollback
    final int originalIndex = _objects.indexWhere((obj) => obj.id == id);
    final ApiObject? originalObject = originalIndex != -1
        ? _objects[originalIndex]
        : null;

    // Optimistic update - preserve display ID
    if (originalIndex != -1) {
      _objects[originalIndex] = object.copyWith(
        id: id,
        displayId: originalObject?.displayId,
      );
    }

    try {
      final ApiObject updatedObject = await _apiService.updateObject(
        id,
        object,
      );

      // Update with the actual response from server, preserving display ID
      if (originalIndex != -1) {
        _objects[originalIndex] = updatedObject.copyWith(
          displayId: originalObject?.displayId,
        );
      }

      // Update selected object if it's the same one, preserving display ID
      if (_selectedObject.value?.id == id) {
        _selectedObject.value = updatedObject.copyWith(
          displayId: _selectedObject.value?.displayId,
        );
      }

      FeedbackService.showCrudSuccess('update', 'Object');

      // Navigate to object list after successful update
      if (!Get.testMode) {
        NavigationService.toObjectList();
      }
    } on ApiException catch (e) {
      // Rollback optimistic update on error, preserving display ID
      if (originalIndex != -1 && originalObject != null) {
        _objects[originalIndex] = originalObject;
      }
      LoggingService.error('API error during update object', error: e);
      FeedbackService.showCrudError('update', 'Object', e.message);
      ErrorHandler.handleApiError(e, context: 'Update Object');
    } catch (e) {
      // Rollback optimistic update on error, preserving display ID
      if (originalIndex != -1 && originalObject != null) {
        _objects[originalIndex] = originalObject;
      }
      LoggingService.error('Unexpected error during update object', error: e);
      FeedbackService.showCrudError('update', 'Object');
      _handleError('Failed to update object. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an object with optimistic updates and rollback
  Future<void> deleteObject(String id) async {
    LoggingService.info(
      '🗑️ Starting delete process',
      tag: 'ObjectController',
      data: {'objectId': id, 'timestamp': DateTime.now().toIso8601String()},
    );

    _setLoading(true);
    _clearError();

    // Find the object to delete for potential rollback
    final int originalIndex = _objects.indexWhere((obj) => obj.id == id);
    final ApiObject? originalObject = originalIndex != -1
        ? _objects[originalIndex]
        : null;

    LoggingService.info(
      '📋 Object lookup result',
      tag: 'ObjectController',
      data: {
        'objectId': id,
        'foundIndex': originalIndex,
        'hasObject': originalObject != null,
        'objectName': originalObject?.name,
      },
    );

    if (originalIndex == -1) {
      LoggingService.error(
        '❌ Object not found in local list',
        tag: 'ObjectController',
        data: {'objectId': id, 'totalObjects': _objects.length},
      );
      _handleError('Object not found in local list');
      _setLoading(false);
      return;
    }

    LoggingService.info(
      '🔄 Performing optimistic delete',
      tag: 'ObjectController',
      data: {'objectId': id, 'originalIndex': originalIndex},
    );

    // Optimistic update - remove from list immediately
    _objects.removeAt(originalIndex);

    try {
      LoggingService.info(
        '📡 Calling API delete service',
        tag: 'ObjectController',
        data: {'objectId': id},
      );

      final bool success = await _apiService.deleteObject(id);

      LoggingService.info(
        '📋 API delete response',
        tag: 'ObjectController',
        data: {'objectId': id, 'success': success},
      );

      if (success) {
        // Clear selected object if it was the deleted one
        if (_selectedObject.value?.id == id) {
          LoggingService.info(
            '🧹 Clearing selected object',
            tag: 'ObjectController',
          );
          _selectedObject.value = null;
        }

        FeedbackService.showCrudSuccess('delete', 'Object');

        LoggingService.info(
          '🧭 Checking navigation',
          tag: 'ObjectController',
          data: {
            'currentRoute': Get.currentRoute,
            'containsId': Get.currentRoute.contains(id),
            'testMode': Get.testMode,
          },
        );

        // Navigate to object list after successful deletion
        if (!Get.testMode) {
          LoggingService.info(
            '🧭 Navigating to object list after delete',
            tag: 'ObjectController',
          );
          NavigationService.toObjectList();
        }

        LoggingService.info(
          '✅ Delete operation completed successfully',
          tag: 'ObjectController',
          data: {'objectId': id},
        );
      } else {
        LoggingService.warning(
          '⚠️ API returned false for delete',
          tag: 'ObjectController',
          data: {'objectId': id},
        );

        // Rollback if deletion wasn't successful
        if (originalObject != null) {
          LoggingService.info(
            '🔄 Rolling back optimistic delete',
            tag: 'ObjectController',
          );
          _objects.insert(originalIndex, originalObject);
        }
        FeedbackService.showCrudError('delete', 'Object');
        _handleError('Failed to delete object');
      }
    } on ApiException catch (e) {
      // Rollback optimistic update on error
      if (originalObject != null) {
        _objects.insert(originalIndex, originalObject);
      }
      LoggingService.error('API error during delete object', error: e);
      ErrorHandler.handleApiError(e, context: 'Delete Object');
    } catch (e) {
      // Rollback optimistic update on error
      if (originalObject != null) {
        _objects.insert(originalIndex, originalObject);
      }
      LoggingService.error('Unexpected error during delete object', error: e);
      _handleError('Failed to delete object. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Get an object by ID for detail view
  Future<ApiObject?> getObjectById(String id) async {
    _clearError();

    // First check if the object is already in our local list
    final ApiObject? localObject = _objects.firstWhereOrNull(
      (obj) => obj.id == id,
    );
    if (localObject != null) {
      _selectedObject.value = localObject;
      return localObject;
    }

    // If not found locally, fetch from API
    _setLoading(true);

    try {
      final ApiObject object = await _apiService.getObjectById(id);

      // Try to find display ID from existing objects
      final ApiObject? existingObject = _objects.firstWhereOrNull(
        (obj) => obj.id == id,
      );

      final ApiObject objectWithDisplayId = object.copyWith(
        displayId: existingObject?.displayId,
      );

      _selectedObject.value = objectWithDisplayId;
      return objectWithDisplayId;
    } on ApiException catch (e) {
      LoggingService.error('API error during get object by ID', error: e);
      ErrorHandler.handleApiError(e, context: 'Get Object Details');
      return null;
    } catch (e) {
      LoggingService.error(
        'Unexpected error during get object by ID',
        error: e,
      );
      _handleError('Failed to fetch object details. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Set the selected object (for navigation purposes)
  void setSelectedObject(ApiObject? object) {
    _selectedObject.value = object;
  }

  /// Clear the selected object
  void clearSelectedObject() {
    _selectedObject.value = null;
  }

  /// Search objects by name (local search)
  List<ApiObject> searchObjects(String query) {
    if (query.isEmpty) return _objects;

    return _objects
        .where(
          (object) =>
              object.name.toLowerCase().contains(query.toLowerCase()) ||
              (object.id?.toLowerCase().contains(query.toLowerCase()) ?? false),
        )
        .toList();
  }

  /// Get objects count
  int get objectsCount => _objects.length;

  /// Check if an object exists in the local list
  bool hasObject(String id) {
    return _objects.any((obj) => obj.id == id);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading.value = loading;
    update(); // Notify GetBuilder widgets
  }

  /// Set refreshing state
  void _setRefreshing(bool refreshing) {
    _isRefreshing.value = refreshing;
    update(); // Notify GetBuilder widgets
  }

  /// Set loading more state
  void _setLoadingMore(bool loadingMore) {
    _isLoadingMore.value = loadingMore;
    update(); // Notify GetBuilder widgets
  }

  /// Clear error message
  void _clearError() {
    _errorMessage.value = '';
  }

  /// Handle errors and update error state
  void _handleError(String error) {
    _errorMessage.value = error;
    FeedbackService.showError(error);
  }

  /// Get next display ID for sequential numbering
  int _getNextDisplayId() {
    return _nextDisplayId++;
  }

  /// Retry last failed operation
  Future<void> retry() async {
    _clearError();
    await fetchObjects(refresh: true);
  }

  @override
  void onClose() {
    // Clean up any subscriptions or resources
    super.onClose();
  }
}
