import 'dart:io';
import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/api_service.dart';

class PropertyProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Property> properties = [];
  Property? selectedProperty;
  bool isLoading = false;
  String? error;

  Future<void> fetchProperties() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      properties = await _api.getProperties();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProperty(int id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      selectedProperty = await _api.getProperty(id);
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<Property?> createProperty(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final property = await _api.createProperty(data);
      await fetchProperties();
      return property;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProperty(int id, Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.updateProperty(id, data);
      await fetchProperties();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadImage(int propertyId, File image, String? roomTag) async {
    try {
      await _api.uploadPropertyImage(propertyId, image, roomTag);
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
