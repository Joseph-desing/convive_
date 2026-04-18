import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'feedback.g.dart';

enum FeedbackType {
  @JsonValue('complaint') complaint,
  @JsonValue('suggestion') suggestion,
  @JsonValue('bug_report') bug_report,
}

enum FeedbackStatus {
  @JsonValue('open') open,
  @JsonValue('in_review') in_review,
  @JsonValue('resolved') resolved,
  @JsonValue('closed') closed,
}

@JsonSerializable()
class UserFeedback {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'type')
  final FeedbackType type;

  @JsonKey(name: 'status')
  final FeedbackStatus status;

  final String subject;
  final String message;

  @JsonKey(name: 'category')
  final String? category;

  @JsonKey(name: 'attachment_url')
  final String? attachmentUrl;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'admin_response')
  final String? adminResponse;

  @JsonKey(name: 'admin_response_at')
  final DateTime? adminResponseAt;

  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;

  UserFeedback({
    String? id,
    required this.userId,
    required this.type,
    this.status = FeedbackStatus.open,
    required this.subject,
    required this.message,
    this.category,
    this.attachmentUrl,
    DateTime? createdAt,
    this.updatedAt,
    this.adminResponse,
    this.adminResponseAt,
    this.resolvedBy,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  factory UserFeedback.fromJson(Map<String, dynamic> json) =>
      _$UserFeedbackFromJson(json);

  Map<String, dynamic> toJson() => _$UserFeedbackToJson(this);

  UserFeedback copyWith({
    String? id,
    String? userId,
    FeedbackType? type,
    FeedbackStatus? status,
    String? subject,
    String? message,
    String? category,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    DateTime? adminResponseAt,
    String? resolvedBy,
  }) {
    return UserFeedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      category: category ?? this.category,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminResponseAt: adminResponseAt ?? this.adminResponseAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
    );
  }
}
