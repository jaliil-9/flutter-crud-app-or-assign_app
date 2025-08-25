import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:assign_app/services/api_service.dart';
import 'package:assign_app/models/api_object.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'api_service_test.mocks.dart';

void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService(dio: mockDio);
    });

    test(
      'getObjects should return list of ApiObjects on successful response',
      () async {
        // Arrange
        final mockResponse = Response(
          data: [
            {
              'id': '1',
              'name': 'Test Object 1',
              'data': {'key': 'value1'},
            },
            {
              'id': '2',
              'name': 'Test Object 2',
              'data': {'key': 'value2'},
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(
          mockDio.get('', queryParameters: anyNamed('queryParameters')),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getObjects();

        // Assert
        expect(result, isA<List<ApiObject>>());
        expect(result.length, equals(2));
        expect(result[0].id, equals('1'));
        expect(result[0].name, equals('Test Object 1'));
        expect(result[1].id, equals('2'));
        expect(result[1].name, equals('Test Object 2'));
        verify(
          mockDio.get('', queryParameters: {'limit': 20, 'offset': 0}),
        ).called(1);
      },
    );
  });
}
