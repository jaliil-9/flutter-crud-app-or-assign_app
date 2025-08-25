import 'package:collection/collection.dart';

class ApiObject {
  final String? id;
  final String name;
  final Map<String, dynamic>? data;
  final int? displayId;

  const ApiObject({this.id, required this.name, this.data, this.displayId});

  factory ApiObject.fromJson(Map<String, dynamic> json, {int? displayId}) {
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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'name': name};

    if (id != null) {
      json['id'] = id;
    }

    if (data != null) {
      json['data'] = data;
    }

    return json;
  }

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

  String get friendlyId {
    if (displayId != null) {
      return displayId.toString();
    }
    return id ?? 'Unknown';
  }
}
