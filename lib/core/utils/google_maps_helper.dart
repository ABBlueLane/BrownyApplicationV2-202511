import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper class สำหรับจัดการ Google Maps
class GoogleMapsHelper {
  // Private constructor เพื่อป้องกันการสร้าง instance
  GoogleMapsHelper._();

  /// ค่า default ของตำแหน่งเริ่มต้น (Bangkok, Thailand)
  static const LatLng defaultLocation = LatLng(13.7563, 100.5018);

  /// ค่า default ของ Zoom level
  static const double defaultZoom = 15.0;

  /// ความกว้าง marker ที่ zoom ปกติ (defaultZoom)
  static const int baseMarkerWidth = 80;

  /// ความกว้าง marker ต่ำสุดเมื่อซูมออกมาก
  static const int minMarkerWidth = 20;

  /// ความกว้าง marker สูงสุดเมื่อซูมเข้ามาก
  static const int maxMarkerWidth = 100;

  /// คำนวณความกว้าง marker ตาม zoom เป็น bucket
  /// เพื่อลดการ regenerate BitmapDescriptor บ่อยเกินไป
  ///
  /// zoom < 11 → 20px, < 13 → 32px, < 14.5 → 48px, < 16 → 80px, นอกนั้น → 100px
  static int calculateMarkerWidth(double zoom) {
    if (zoom < 11) return minMarkerWidth;
    if (zoom < 13) return 32;
    if (zoom < 14.5) return 48;
    if (zoom < 16) return baseMarkerWidth;
    return maxMarkerWidth;
  }

  /// สร้าง Camera Position
  static CameraPosition createCameraPosition({
    required LatLng target,
    double zoom = defaultZoom,
    double tilt = 0,
    double bearing = 0,
  }) {
    return CameraPosition(
      target: target,
      zoom: zoom,
      tilt: tilt,
      bearing: bearing,
    );
  }

  /// สร้าง Marker
  static Marker createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
    Color? color,
  }) {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
    );
  }

  /// สร้าง Circle สำหรับแสดงพื้นที่
  static Circle createCircle({
    required String circleId,
    required LatLng center,
    required double radius, // radius in meters
    Color? fillColor,
    Color? strokeColor,
    double strokeWidth = 2,
  }) {
    return Circle(
      circleId: CircleId(circleId),
      center: center,
      radius: radius,
      fillColor: fillColor ?? Colors.blue.withValues(alpha: 0.2),
      strokeColor: strokeColor ?? Colors.blue,
      strokeWidth: strokeWidth.round(),
    );
  }

  /// สร้าง Polyline สำหรับแสดงเส้นทาง
  static Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color? color,
    double width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color ?? Colors.blue,
      width: width.round(),
    );
  }

  /// อัพเดท Camera ให้ไปยังตำแหน่งใหม่
  static Future<void> animateCamera(
    GoogleMapController controller, {
    required LatLng target,
    double zoom = defaultZoom,
  }) async {
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: zoom,
        ),
      ),
    );
  }

  /// ปรับ Camera ให้แสดงทุก Markers ในหน้าจอ
  static Future<void> fitBounds(
    GoogleMapController controller,
    List<LatLng> positions, {
    double padding = 50,
  }) async {
    if (positions.isEmpty) return;

    if (positions.length == 1) {
      await animateCamera(controller, target: positions.first);
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var position in positions) {
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        padding,
      ),
    );
  }

  /// สร้าง Custom Marker จาก Widget
  ///
  /// NOTE: ต้อง import 'dart:ui' as ui; ด้วย
  /// และใช้ package:flutter/services.dart
  /* Example usage:
  static Future<BitmapDescriptor> createCustomMarkerFromWidget(
    Widget widget, {
    Size size = const Size(150, 150),
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Render widget to canvas
    final widgetRepaintBoundary = RepaintBoundary(child: widget);
    // ... implementation

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }
  */

  /// Map Styles - ใช้สำหรับกำหนด theme ของ map
  /// TODO: เพิ่ม JSON style ตามต้องการ
  /// Reference: https://mapstyle.withgoogle.com/
  static const String? lightMapStyle = null; // Add your light theme JSON here
  static const String? darkMapStyle = null; // Add your dark theme JSON here

  /// คำนวณ zoom level ที่เหมาะสมตามระยะทาง
  static double calculateZoomLevel(double radiusInMeters) {
    double zoomLevel = 16;
    if (radiusInMeters > 0) {
      double radiusElevated = radiusInMeters + radiusInMeters / 2;
      double scale = radiusElevated / 500;
      zoomLevel = (16 - (scale.clamp(0, 20)));
    }
    return zoomLevel;
  }
}
