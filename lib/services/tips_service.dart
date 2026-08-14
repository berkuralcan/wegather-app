import '../models/tips_model.dart';
import '../repositories/tips_repository.dart';

/// Business logic around an event's "Important Tips".
class TipsService {
  final TipsRepository _tipsRepository = TipsRepository();

  /// Every tip of an event, ordered for display.
  ///
  /// Tips have no explicit order field yet, so they are sorted by their
  /// primary-language title. Swap this for the stored order once the admin
  /// panel lets managers arrange them.
  Future<List<TipModel>> getTips(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    final tips = await _tipsRepository.getTips(eventId);
    tips.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return tips;
  }

  /// A single tip, or null if it doesn't exist.
  Future<TipModel?> getTip(String eventId, String tipId) {
    if (eventId.isEmpty || tipId.isEmpty) {
      throw ArgumentError('Event ID and tip ID cannot be empty');
    }
    return _tipsRepository.getTip(eventId, tipId);
  }
}
