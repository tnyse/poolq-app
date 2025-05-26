import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Upload file
  Future<String> uploadFile(File file, String path) async {
    try {
      final Reference storageRef = _storage.ref().child(path);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot taskSnapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  // Upload image from image picker
  Future<String?> uploadImage(XFile image, String path) async {
    try {
      final File file = File(image.path);
      return await uploadFile(file, path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Get download URL
  Future<String> getDownloadURL(String path) async {
    try {
      return await _storage.ref(path).getDownloadURL();
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      rethrow;
    }
  }

  // Delete file
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  // List files in a directory
  Future<ListResult> listFiles(String path) async {
    try {
      return await _storage.ref(path).listAll();
    } catch (e) {
      debugPrint('Error listing files: $e');
      rethrow;
    }
  }
} 