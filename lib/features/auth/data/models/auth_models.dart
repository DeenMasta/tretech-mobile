import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

// Helper functions to read keys flexibly from Laravel backend
Object? _readToken(Map<dynamic, dynamic> json, String key) =>
    json['token'] ?? json['access_token'];
Object? _readTokenType(Map<dynamic, dynamic> json, String key) =>
    json['tokenType'] ?? json['token_type'];
Object? _readName(Map<dynamic, dynamic> json, String key) =>
    json['full_name'] ?? json['name'] ?? json['email'];
Object? _readEmail(Map<dynamic, dynamic> json, String key) =>
    json['email'] ?? json['username'] ?? json['login'];

String _requiredString(Object? value, {required String fieldName}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    throw FormatException('Missing required auth field: $fieldName');
  }
  return text;
}

String _tokenFromJson(Object? value) =>
    _requiredString(value, fieldName: 'token');

String _tokenTypeFromJson(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? 'Bearer' : text;
}

int _idFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    throw const FormatException('Missing required auth field: user.id');
  }

  return parsed;
}

String _nameFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text != null && text.isNotEmpty) {
    return text;
  }

  return 'TRETECH User';
}

String _emailFromJson(Object? value) =>
    _requiredString(value, fieldName: 'user.email');

String? _nullableStringFromJson(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) return const [];

  return value
      .map((item) => item?.toString().trim())
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _dateTimeFromJson(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

/// Laravel Sanctum login response
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    @JsonKey(readValue: _readToken, fromJson: _tokenFromJson)
    required String token,
    @JsonKey(readValue: _readTokenType, fromJson: _tokenTypeFromJson)
    required String tokenType,
    required UserModel user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

/// Authenticated user model
@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    @JsonKey(fromJson: _idFromJson) required int id,
    @JsonKey(readValue: _readName, fromJson: _nameFromJson)
    required String name,
    @JsonKey(readValue: _readEmail, fromJson: _emailFromJson)
    required String email,
    @JsonKey(fromJson: _nullableStringFromJson) String? phone,
    @JsonKey(fromJson: _nullableStringFromJson) String? avatar,
    @JsonKey(fromJson: _nullableStringFromJson) String? role,
    @JsonKey(fromJson: _stringListFromJson) required List<String> permissions,
    @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
    DateTime? createdAt,
    @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJson)
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

/// Login request body
@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String password,
    @JsonKey(name: 'device_name') @Default('mobile') String deviceName,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

enum TretechUserRole { admin, logisticStaff, unsupported }

extension UserModelRoleX on UserModel {
  TretechUserRole get mobileRole {
    switch (role) {
      case 'admin':
        return TretechUserRole.admin;
      case 'logistic_staff':
        return TretechUserRole.logisticStaff;
      default:
        return TretechUserRole.unsupported;
    }
  }

  bool get hasSupportedMobileRole =>
      mobileRole == TretechUserRole.admin ||
      mobileRole == TretechUserRole.logisticStaff;

  String get mobileRoleLabel {
    switch (mobileRole) {
      case TretechUserRole.admin:
        return 'Admin';
      case TretechUserRole.logisticStaff:
        return 'Logistic Staff';
      case TretechUserRole.unsupported:
        return 'Unsupported Role';
    }
  }
}
