import 'package:collection/collection.dart';

class ApiObject {
  final String? id;
  final String name;
  final Map<String, dynamic>? data;
  final int? displayId; // Simple sequential ID for display

  const ApiObject({this.id, required this.name, this.data, this.displayId});

  /// Factory constructor to create ApiObject from JSON
  factory ApiObject.fromJson(Map<String, dynamic> json, {int? displayId}) {
    // Validate required fields
    if (json['name'] == null || json['name'].toString().isEmpty) {
      throw ArgumentError('Name field is required and cannot be empty');
    }

    return ApiObject(
      id: json['id']?.toString(),
      name: json['name'].toString(),
      data: json['data'] as Map<String, dynamic>?,
      displayId: displayId,
    );
  }

  /// Convert ApiObject to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'name': name};

    // Only include id if it's not null
    if (id != null) {
      json['id'] = id;
    }

    // Only include data if it's not null
    if (data != null) {
      json['data'] = data;
    }

    return json;
  }

  /// Create a copy of this ApiObject with updated fields
  ApiObject copyWith({
    String? id,
    String? name,
    Map<String, dynamic>? data,
    int? displayId,
  }) {
    return ApiObject(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      displayId: displayId ?? this.displayId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ApiObject) return false;

    return other.id == id &&
        other.name == name &&
        other.displayId == displayId &&
        const DeepCollectionEquality().equals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    displayId,
    data != null ? const DeepCollectionEquality().hash(data) : null,
  );

  @override
  String toString() {
    return 'ApiObject(id: $id, displayId: $displayId, name: $name, data: $data)';
  }

  /// Get the display-friendly ID (simple number or fallback to API ID)
  String get friendlyId {
    if (displayId != null) {
      return displayId.toString();
    }
    return id ?? 'Unknown';
  }
}
