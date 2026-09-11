import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:browny_applications_new/core/core_index.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// DONG 2026-01-28
///
/// Converter สำหรับ download marker icon จาก URL และแปลงเป็น BitmapDescriptor
class MarkerIconConverter {
  /// Cache bytes ต้นฉบับตาม URL เพื่อ resize ซ้ำได้โดยไม่ต้อง download ใหม่
  static final Map<String, Uint8List> _bytesCache = {};

  /// Dio instance เฉพาะกิจสำหรับ download รูปภาพ
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Download marker icon จาก URL และแปลงเป็น BitmapDescriptor
  ///
  /// [url] - URL ของรูปภาพ marker
  /// [width] - ความกว้างที่ต้องการ resize (default: 100)
  Future<BitmapDescriptor> getMarkerIconFromUrl(
    String url, {
    int width = 100,
  }) async {
    try {
      final imageData = await _getOrDownloadBytes(url);
      if (imageData == null) {
        return BitmapDescriptor.defaultMarker;
      }
      return resizeFromBytes(imageData, width: width);
    } catch (e) {
      debugPrint("Dio Error loading marker: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Resize จาก bytes ที่ cache ไว้แล้ว (ไม่ download ซ้ำ)
  ///
  /// ถ้ายังไม่มีใน cache จะ download ให้ก่อน
  Future<BitmapDescriptor> getMarkerIconAtWidth(
    String url, {
    required int width,
  }) async {
    return getMarkerIconFromUrl(url, width: width);
  }

  /// Download marker icons ทั้ง active และ inactive พร้อมกัน
  ///
  /// Returns: Map with 'active' and 'inactive' keys
  Future<Map<String, BitmapDescriptor>> getMarkerIcons({
    required String activeUrl,
    required String inactiveUrl,
    int width = 100,
  }) async {
    try {
      final results = await Future.wait([
        getMarkerIconFromUrl(activeUrl, width: width),
        getMarkerIconFromUrl(inactiveUrl, width: width),
      ]);

      return {
        'active': results[0],
        'inactive': results[1],
      };
    } catch (e) {
      debugPrint("Error loading marker icons: $e");
      return {
        'active': BitmapDescriptor.defaultMarker,
        'inactive': BitmapDescriptor.defaultMarker,
      };
    }
  }

  /// Resize bytes เป็น BitmapDescriptor ตามความกว้างที่กำหนด
  Future<BitmapDescriptor> resizeFromBytes(
    Uint8List imageData, {
    required int width,
  }) async {
    try {
      final ui.Codec codecForSize = await ui.instantiateImageCodec(imageData);
      final ui.FrameInfo frameInfoForSize = await codecForSize.getNextFrame();
      final originalWidth = frameInfoForSize.image.width;
      final originalHeight = frameInfoForSize.image.height;
      frameInfoForSize.image.dispose();

      final aspectRatio = originalHeight / originalWidth;
      final targetHeight = (width * aspectRatio).round();

      final ui.Codec codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: width,
        targetHeight: targetHeight,
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ByteData? byteData = await frameInfo.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frameInfo.image.dispose();

      if (byteData == null) {
        return BitmapDescriptor.defaultMarker;
      }

      return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
    } catch (e) {
      debugPrint("Error resizing marker: $e");
      return BitmapDescriptor.defaultMarker;
    }
  }

  Future<Uint8List?> _getOrDownloadBytes(String url) async {
    final cached = _bytesCache[url];
    if (cached != null) {
      return cached;
    }

    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      final imageData = Uint8List.fromList(response.data!);
      _bytesCache[url] = imageData;
      return imageData;
    }
    return null;
  }

  /// Dispose Dio instance
  void dispose() {
    _dio.close();
  }
}
