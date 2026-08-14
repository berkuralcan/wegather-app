import '../models/announcement_model.dart';
import '../repositories/announcements_repository.dart';

/// Business logic around an event's announcements.
class AnnouncementsService {
  final AnnouncementsRepository _announcementsRepository =
      AnnouncementsRepository();

  /// Every announcement of an event, newest first (ordered by the repository's
  /// `createdAt` query).
  Future<List<AnnouncementModel>> getAnnouncements(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    return _announcementsRepository.getAnnouncements(eventId);
  }

  /// A single announcement, or null if it doesn't exist.
  Future<AnnouncementModel?> getAnnouncement(
    String eventId,
    String announcementId,
  ) {
    if (eventId.isEmpty || announcementId.isEmpty) {
      throw ArgumentError('Event ID and announcement ID cannot be empty');
    }
    return _announcementsRepository.getAnnouncement(eventId, announcementId);
  }
}
