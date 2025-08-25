import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:assign_app/controllers/object_controller.dart';
import 'package:assign_app/models/api_object.dart';
import 'package:assign_app/services/api_service.dart';

// Generate mocks
@GenerateMocks([ApiService])
import 'object_controller_test.mocks.dart';

void main() {
  group('ObjectController Tests', () {
    late ObjectController controller;
    late MockApiService mockApiService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Get.testMode = true;
      mockApiService = MockApiService();
      controller = ObjectController(apiService: mockApiService);
    });

    tearDown(() {
      Get.reset();
    });

    test('fetchObjects should fetch objects successfully', () async {
      // Arrange
      final testObjects = [
        const ApiObject(
          id: '1',
          name: 'Test Object 1',
          data: {'key': 'value1'},
        ),
        const ApiObject(
          id: '2',
          name: 'Test Object 2',
          data: {'key': 'value2'},
        ),
      ];

      when(
        mockApiService.getObjects(
          limit: anyNamed('limit'),
          offset: anyNamed('offset'),
        ),
      ).thenAnswer((_) async => testObjects);

      // Act
      await controller.fetchObjects();

      // Assert
      expect(controller.objects, equals(testObjects));
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isEmpty);
      verify(mockApiService.getObjects(limit: 20, offset: 0)).called(1);
    });
  });
}
