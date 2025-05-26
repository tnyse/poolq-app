import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Get a collection reference
  CollectionReference collection(String path) {
    return _firestore.collection(path);
  }

  // Get a document reference
  DocumentReference document(String path) {
    return _firestore.doc(path);
  }

  // Get data from a document
  Future<DocumentSnapshot> getDocument(String path) async {
    try {
      return await _firestore.doc(path).get();
    } catch (e) {
      debugPrint('Error getting document: $e');
      rethrow;
    }
  }

  // Get data from a collection
  Future<QuerySnapshot> getCollection(String path) async {
    try {
      return await _firestore.collection(path).get();
    } catch (e) {
      debugPrint('Error getting collection: $e');
      rethrow;
    }
  }

  // Add data to a collection
  Future<DocumentReference> addDocument(String path, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(path).add(data);
    } catch (e) {
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  // Set data to a document
  Future<void> setDocument(String path, Map<String, dynamic> data, {bool merge = false}) async {
    try {
      await _firestore.doc(path).set(data, SetOptions(merge: merge));
    } catch (e) {
      debugPrint('Error setting document: $e');
      rethrow;
    }
  }

  // Update data in a document
  Future<void> updateDocument(String path, Map<String, dynamic> data) async {
    try {
      await _firestore.doc(path).update(data);
    } catch (e) {
      debugPrint('Error updating document: $e');
      rethrow;
    }
  }

  // Delete a document
  Future<void> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  // Listen to a document
  Stream<DocumentSnapshot> streamDocument(String path) {
    return _firestore.doc(path).snapshots();
  }

  // Listen to a collection
  Stream<QuerySnapshot> streamCollection(String path) {
    return _firestore.collection(path).snapshots();
  }
} 