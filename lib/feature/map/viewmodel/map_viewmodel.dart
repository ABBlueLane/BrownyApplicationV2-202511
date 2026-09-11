import 'package:browny_applications_new/core/data/remote/models/converters/marker_icon_converter.dart';
import 'package:browny_applications_new/core/data/remote/models/response/map_location_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/store_detail_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/google_maps_helper.dart';
import 'package:browny_applications_new/core/utils/ui_result.dart';
import 'package:browny_applications_new/core/viewmodels/app_viewmodel.dart';
import 'package:browny_applications_new/feature/map/repository/map_repo.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewModel extends AppViewModel {
  MapViewModel({
    required super.context,
    required this.repo,
  });

  // ========== Repository ==========
  final MapDataSourceMixin repo;

  // ========== Notifier, Controller ==========
  final List<StoreLocationItem> _storeList = [];
  List<StoreLocationItem> get storeList => _storeList;

  TextEditingController textSerchController = TextEditingController();

  /// ความกว้าง marker ปัจจุบัน (bucket ตาม zoom)
  int _markerWidth = GoogleMapsHelper.baseMarkerWidth;
  int get markerWidth => _markerWidth;

  // ========== Logic, Function ==========
  final Map<String, StoreLocationItem?> _servicesAvailable = {
    for (var element in StoreLocationItem.servicesType) element: null,
  };
  Map<String, StoreLocationItem?> get servicesAvialble => _servicesAvailable;

  Future<UiResult<List<StoreLocationItem>>> fetchStoreLocation({
    LatLng? currentPosition,
  }) async {
    final result = await repo.fetchMapLocations(
      currentPosition: currentPosition,
    );

    if (result.isEmpty || result.hasError) {
      return UiResult.empty();
    }
    _storeList.addAll(result.data);

    // Distinct Service Type ที่ API ส่งลงมาเป็นเก็บไว้
    final setServices = _storeList.map((e) => e.type).toSet();
    // Sort เอาที่ Distance ใกล้ที่สุดขึ้นบน
    _storeList.sort(
      // น้อยไปมาก
      (left, right) => left.distance?.compareTo(right.distance ?? 0) ?? 1,
    );

    // loop หา service ที่ Available เป็น key และ Service nearest เป็น Value
    for (final service in setServices) {
      _servicesAvailable[service.orEmpty] = _storeList.firstWhere(
        (e) => e.type == service,
      );
    }

    return UiResult.success(data: _storeList);
  }

  /// Resize marker icons ตามความกว้างใหม่จาก zoom
  ///
  /// ใช้ bytes ที่ cache ใน [MarkerIconConverter] จึงไม่ download ซ้ำ
  /// Returns `true` เมื่อมีการเปลี่ยนขนาดจริง
  Future<bool> resizeMarkerIcons(int width) async {
    if (_storeList.isEmpty || width == _markerWidth) {
      return false;
    }

    _markerWidth = width;
    final converter = MarkerIconConverter();

    try {
      final activeByUrl = <String, BitmapDescriptor>{};
      final inactiveByUrl = <String, BitmapDescriptor>{};

      for (final store in _storeList) {
        final activeUrl = store.markerIconActiveUrl;
        if (activeUrl != null) {
          activeByUrl[activeUrl] ??= await converter.getMarkerIconAtWidth(
            activeUrl,
            width: width,
          );
          store.markerIconActive = activeByUrl[activeUrl];
        }

        final inactiveUrl = store.markerIconInactiveUrl;
        if (inactiveUrl != null) {
          inactiveByUrl[inactiveUrl] ??= await converter.getMarkerIconAtWidth(
            inactiveUrl,
            width: width,
          );
          store.markerIconInactive = inactiveByUrl[inactiveUrl];
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error resizing marker icons: $e');
      return false;
    } finally {
      converter.dispose();
    }
  }

  /// Fetch รายละเอียดร้านค้าตาม storeId และตำแหน่งปัจจุบัน
  ///
  /// Parameters:
  /// - storeId: ID ของร้านค้า
  /// - latitude: ละติจูดของตำแหน่งปัจจุบัน
  /// - longitude: ลองจิจูดของตำแหน่งปัจจุบัน
  ///
  /// Returns: UiResult&lt;StoreData&gt; ที่มีข้อมูลร้านค้าละเอียด รวมถึงสถานะเครื่องซัก/อบ
  Future<UiResult<StoreDataDetail>> fetchStoreDetail({
    required String storeId,
    required String? latitude,
    required String? longitude,
  }) async {
    final result = await repo.fetchStoreDetail(
      storeId: storeId,
      latitude: latitude,
      longitude: longitude,
    );

    if (result.isEmpty || result.hasError) {
      return UiResult.empty();
    }

    return UiResult.success(data: result.data);
  }
}
