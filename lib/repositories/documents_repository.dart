import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/access_model.dart';
import '../models/document_model.dart';

/// Reads for an event's documents. Documents live in a subcollection of their
/// event — `events/{eventId}/documents/{id}` — and inherit its access: anyone who
/// can read the event can read its documents. Writes happen in the admin panel
/// only (`composables/useDocuments.ts`).
class DocumentsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _documentsCollection(
    String eventId,
  ) => _firestore
      .collection(Collections.events)
      .doc(eventId)
      .collection(Collections.documents);

  /// Every document for an event, newest first.
  Future<List<DocumentModel>> getDocuments(String eventId) async {
    final snapshot = await _documentsCollection(
      eventId,
    ).orderBy('createdAt', descending: true).get();
    // The document id wins over any stale `id` written into the body.
    return snapshot.docs
        .map((doc) => DocumentModel.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// A single document, or null if it doesn't exist.
  Future<DocumentModel?> getDocument(String eventId, String documentId) async {
    final doc = await _documentsCollection(eventId).doc(documentId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return DocumentModel.fromJson({...data, 'id': doc.id});
  }
}
