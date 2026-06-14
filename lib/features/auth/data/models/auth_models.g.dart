// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) =>
    _AuthResponse(
      token: _tokenFromJson(_readToken(json, 'token')),
      tokenType: _tokenTypeFromJson(_readTokenType(json, 'tokenType')),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthResponseToJson(_AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'tokenType': instance.tokenType,
      'user': instance.user,
    };

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: _idFromJson(json['id']),
  name: _nameFromJson(_readName(json, 'name')),
  email: _emailFromJson(_readEmail(json, 'email')),
  phone: _nullableStringFromJson(json['phone']),
  avatar: _nullableStringFromJson(json['avatar']),
  role: _nullableStringFromJson(json['role']),
  permissions: _stringListFromJson(json['permissions']),
  createdAt: _dateTimeFromJson(json['created_at']),
  updatedAt: _dateTimeFromJson(json['updated_at']),
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'avatar': instance.avatar,
      'role': instance.role,
      'permissions': instance.permissions,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      deviceName: json['device_name'] as String? ?? 'mobile',
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'device_name': instance.deviceName,
    };
