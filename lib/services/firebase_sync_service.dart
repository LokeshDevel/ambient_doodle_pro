import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';

class FirebaseSyncService {
  final DrawingController controller;
  DatabaseReference? _doodleRef;
  final String _clientId = DateTime.now().microsecondsSinceEpoch.toString();
  
  // Track if we are currently receiving an update from the cloud
  // so we don't infinitely bounce the same drawing back up.
  bool _isReceivingCloudUpdate = false;
  
  // Guard to prevent wiping the cloud with an empty local canvas on startup
  bool _hasLoadedInitialCloudData = false;
  String? _lastPushedLocalHash;
  String? _lastAppliedCloudHash;
  DateTime? _lastLocalEditAt;

  FirebaseSyncService(this.controller) {
    _initFirebase();
  }

  void _initFirebase() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _doodleRef = FirebaseDatabase.instance.ref('session/current_doodle');
        _listenToCloud();
        _listenToLocalController();
      }
    } catch (e) {
      debugPrint("Firebase Sync Init Failed: $e");
    }
  }

  Timer? _debounceTimer;

  void _listenToLocalController() {
    // Add a basic listener to the drawing controller history
    controller.addListener(() {
      _lastLocalEditAt = DateTime.now();
      if (_isReceivingCloudUpdate || !_hasLoadedInitialCloudData) return;
      
      // Debounce the push to cloud to avoid throttling on every drag frame
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _pushLocalToCloud();
      });
    });
  }

  void _pushLocalToCloud() {
    if (_doodleRef == null) return;
    
    try {
      final List<Map<String, dynamic>> serializedPaths = 
          controller.getHistory.map((p) => p.toJson()).toList();

      final String payloadHash = jsonEncode(serializedPaths);
      _lastPushedLocalHash = payloadHash;

      _doodleRef!.set({
        'updatedBy': _clientId,
        'updatedAt': ServerValue.timestamp,
        'paths': serializedPaths,
      });
    } catch (e) {
      debugPrint("Failed to sync drawing to cloud: $e");
    }
  }

  void _listenToCloud() {
    if (_doodleRef == null) return;
    
    _doodleRef!.onValue.listen((DatabaseEvent event) {
      _hasLoadedInitialCloudData = true;
      final data = event.snapshot.value;
      if (data == null) {
        if (!_isReceivingCloudUpdate) {
            _isReceivingCloudUpdate = true;
            controller.clear();
            _isReceivingCloudUpdate = false;
        }
        return;
      }
      
      try {
        dynamic rawPaths = data;
        String? updatedBy;

        // New envelope format: { updatedBy, updatedAt, paths }
        if (data is Map && data['paths'] != null) {
          updatedBy = data['updatedBy']?.toString();
          rawPaths = data['paths'];
        }

        // Ignore echoes of our own writes.
        if (updatedBy != null && updatedBy == _clientId) {
          return;
        }

        final String rawPathsJson = jsonEncode(rawPaths);
        if (rawPathsJson == _lastPushedLocalHash ||
            rawPathsJson == _lastAppliedCloudHash) {
          return;
        }

        final recentLocalEdit = _lastLocalEditAt;
        if (recentLocalEdit != null &&
            DateTime.now().difference(recentLocalEdit) <
                const Duration(seconds: 1)) {
          return;
        }

        _isReceivingCloudUpdate = true;
        
        // Normalize Firebase RTD data types (which are often Map<Object?, Object?>)
        // into strict JSON maps (Map<String, dynamic>) avoiding TypeErrors in fromJson.
        final String jsonString = jsonEncode(rawPaths);
        final List<dynamic> decodedList = jsonDecode(jsonString) as List<dynamic>;
        
        final List<Map<String, dynamic>> jsonPaths = decodedList
            .where((item) => item != null)
            .map((item) {
               final Map<String, dynamic> rawMap = item as Map<String, dynamic>;
               return _normalizeNumbers(rawMap) as Map<String, dynamic>;
            })
            .toList();

        // Warning: flutter_drawing_board doesn't provide a direct static PaintContent.fromJson.
        // We have to use the global DrawingBoard properties, or parse them manually based on 'type'.
        // For now, testing generic loading if the library exposes an undocumented wrapper, otherwise we will write a generic parser.
        // To fix the immediate compile error, we will use the dynamic factory pattern:
        // Due to library limitations, cloud->local restoration requires mapping specific line types manually.
        List<PaintContent> cloudContents = [];
        for (var j in jsonPaths) {
           if (j['type'] == 'SimpleLine') {
              cloudContents.add(SimpleLine.fromJson(j));
           } else if (j['type'] == 'SmoothLine') {
              cloudContents.add(SmoothLine.fromJson(j));
           } else if (j['type'] == 'Eraser') {
              cloudContents.add(Eraser.fromJson(j));
           } else {
              // fallback
              cloudContents.add(SimpleLine.fromJson(j));
           }
        }
        
        controller.clear();
        controller.addContents(cloudContents);
        _lastAppliedCloudHash = rawPathsJson;
        
      } catch (e) {
        debugPrint("Failed to decode cloud drawing data: $e");
      } finally {
        _isReceivingCloudUpdate = false;
      }
    });
  }

  /// Recursively walks a JSON tree and forcefully converts `int` to `double`
  /// ONLY for fields that do NOT strictly require `int` in `flutter_drawing_board`.
  /// Firebase strips `.0` suffixes, turning doubles into ints and causing TypeErrors.
  dynamic _normalizeNumbers(dynamic node, [String? parentKey]) {
    if (node is Map) {
      final Map<String, dynamic> newMap = {};
      node.forEach((key, value) {
        newMap[key as String] = _normalizeNumbers(value, key as String);
      });
      return newMap;
    } else if (node is List) {
      return node.map((e) => _normalizeNumbers(e, parentKey)).toList();
    } else if (node is int) {
      // Safelist of specific fields inside Paint() or Path() that MUST remain int.
      // Every other number in a drawing board payload (x, y, dx, dy, strokeWidth) should be double.
      final intOnlyFields = [
        'color', 'blendMode', 'style', 'strokeCap', 
        'strokeJoin', 'filterQuality', 'fillType'
      ];
      
      if (parentKey != null && intOnlyFields.contains(parentKey)) {
        return node; // Return color, blendMode, etc. as int safely
      }
      
      // Convert all other orphaned ints implicitly acting as sizes/coords back to double
      return node.toDouble();
    }
    return node;
  }
}
