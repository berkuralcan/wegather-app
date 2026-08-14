import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/document_model.dart';
import '../services/documents_service.dart';
import 'access_providers.dart';

final documentsServiceProvider = Provider<DocumentsService>(
  (ref) => DocumentsService(),
);

/// The documents of the currently selected event. Re-fetches by itself when the
/// user switches events; empty while no event is selected.
///
/// `autoDispose` keeps the list fresh: `/documents` is pushed on the root
/// navigator, so leaving the screen drops the last listener and disposes the
/// cached result, and re-entering refetches (mirrors [tipsProvider]).
final documentsProvider = FutureProvider.autoDispose<List<DocumentModel>>((
  ref,
) async {
  final eventId = ref.watch(selectedEventIdProvider);
  if (eventId == null) return const [];
  return ref.watch(documentsServiceProvider).getDocuments(eventId);
});
