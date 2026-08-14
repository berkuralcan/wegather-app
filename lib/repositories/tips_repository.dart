import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/tips_model.dart';

/// Reads for an event's "Important Tips". Tips live in a subcollection of their
/// event — `events/{eventId}/tips/{tipId}` — and inherit its access: anyone who
/// can read the event can read its tips. Writes happen in the admin panel only
/// (`composables/useTips.ts`).
class TipsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tipsCollection(String eventId) =>
      _firestore
          .collection(Collections.events)
          .doc(eventId)
          .collection(Collections.tips);

  /// Every tip for an event.
  Future<List<TipModel>> getTips(String eventId) async {
    final snapshot = await _tipsCollection(eventId).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => TipModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// A single tip, or null if it doesn't exist.
  Future<TipModel?> getTip(String eventId, String tipId) async {
    final doc = await _tipsCollection(eventId).doc(tipId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return TipModel.fromJson({...data, 'id': doc.id});
  }
}
