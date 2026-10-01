import 'package:browny_applications_new/core/core_index.dart';
import 'package:browny_applications_new/core/data/remote/models/converters/marker_icon_converter.dart';
import 'package:browny_applications_new/core/data/remote/models/request/store_location_request.dart';
import 'package:browny_applications_new/core/data/remote/models/response/map_location_response.dart';
import 'package:browny_applications_new/core/data/remote/models/response/store_detail_response.dart';
import 'package:browny_applications_new/core/data/repo/app_repository.dart';
import 'package:browny_applications_new/core/utils/google_maps_helper.dart';
import 'package:browny_applications_new/core/utils/repo_result.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mixin สำหรับ Map Data Source
mixin MapDataSourceMixin {
  /// Fetch map locations พร้อม marker icons
  Future<RepoResult<List<StoreLocationItem>>> fetchMapLocations({
    LatLng? currentPosition,
  });

  /// Fetch ข้อมูลร้านค้าแบบละเอียดตาม storeId และตำแหน่งปัจจุบัน
  Future<RepoResult<StoreDataDetail>> fetchStoreDetail({
    required String storeId,
    required String? latitude,
    required String? longitude,
  });
}

/// Repository สำหรับจัดการข้อมูล Map
class MapRepo extends AppRepository with MapDataSourceMixin {
  @override
  Future<RepoResult<List<StoreLocationItem>>> fetchMapLocations({
    LatLng? currentPosition,
  }) async {
    final converter = MarkerIconConverter();

    try {
      // 1. Fetch data จาก API
      final response = await requireRemote.fetchMapLocations();

      if (!response.isSuccessful) {
        return RepoResult.empty();
      }

      final locations = response.data.data ?? [];
      if (locations.isEmpty) {
        return RepoResult.success(data: []);
      }

      // 2. หา distinct types และ download marker icons สำหรับแต่ละ type
      final uniqueTypes = <String>{};
      final typeToIcons = <String, Map<String, dynamic>>{};

      // รวบรวม unique types
      for (var location in locations) {
        if (location.type != null) {
          uniqueTypes.add(location.type!);
        }
      }

      // Download marker icons สำหรับแต่ละ type (เอา item แรกของแต่ละ type)
      for (var type in uniqueTypes) {
        final firstItemOfType = locations.firstWhere(
          (item) => item.type == type,
        );

        // Skip if URLs are null
        if (firstItemOfType.markerIconActiveUrl == null ||
            firstItemOfType.markerIconInactiveUrl == null) {
          typeToIcons[type] = {
            'active': null,
            'inactive': null,
          };
          continue;
        }

        try {
          final icons = await converter.getMarkerIcons(
            activeUrl: firstItemOfType.markerIconActiveUrl!,
            inactiveUrl: firstItemOfType.markerIconInactiveUrl!,
            width: GoogleMapsHelper.baseMarkerWidth,
          );

          typeToIcons[type] = icons;
        } catch (e) {
          debugPrint('Error downloading icons for type $type: $e');
          // ถ้า download ไม่ได้ ให้ใช้ default marker
          typeToIcons[type] = {
            'active': null,
            'inactive': null,
          };
        }
      }

      // 3. Assign marker icons ให้กับทุก items ตาม type
      final updatedLocations = locations.map((location) {
        final icons = typeToIcons[location.type];
        double distance = 0.0;
        try {
          if (currentPosition != null) {
            distance = LocationHelper.calculateDistance(
              currentPosition.latitude,
              currentPosition.longitude,
              location.latitudeValue,
              location.longitudeValue,
            );
          }
        } on Exception catch (_) {}

        return location.copyWith(
          markerIconActive: icons?['active'],
          markerIconInactive: icons?['inactive'],
          distance: distance,
        );
      }).toList();

      return RepoResult.success(data: updatedLocations);
    } on DioException catch (dioEx) {
      return RepoResult.error(error: dioEx);
    } on Exception catch (e) {
      return RepoResult.error(error: e);
    } finally {
      // ปิด Dio instance ของ converter
      converter.dispose();
    }
  }

  @override
  Future<RepoResult<StoreDataDetail>> fetchStoreDetail({
    required String storeId,
    required String? latitude,
    required String? longitude,
  }) async {
    try {
      // สร้าง request body
      final request = StoreLocationRequest(
        latitude: latitude,
        longitude: longitude,
      );

      // เรียก API
      final response = await requireRemote.fetchStoreDetail(storeId, request);

      if (!response.isSuccessful || response.data.data == null) {
        return RepoResult.empty();
      }

      return RepoResult.success(data: response.data.data!);
    } on DioException catch (dioEx) {
      return RepoResult.error(error: dioEx);
    } on Object catch (e) {
      return RepoResult.error(error: e as Exception);
    }
  }
}
