// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:browny_applications_new/core/data/remote/models/response/map_location_response.dart';
import 'package:browny_applications_new/core/utils/app_extensions.dart';
import 'package:browny_applications_new/core/utils/google_maps_helper.dart';
import 'package:browny_applications_new/core/utils/location_helper.dart';
import 'package:browny_applications_new/core/utils/permission_helper.dart';
import 'package:browny_applications_new/core/widgets/app_overlays.dart';
import 'package:browny_applications_new/core/widgets/app_text.dart';
import 'package:browny_applications_new/core/widgets/store_bottom_sheet_dialog.dart';
import 'package:browny_applications_new/feature/map/repository/map_repo.dart';
import 'package:browny_applications_new/feature/map/screens/store_detail_page.dart';
import 'package:browny_applications_new/feature/map/viewmodel/map_viewmodel.dart';
import 'package:browny_applications_new/res/colors/app_colors.dart';
import 'package:browny_applications_new/res/dims/app_dims.dart';
import 'package:browny_applications_new/res/icons/assets.gen.dart';
import 'package:browny_applications_new/res/strings/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  static final pagePath = '/Map';
  static final pageName = 'map_page';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapViewModel(
        context: context,
        repo: MapRepo(),
      ),
      child: MapContent(),
    );
  }
}

class MapContent extends StatefulWidget {
  const MapContent({super.key});

  @override
  State<MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  late final MapViewModel _viewmodel;

  // ========== Google Map Controllers & Data ==========
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentPosition;

  bool _isSearching = false;

  // ========== Speech to Text ==========
  late stt.SpeechToText _speech;
  bool _isListening = false;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  // Initial camera position (Bangkok default)
  final CameraPosition _initialCameraPosition = CameraPosition(
    target: GoogleMapsHelper.defaultLocation,
    zoom: GoogleMapsHelper.defaultZoom,
  );

