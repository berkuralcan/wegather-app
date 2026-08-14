import '../models/document_model.dart';
import '../repositories/documents_repository.dart';

/// Business logic around an event's documents.
class DocumentsService {
  final DocumentsRepository _documentsRepository = DocumentsRepository();

  /// Every document of an event, newest first (ordered by the repository's
  /// `createdAt` query).
  Future<List<DocumentModel>> getDocuments(String eventId) async {
    if (eventId.isEmpty) {
      throw ArgumentError('Event ID cannot be empty');
    }
    return _documentsRepository.getDocuments(eventId);
  }

  /// A single document, or null if it doesn't exist.
  Future<DocumentModel?> getDocument(String eventId, String documentId) {
    if (eventId.isEmpty || documentId.isEmpty) {
      throw ArgumentError('Event ID and document ID cannot be empty');
    }
    return _documentsRepository.getDocument(eventId, documentId);
  }
}
