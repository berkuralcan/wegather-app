import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath;

  BaseRepository(this.collectionPath);

  // Get document by ID
  Future<T?> getById(String id) async {
    try {
      final doc = await _firestore.collection(collectionPath).doc(id).get();
      if (doc.exists) {
        return fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get document: $e',
      );
    }
  }

  // Get all documents in collection
  Future<List<T>> getAll() async {
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      return querySnapshot.docs.map((doc) => fromFirestore(doc)).toList();
    } catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Failed to get collection: $e',
      );
    }
  }

  T fromFirestore(DocumentSnapshot doc);
  Map<String, dynamic> toFirestore(T item);
}