  @override
  void initState() {
    super.initState();
    _viewmodel = context.read();
    _viewmodel.attachContext(context);
    _speech = stt.SpeechToText();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeMap();
    });
  }

  /// Initialize map: check permission, get location, fetch stores
  Future<void> _initializeMap() async {
    // 1. Check location permission
    final hasPermission = await PermissionHelper.hasLocationPermission();
    if (!hasPermission) {
      final granted = await PermissionHelper.requestLocationPermission();
      if (context.mounted && !granted.isGranted) {
        AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyError2.path,
          // ไม่สามารถเข้าถึงตำแหน่งได้,
          title: context.wording.locationAccessDeniedTitle,
          // กรุณาให้สิทธิ์เข้าถึงตำแหน่งก่อนใช้งาน,
          message: context.wording.locationAccessDeniedMessage,
          // เปิด Setting,
          confirmText: context.wording.openSettings,
          onConfirm: () async {
            await PermissionHelper.openAppSettings();
            // recursive
            await _initializeMap();
          },
          cancelText: context.wording.cancel,
        );
        // return;
      }
    }

    // 2. Get current position
    _findCurrentPositsion().then((_) async {
      // 3. Fetch store locations
      await _fetchAndDisplayStores();
    });
  }

  Future<void> _findCurrentPositsion() async {
    try {
      final position = await LocationHelper.getCurrentPosition(
        currentPosition: _currentPosition,
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting current position: $e');
    }
  }

  /// Fetch stores and create markers
  Future<void> _fetchAndDisplayStores() async {
    final result = await _viewmodel.fetchStoreLocation(
      currentPosition: _currentPosition,
    );

    if (result.isSuccess && result.data != null) {
      final stores = result.data!;

      if (mounted) {
        setState(() {
          _markers = _createMarkersFromStores(stores);
        });

        // Move camera to current position if available
        if (_currentPosition != null && _mapController != null) {
          await _moveCameraTo(_currentPosition!);
        }
      }
    }
  }

  Future<void> _moveCameraTo(LatLng newPosition, {double zoom = 15.0}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newPosition,
            zoom: zoom,
          ),
        ),
      );
    }
  }

  /// Create markers from store location items
  Set<Marker> _createMarkersFromStores(List<StoreLocationItem> stores) {
    return stores.map((store) {
      return Marker(
        markerId: MarkerId('${store.type}#${store.id.toString()}'),
        position: LatLng(store.latitudeValue, store.longitudeValue),
        icon: store.markerIconActive ?? BitmapDescriptor.defaultMarker,
        // infoWindow: InfoWindow(
        //   title: store.getLocalizedName(context.languageCode),
        //   snippet: store.getLocalizedAddress(context.languageCode),
        // ),
        onTap: () async {
          await _onMarkerTapped(store);
        },
      );
    }).toSet();
  }

  /// Handle marker tap
  Future<void> _onMarkerTapped(StoreLocationItem store) async {
    AppOverlays.showLoading(context);
    final storeResult = await _viewmodel.fetchStoreDetail(
      storeId: store.id?.toString() ?? '',
      latitude: _currentPosition?.latitude.toString(),
      longitude: _currentPosition?.longitude.toString(),
    );

    AppOverlays.hideLoading();
    if (!mounted) return;

    if (storeResult.hasError) {
      AppOverlays.showBrownyErrorDialog(
        context,
        // ไม่พบข้อมูล,
        title: context.wording.dataNotFound,
        error: storeResult.error,
      );
      return;
    }

    if (storeResult.isEmpty) {
      AppOverlays.showBrownyDialog(
        context,
        // ไม่พบข้อมูล,
        title: context.wording.dataNotFound,
        message: context.wording.errorUi,
      );
      return;
    }
    // print('Store tapped: ${store.getLocalizedName('th')}');
    StoreBottomSheetDialog.showDialog(
      context,
      storeResult.data!,
      (heroTag) {
        context.pushNamed(
          StoreDetailPage.pageName,
          extra: storeResult.data!,
        );
      },
    );
  }

  /// Start listening to voice input
  Future<void> _startListening() async {
    // Check if speech recognition is available
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _stateSpeechingingChnage();
        }
      },
      onError: (error) {
        _stateSpeechingingChnage();
      },
    );

    if (!available) {
      if (context.mounted) {
        AppOverlays.showBrownyDialog(
          context,
          imageAsset: Assets.png.brownyError2.path,
          // เกิดข้อผิดพลาด,
          title: context.wording.errorOccurred,
          // อุปกรณ์ของคุณไม่รองรับการค้นหาด้วยเสียง,
          message: context.wording.voiceSearchNotSupported,
          confirmText: context.wording.confirm,
        );
      }
      return;
    }

    // Start listening
    _stateSpeechingingChnage();
    _searchFocusNode.requestFocus();
    _stateSearchingChange();

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      // ตาม Local
      localeId: context.languageCode,
    );
  }

  /// Stop listening to voice input
  Future<void> _stopListening() async {
    await _speech.stop();
    _stateSpeechingingChnage();
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusTextChange);
    _mapController?.dispose();
    // _searchController.dispose();
    // _searchFocusNode.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Map แสดงเต็มหน้า
              GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
              ),

              // Widget Searching
              Align(
                alignment: AlignmentGeometry.topCenter,
                child: SafeArea(
                  child: Row(
                    children: [
                      AppDims.horizonPadding_16,

                      if (!_isSearching) ...[
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppColors.defatultShadow,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton.filled(
                            onPressed: () => context.safePop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              shape: CircleBorder(),
                              shadowColor: AppColors.textSecondary,
                            ),
                            icon: Assets.svg.icArrowBackward.svg(
                              width: 18.w,
                              colorFilter: ColorFilter.mode(
                                AppColors.gray600,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        AppDims.horizonPadding_16,
                      ],

                      // ช่อง search
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: AppColors.defatultShadow,
                          ),
                          child: Autocomplete<StoreLocationItem>(
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _viewmodel.storeList.take(4);
                              }
                              return _viewmodel.storeList.where(
                                (item) => item
                                    .getLocalizedName(context.languageCode)
                                    .contains(
                                      textEditingValue.text.toLowerCase(),
                                    ),
                              );
                            },
                            // สิ่งที่จะเอาแสดง
                            displayStringForOption: (option) {
                              return option.getLocalizedName(
                                context.languageCode,
                              );
                            },
                            // List drop จากช่อง Search
                            optionsViewBuilder: _buildOptionsViewBuilder,
                            // ช่อง Search
                            fieldViewBuilder: _buildFieldViewBuilder,
                            onSelected: (option) => unawaited(
                              _onFilterSelected(option),
                            ),
                          ),
                        ),
                      ),
                      AppDims.horizonPadding_16,
                    ],
                  ),
                ),
              ),

              // Widget filter, My location
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // My location
                      Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: GestureDetector(
                          onTap: () async {
                            AppOverlays.showLoading(context);
                            await _findCurrentPositsion();

                            AppOverlays.hideLoading();
                            if (_currentPosition != null) {
                              _moveCameraTo(_currentPosition!);
                            }
                          },
                          child: Assets.svg.icMyLocationRegWhite.svg(),
                        ),
                      ),

                      // filter Browny, Browny+, Charger
                      Container(
                        padding: EdgeInsets.only(
                          top: AppDims.size_4.w,
                          bottom: AppDims.size_32.w,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: _buildServicesCard(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildServicesCard() {
    // browny ซักอบ
    StoreLocationItem? service1 =
        _viewmodel.servicesAvialble[StoreLocationItem.kService1];

    // browny ซักอบ พับ
    StoreLocationItem? service2 =
        _viewmodel.servicesAvialble[StoreLocationItem.kService2];

    // Station Charge
    StoreLocationItem? service3 =
        _viewmodel.servicesAvialble[StoreLocationItem.kService3];
    return [
      // Padding หัว เว้นจากขอบจอ
      AppDims.horizonPadding_16,

      if (service1 != null) ...[
        GestureDetector(
          onTap: () {
            unawaited(_onFilterSelected(service1));
          },
          child: _buildCardFilterServices(
            service: service1,
            image: Assets.png.bgMapBrowny,
          ),
        ),
        AppDims.horizonPadding_8,
      ],

      if (service2 != null) ...[
        GestureDetector(
          onTap: () {
            unawaited(_onFilterSelected(service2));
          },
          child: _buildCardFilterServices(
            service: service2,
            image: Assets.png.bgMapBrownyPlus,
          ),
        ),
        AppDims.horizonPadding_8,
      ],

      if (service3 != null) ...[
        GestureDetector(
          onTap: () {
            unawaited(_onFilterSelected(service3));
          },
          child: _buildCardFilterServices(
            service: service3,
            image: Assets.png.bgMapCharger,
          ),
        ),
        AppDims.horizonPadding_8,
      ],

      // Padding ปิด เว้นจากขอบจอ
      AppDims.horizonPadding_16,
    ];
  }

  Widget _buildFieldViewBuilder(
    BuildContext context,
    TextEditingController textEditingController,
    FocusNode focusNode,
    VoidCallback onFieldSubmitted,
  ) {
    // Use our controllers
    _searchController = textEditingController;
    _searchFocusNode = focusNode;
    _searchFocusNode.removeListener(
      _onFocusTextChange,
    );
    _searchFocusNode.addListener(
      _onFocusTextChange,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDims.size_16.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: _isSearching
            ? BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              )
            : BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Icon นำหน้า Text Search
          // - ถ้ายังไม่มีการ focus จะเป็นปุ่มกลับ pop ออกจากหน้า
          // - focus อยู่จะเป็นปุ่ม กลับ เพื่อปิด Keyborad
          _buildPrefixIconSearching(focusNode),

          // TextField Search
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: textEditingController,
              style: context.textTheme.labelLarge,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                ),
                hintText: context.wording.typeStoreName,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle: context.textTheme.labelLarge!.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              onEditingComplete: onFieldSubmitted,
            ),
          ),

          // Text Speech to searching
          GestureDetector(
            onTap: () async {
              if (_isListening) {
                await _stopListening();
              } else {
                await _startListening();
              }
            },
            child: _isListening
                ? Assets.svg.icSpeech.svg(
                    colorFilter: ColorFilter.mode(
                      AppColors.primary,
                      BlendMode.srcIn,
                    ),
                  )
                : Assets.svg.icSpeech.svg(
                    colorFilter: ColorFilter.mode(
                      AppColors.gray600,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsViewBuilder(
    BuildContext context,
    AutocompleteOnSelected<StoreLocationItem> onSelected,
    Iterable<StoreLocationItem> options,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8.r),
          bottomRight: Radius.circular(8.r),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (context, index) => Divider(
          indent: 16.w,
          endIndent: 16.w,
        ),
        itemCount: options.take(6).length,
        itemBuilder: (context, i) {
          final data = options.toList()[i];

          String subTitle;
          TextStyle subTitleStyle;
          if (data.isMachineAvailable) {
            // ว่าง;
            subTitle = context.wording.machineAvailable;
            subTitleStyle = context.textTheme.labelLarge!.copyWith(
              color: AppColors.primary,
            );
          } else {
            // เต็ม;
            subTitle = context.wording.machineOccupied;
            subTitleStyle = context.textTheme.labelLarge!.copyWith(
              color: AppColors.error,
            );
          }
          // if (i == 3) {
          //   subTitle = 'ปิดปรับปรุง';
          //   subTitleStyle = context.textTheme.labelLarge!.copyWith(
          //     color: AppColors.yellow2,
          //   );
          // }
          return ListTile(
            // leading: Assets.svg.icLocation.svg(),
            leading: Image.network(
              width: AppDims.size_40.w,
              data.icon.orEmpty,
            ),
            title: AppText(
              data.getLocalizedName(
                context.languageCode,
              ),
              style: context.textTheme.labelLarge,
            ),
            subtitle: AppText(
              subTitle,
              style: subTitleStyle,
            ),

            trailing: AppText(
              data.getDistaceDisplay(
                context.languageCode,
              ),
              style: context.textTheme.labelLarge!.copyWith(
                color: AppColors.gray500,
              ),
            ),
            onTap: () {
              unawaited(_onFilterSelected(options.toList()[i]));
              // _searchFocusNode.unfocus();

              // _searchController.text = options.toList()[i].getLocalizedName(
              //   context.languageCode,
              // );

              // await _moveCameraTo(
              //   LatLng(
              //     data.latitudeValue,
              //     data.longitudeValue,
              //   ),
              // );
            },
          );
        },
      ),
    );
  }

  Widget _buildCardFilterServices({
    required StoreLocationItem service,
    required AssetGenImage image,
    int width = 115,
  }) {
    return Container(
      width: width.w,
      padding: EdgeInsets.only(
        top: AppDims.size_40.h,
        bottom: AppDims.size_48.h,
        left: AppDims.size_8.w,
        right: AppDims.size_8.w,
      ),
      decoration: BoxDecoration(
        // borderRadius: BorderRadius.circular(16.r),
        image: DecorationImage(
          image: image.provider(),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDims.vericalPadding_12,
          AppText(
            service.getTypeToTypeName(context.languageCode),
            style: context.textTheme.labelMedium!.copyWith(
              color: AppColors.textWhite,
            ),
          ),
          AppText(
            service.getNearestDisplay(context.languageCode),
            style: context.textTheme.labelSmall!.copyWith(
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefixIconSearching(FocusNode focusNode) {
    if (_isSearching) {
      return GestureDetector(
        onTap: () {
          focusNode.unfocus();
        },
        child: Assets.svg.icArrowBackward.svg(
          width: 18.w,
          colorFilter: ColorFilter.mode(AppColors.gray600, BlendMode.srcIn),
        ),
      );
    }

    return Assets.svg.icMagnify.svg(
      width: 18.w,
      colorFilter: ColorFilter.mode(AppColors.gray600, BlendMode.srcIn),
    );
  }

  Future<void> _onFilterSelected(StoreLocationItem service) async {
    _searchFocusNode.unfocus();

    _searchController.text = service.getLocalizedName(
      context.languageCode,
    );
    await _onMarkerTapped(service);
    unawaited(
      _moveCameraTo(
        LatLng(
          service.latitudeValue,
          service.longitudeValue,
        ),
      ),
    );
  }

  void _onFocusTextChange() {
    _stateSearchingChange();
  }

  void _stateSearchingChange() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  void _stateSpeechingingChnage() {
    setState(() {
      _isListening = !_isListening;
    });
  }
}
