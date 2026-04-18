// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserFeedback _$UserFeedbackFromJson(Map<String, dynamic> json) => UserFeedback(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      status: $enumDecodeNullable(_$FeedbackStatusEnumMap, json['status']) ??
          FeedbackStatus.open,
      subject: json['subject'] as String,
      message: json['message'] as String,
      category: json['category'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      adminResponse: json['admin_response'] as String?,
      adminResponseAt: json['admin_response_at'] == null
          ? null
          : DateTime.parse(json['admin_response_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
    );

Map<String, dynamic> _$UserFeedbackToJson(UserFeedback instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'status': _$FeedbackStatusEnumMap[instance.status]!,
      'subject': instance.subject,
      'message': instance.message,
      'category': instance.category,
      'attachment_url': instance.attachmentUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'admin_response': instance.adminResponse,
      'admin_response_at': instance.adminResponseAt?.toIso8601String(),
      'resolved_by': instance.resolvedBy,
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.complaint: 'complaint',
  FeedbackType.suggestion: 'suggestion',
  FeedbackType.bug_report: 'bug_report',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.open: 'open',
  FeedbackStatus.in_review: 'in_review',
  FeedbackStatus.resolved: 'resolved',
  FeedbackStatus.closed: 'closed',
};
