import '../models/support_model.dart';
import '../repositories/support_repository.dart';

/// Business logic around an event's support requests: what the participant can
/// read, and the two things they can write — opening a request, and replying in
/// one.
///
/// The screens talk to this rather than the repository directly, matching the
/// community feed. The length limits live here rather than in the text fields,
/// so each one is a single number shared by the composer that enforces it, the
/// model that trims to it, and the security rules that reject past it.
class SupportService {
  final SupportRepository _repository = SupportRepository();

  /// The longest a subject may be. Kept equal to the rules' check and the
  /// panel's `SUPPORT_SUBJECT_MAX_LENGTH`.
  static const int subjectMaxLength = SupportRequest.subjectMaxLength;

  /// The longest a single message may be. Same three-way agreement.
  static const int messageMaxLength = SupportMessage.messageMaxLength;

  /// The signed-in user's own requests for an event, most recently active first.
  Stream<List<SupportRequest>> watchMyRequests(String eventId, String uid) {
    if (eventId.isEmpty || uid.isEmpty) return Stream.value(const []);
    return _repository.watchMyRequests(eventId, uid);
  }

  /// One request, live — null once it no longer exists.
  Stream<SupportRequest?> watchRequest(String eventId, String requestId) {
    if (eventId.isEmpty || requestId.isEmpty) return Stream.value(null);
    return _repository.watchRequest(eventId, requestId);
  }

  /// A request's messages, oldest first, as a live stream.
  Stream<List<SupportMessage>> watchMessages(String eventId, String requestId) {
    if (eventId.isEmpty || requestId.isEmpty) return Stream.value(const []);
    return _repository.watchMessages(eventId, requestId);
  }

  /// Open a request with its first message, and return its new id.
  ///
  /// Both fields are trimmed and refused when empty here rather than left to the
  /// rules: a rejected write costs a round trip and surfaces as a permission
  /// error, which is not what "you forgot to type anything" should look like.
  Future<String> openRequest({
    required String eventId,
    required String requesterId,
    required String requesterName,
    String? requesterImage,
    required String subject,
    required String message,
  }) {
    if (eventId.isEmpty || requesterId.isEmpty) {
      throw ArgumentError('Event ID and requester cannot be empty');
    }
    final trimmedSubject = subject.trim();
    final trimmedMessage = message.trim();
    if (trimmedSubject.isEmpty) {
      throw ArgumentError('A request needs a subject');
    }
    if (trimmedSubject.length > subjectMaxLength) {
      throw ArgumentError(
        'A subject holds at most $subjectMaxLength characters',
      );
    }
    if (trimmedMessage.isEmpty) {
      throw ArgumentError('A request needs a message');
    }
    if (trimmedMessage.length > messageMaxLength) {
      throw ArgumentError(
        'A message holds at most $messageMaxLength characters',
      );
    }
    return _repository.openRequest(
      eventId: eventId,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterImage: requesterImage,
      subject: trimmedSubject,
      message: trimmedMessage,
    );
  }

  /// Send the participant's message into an existing thread.
  ///
  /// [currentStatus] is the status the thread was in when the composer was
  /// drawn — a message sent into a resolved thread reopens it.
  Future<String> sendMessage({
    required String eventId,
    required String requestId,
    required String senderId,
    required String senderName,
    required String message,
    required SupportRequestStatus currentStatus,
  }) {
    if (eventId.isEmpty || requestId.isEmpty || senderId.isEmpty) {
      throw ArgumentError('Event ID, request ID and sender cannot be empty');
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('A message cannot be empty');
    }
    if (trimmed.length > messageMaxLength) {
      throw ArgumentError(
        'A message holds at most $messageMaxLength characters',
      );
    }
    return _repository.sendMessage(
      eventId: eventId,
      requestId: requestId,
      senderId: senderId,
      senderName: senderName,
      message: trimmed,
      currentStatus: currentStatus,
    );
  }
}
