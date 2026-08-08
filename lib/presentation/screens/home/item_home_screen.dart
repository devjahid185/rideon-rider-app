import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_on/app/route_settings.dart';
import 'package:ride_on/core/services/config.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/core/extensions/helper/push_notifications.dart';
import 'package:ride_on/core/utils/common_widget.dart' hide goTo;
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/domain/entities/food_models.dart';
import 'package:ride_on/domain/entities/Sliders_data.dart';
import 'package:ride_on/domain/entities/catrgory.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/domain/entities/service_type.dart';
import 'package:ride_on/presentation/cubits/food_cubit.dart';
import 'package:ride_on/presentation/cubits/slider_cubit.dart';
import 'package:ride_on/presentation/cubits/vehicle_data/get_service_type_cubit.dart';
import 'package:ride_on/presentation/screens/home/parcel_details_screen.dart'
    show ParcelDetailsScreen;
import 'package:ride_on/presentation/screens/food/food_home_screen.dart';
import 'package:ride_on/presentation/screens/food/food_menu_screen.dart';
import 'package:ride_on/presentation/screens/food/food_orders_screen.dart';
import 'package:ride_on/presentation/screens/search/search_map_screen.dart';
import 'package:ride_on/presentation/widgets/drawer_custom.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/data_store.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/general_cubit.dart';
import '../../cubits/location/user_current_location_cubit.dart';
import '../../cubits/profile/edit_profile_cubit.dart';
import '../../cubits/realtime/update_ride_request_parameter.dart';
import '../../cubits/vehicle_data/get_vehicle_cetgegory_cubit.dart';
import '../Search/loading_nearby_search_screen.dart';
import '../Search/route_location_screen.dart';

class ItemHomeScreen extends StatefulWidget {
  const ItemHomeScreen({super.key});

  @override
  State<ItemHomeScreen> createState() => _ItemHomeScreenState();
}

class _ItemHomeScreenState extends State<ItemHomeScreen>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<LatLng> _selectedLocation = ValueNotifier(
    const LatLng(0, 0),
  );
  Timer? _debounceTimer;
  bool showAlert = false;
  late TabController _tabController;
  int _selectedTab = 0;
  bool get _isFoodTab =>
      serviceTypes.isNotEmpty && _selectedTab == serviceTypes.length;
  String? pickupLocation;
  String? dropLocation;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  double? pickupLat;
  double? pickupLng;
  double? dropLat;
  double? dropLng;
  List<Map<String, dynamic>> scheduledRides = [];
  List<FoodRestaurant> _cachedFoodRestaurants = [];
  int _selectedFoodCategory = 0;
  String _foodSearchQuery = '';
  String _foodDeliveryAddress = '';
  final TextEditingController _foodSearchController = TextEditingController();

  static const List<_FoodCategoryShortcut> _foodCategories = [
    _FoodCategoryShortcut('All', Icons.dashboard_customize_rounded, ''),
    _FoodCategoryShortcut('Burger', Icons.lunch_dining_rounded, 'burger'),
    _FoodCategoryShortcut('Pizza', Icons.local_pizza_rounded, 'pizza'),
    _FoodCategoryShortcut('Rice', Icons.rice_bowl_rounded, 'rice'),
    _FoodCategoryShortcut('Drinks', Icons.local_cafe_rounded, 'drink'),
    _FoodCategoryShortcut('Dessert', Icons.icecream_rounded, 'dessert'),
  ];

  @override
  void initState() {
    super.initState();
    getFCMToken();

    box.delete('current_parcel_data');
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(_handleTabSelection);
    _loadRecentDropLocations();
    context.read<MyImageCubit>().updateMyImage(myImage);
    context.read<BookRideRealTimeDataBaseCubit>().updateUserImageUrl(
      userImageUrl: myImage,
    );
    context.read<UpdateRideRequestParameterCubit>().updateFirebaseUserParameter(
      rideId: context.read<BookRideRealTimeDataBaseCubit>().state.rideId,
      userParameter: {"userImageUrl": myImage},
    );
    context.read<NameCubit>().updateName(loginModel?.data?.firstName ?? "");
    context.read<EmailCubit>().updateEmail(loginModel?.data?.email ?? "");
    isNumeric = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeApp();
      showNotification(context);
    });
  }

  void _handleTabSelection() {
    if (mounted && _selectedTab != _tabController.index) {
      setState(() {
        _selectedTab = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _tabController.removeListener(_handleTabSelection);
    _foodSearchController.dispose();
    _tabController.dispose();
    _selectedLocation.dispose();
    super.dispose();
  }

  List<Map<String, String>> recentDropLocations = [];
  void _loadRecentDropLocations() {
    final storedList = box.get('recent_drop_locations', defaultValue: []);
    if (storedList is List) {
      recentDropLocations = storedList
          .map((e) => Map<String, String>.from(e))
          .toList();
    }
    setState(() {});
  }

  String _currentAddress = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInitialLocationLoaded = false;
  bool _isLoadingLocation = false;

  Future<void> _initializeApp() async {
    if (!mounted) return;
    // context.read<GetVehicleDataCubit>().getAllCategories();
    context.read<GetServiceTypeDataCubit>().getServiceType();
    context.read<SlidersCubit>().getSlidersList(context);
    getCurrency(context);
    getUserDataLocallyToHandleTheState(context);
    await _loadInitialLocation();
  }

  Future<void> _loadFoodRestaurantsForCurrentLocation() async {
    final selected = _selectedLocation.value;
    final hasValidLocation = selected.latitude != 0 && selected.longitude != 0;
    debugPrint(
      '[FoodHomeTab] load requested selectedLat=${selected.latitude} '
      'selectedLng=${selected.longitude} hasValid=$hasValidLocation',
    );
    if (!hasValidLocation) {
      await startLiveLocationTracking();
    }

    if (!mounted) return;
    final latest = _selectedLocation.value;
    final hasLatestLocation = latest.latitude != 0 && latest.longitude != 0;
    debugPrint(
      '[FoodHomeTab] load after location latestLat=${latest.latitude} '
      'latestLng=${latest.longitude} hasValid=$hasLatestLocation',
    );
    if (!hasLatestLocation) {
      context.read<FoodCubit>().showFailure(
        'Please enable location and refresh food restaurants.',
      );
      return;
    }

    context.read<FoodCubit>().loadNearbyRestaurants(
      latitude: latest.latitude,
      longitude: latest.longitude,
      radiusKm: 30,
    );
  }

  Future<void> _loadInitialLocation() async {
    if (!mounted || _isInitialLocationLoaded || _isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);
    final cachedFoodAddress =
        (box.get('food_delivery_address', defaultValue: '') ?? '').toString();
    if (cachedFoodAddress.isNotEmpty) {
      _foodDeliveryAddress = cachedFoodAddress;
    }
    final cachedLocation = await _loadCachedLocation();
    if (!mounted) return;
    if (cachedLocation != null) {
      _selectedLocation.value = cachedLocation;
      setState(() => _isInitialLocationLoaded = true);
    }
    try {
      await startLiveLocationTracking(isInitialLoad: true).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) {
            setState(() => _isInitialLocationLoaded = true);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      showErrorToastMessage('Error getting location: $e');
      setState(() => _isInitialLocationLoaded = true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<LatLng?> _loadCachedLocation() async {
    final lat = box.get('last_latitude');
    final lng = box.get('last_longitude');
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }

  Future<void> startLiveLocationTracking({bool isInitialLoad = false}) async {
    if (!mounted || (_isLoadingLocation && !isInitialLoad)) return;
    try {
      _isLoadingLocation = true;
      LocationPermission permission = await _checkPermissions();
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showAlert == true) {
          return;
        }
        _showPermissionDeniedDialog();
        showAlert = true;
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      updateUserLocation(position);
    } catch (e) {
      if (!mounted) return;
      showErrorToastMessage('Error getting location: $e');
    } finally {
      if (mounted && !isInitialLoad) {
        _isLoadingLocation = false;
      }
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: notifires.getbgcolor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Location Access Needed".translate(context),
                style: heading2Grey1(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To keep your rides accurate and smooth, please allow location access. You can enable it easily by following these steps:"
                  .translate(context),
              style: regular2(context),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.arrow_right_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Open your phone's Settings".translate(context),
                    style: regular2(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.arrow_right_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Go to App Permissions".translate(context),
                    style: regular2(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.arrow_right_rounded,
                    size: 20,
                    color: Colors.blueAccent,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Allow Location Access for this app".translate(context),
                    style: regular2(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Not Now".translate(context),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.settings, size: 18, color: Colors.white),
            label: Text(
              "Open Settings".translate(context),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<LocationPermission> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showErrorToastMessage(
          "Please enable location services".translate(context),
        );
      }
      return LocationPermission.denied;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  void updateUserLocation(Position position) {
    if (!mounted) return;
    debugPrint(
      '[FoodHomeTab] GPS resolved lat=${position.latitude} lng=${position.longitude}',
    );
    final location = LatLng(position.latitude, position.longitude);
    _selectedLocation.value = location;
    latitudeGlobal = position.latitude.toString();
    longitudeGlobal = position.longitude.toString();
    box.put('last_latitude', position.latitude);
    box.put('last_longitude', position.longitude);
    if (_foodDeliveryAddress.isEmpty && _currentAddress.isNotEmpty) {
      _foodDeliveryAddress = _currentAddress;
      box.put('food_delivery_address', _currentAddress);
    }
    if (_isFoodTab) {
      context.read<FoodCubit>().loadNearbyRestaurants(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 30,
      );
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.read<UpdateCurrentAddressCubit>().getAddressFromLatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  Future<void> _selectFoodLocationFromMap() async {
    FocusScope.of(context).unfocus();

    final current = _selectedLocation.value;
    if (current.latitude != 0 && current.longitude != 0) {
      context.read<BookRideRealTimeDataBaseCubit>().updatePickupLatAndLng(
        pickupAddressLatitude: current.latitude.toString(),
        pickupAddressLongitude: current.longitude.toString(),
      );
    }

    final selectedCubit = context.read<SelectedAddressCubit>();
    selectedCubit.dropOffAddressController.text =
        _foodDeliveryAddress.isNotEmpty
        ? _foodDeliveryAddress
        : _currentAddress;

    final picked = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMapScreen(
          selectedAddressTitle: _foodDeliveryAddress.isNotEmpty
              ? _foodDeliveryAddress
              : _currentAddress,
          checkStatus: false,
        ),
      ),
    );

    if (!mounted || picked is! Map) return;

    final lat = double.tryParse((picked['lat'] ?? '').toString());
    final lng = double.tryParse((picked['lng'] ?? '').toString());
    final address =
        (picked['address'] ?? selectedCubit.dropOffAddressController.text)
            .toString()
            .trim();

    if (lat == null || lng == null) {
      showErrorToastMessage(
        'Could not detect selected location'.translate(context),
      );
      return;
    }

    debugPrint(
      '[FoodHomeTab] manual map location selected lat=$lat lng=$lng address=$address',
    );

    setState(() {
      _selectedLocation.value = LatLng(lat, lng);
      _foodDeliveryAddress = address;
    });

    latitudeGlobal = lat.toString();
    longitudeGlobal = lng.toString();
    box.put('last_latitude', lat);
    box.put('last_longitude', lng);
    if (address.isNotEmpty) {
      box.put('food_delivery_address', address);
    }

    context.read<FoodCubit>().loadNearbyRestaurants(
      latitude: lat,
      longitude: lng,
      radiusKm: 30,
    );
  }

  void _showParcelDetailsDialog(String maxWeight) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: ParcelDetailsScreen(maxWeight: maxWeight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (v, e) async => dialogExit(context),
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        drawer: const MyDrawer(),
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(_isFoodTab ? 105 : 170),
          child: Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _AnimatedTopChrome(
                    visible: !_isFoodTab,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        _buildLocationInput(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          height: double.maxFinite,
          width: double.maxFinite,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 245, 237, 213),
                Color.fromARGB(255, 255, 247, 223),
                Color.fromARGB(255, 248, 242, 226),
                Color.fromARGB(255, 254, 238, 196),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SvgPicture.asset("assets/images/home_group.svg"),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _AnimatedHomeBanner(visible: !_isFoodTab),
                    _buildTabBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.03),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            key: ValueKey<int>(_selectedTab),
                            children: [
                              _buildTabContent(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          BlocBuilder<MyImageCubit, dynamic>(
            builder: (context, state) {
              return InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: myImage.isEmpty
                    ? Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.profile_circled,
                          size: 40,
                          color: themeColor,
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: themeColor, width: 2),
                        ),
                        child: ClipOval(
                          child: myNetworkImage(
                            context.read<MyImageCubit>().state,
                          ),
                        ),
                      ),
              );
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<NameCubit, dynamic>(
                  builder: (context, state) {
                    return RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Hi, ".translate(context),
                            style: heading2Grey1(
                              context,
                            ).copyWith(fontSize: 18, color: Colors.grey[700]),
                          ),
                          TextSpan(
                            text: " ${context.read<NameCubit>().state}",
                            style: heading2Grey1(context).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: blackColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  "Where do you want to go today?".translate(context),
                  style: heading3Grey1(
                    context,
                  ).copyWith(color: grey2, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput() {
    return BlocBuilder<UpdateCurrentAddressCubit, UpdateCurrentAddressState>(
      builder: (context, state) {
        if (state is UpdateCurrentAddresSuccess) {
          _currentAddress = state.currentAddress ?? '';
          context.read<BookRideRealTimeDataBaseCubit>().updatePickupAddress(
            pickupAddress: _currentAddress,
          );
          context.read<BookRideRealTimeDataBaseCubit>().updatePickupLatAndLng(
            pickupAddressLatitude: state.lat.toString(),
            pickupAddressLongitude: state.lng.toString(),
          );
          context.read<UpdateCurrentAddressCubit>().removeAddress();

          pickupLocation = _currentAddress;
          pickupLat = state.lat;
          pickupLng = state.lng;
          if (state.lat != null && state.lng != null) {
            _selectedLocation.value = LatLng(state.lat!, state.lng!);
            latitudeGlobal = state.lat.toString();
            longitudeGlobal = state.lng.toString();
            box.put('last_latitude', state.lat);
            box.put('last_longitude', state.lng);
            if (_foodDeliveryAddress.isEmpty && _currentAddress.isNotEmpty) {
              _foodDeliveryAddress = _currentAddress;
              box.put('food_delivery_address', _currentAddress);
            }
          }
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.menu_outlined, color: themeColor, size: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    context
                        .read<VehicleDataUpdateCubit>()
                        .updateVehicleTypeSelectedId(1);
                    context
                            .read<SelectedAddressCubit>()
                            .pickupAddressController
                            .text =
                        _currentAddress;
                    context.read<GetSuggestionAddressCubit>().getSuggestions(
                      "",
                    );

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            UserSearchLocation(currentAddress: _currentAddress),
                      ),
                    );
                    _loadRecentDropLocations();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: themeColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentAddress.isEmpty
                                    ? "Fetching location...".translate(context)
                                    : _currentAddress.length > 40
                                    ? "${_currentAddress.substring(0, 40)}..."
                                    : _currentAddress,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: Colors.grey[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<ServiceType> serviceTypes = [];

  bool isLoadingServiceTypes = false;

  Widget _buildTabBar() {
    return BlocBuilder<GetServiceTypeDataCubit, GetServiceTypeDataState>(
      builder: (context, state) {
        bool isLoading = state is GetServiceTypeLoading;

        if (state is GetServiceTypeSuccess) {
          serviceTypes = state.itemTypes;

          if (serviceTypes.isNotEmpty && _selectedTab == 0) {
            context.read<GetVehicleDataCubit>().getItemTypesByService(
              serviceTypes[0].id.toString(),
            );
          }
          context.read<GetServiceTypeDataCubit>().resetState();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? Row(
                    children: [
                      Expanded(child: ShimmerLoader()),
                      const SizedBox(width: 10),
                      Expanded(child: ShimmerLoader()),
                    ],
                  )
                : serviceTypes.isEmpty
                ? Center(child: Text("No Services".translate(context)))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...List.generate(serviceTypes.length, (index) {
                          final item = serviceTypes[index];
                          final isSelected = _selectedTab == index;

                          return SizedBox(
                            width: 104,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap: () {
                                if (_selectedTab == index) return;
                                setState(() {
                                  _selectedTab = index;
                                });

                                context
                                    .read<GetVehicleDataCubit>()
                                    .getItemTypesByService(item.id.toString());
                                context.read<ServiceTypeId>().update(
                                  item.id.toString(),
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? themeColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  item.name ?? "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? whiteColor : grey2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        SizedBox(
                          width: 104,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () {
                              final foodTabIndex = serviceTypes.length;
                              if (_selectedTab == foodTabIndex) return;
                              setState(() {
                                _selectedTab = foodTabIndex;
                              });
                              _loadFoodRestaurantsForCurrentLocation();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: _selectedTab == serviceTypes.length
                                    ? themeColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "Food".translate(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTab == serviceTypes.length
                                      ? whiteColor
                                      : grey2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent() {
    if (_selectedTab == serviceTypes.length && serviceTypes.isNotEmpty) {
      return _buildFoodContent();
    }
    switch (_selectedTab) {
      case 0:
        return _buildRideContent();
      case 1:
        return _buildParcelContent();
      default:
        return _buildRideContent();
    }
  }

  Widget _buildFoodContent() {
    return BlocConsumer<FoodCubit, FoodState>(
      listener: (context, state) {
        if (state is FoodNearbyRestaurantsLoaded) {
          _cachedFoodRestaurants = state.restaurants;
        }
      },
      builder: (context, state) {
        final restaurants = state is FoodNearbyRestaurantsLoaded
            ? state.restaurants
            : _cachedFoodRestaurants;
        final isLoading = state is FoodLoading && restaurants.isEmpty;
        final filteredRestaurants = _filteredFoodRestaurants(restaurants);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildFoodHero(),
              const SizedBox(height: 16),
              _buildFoodSearch(),
              const SizedBox(height: 16),
              _buildFoodCategoryRail(),
              const SizedBox(height: 18),
              if (isLoading)
                _buildFoodLoadingCards()
              else if (state is FoodFailure && restaurants.isEmpty)
                _buildFoodEmptyState(
                  icon: Icons.wifi_tethering_error_rounded,
                  title: 'Could not load restaurants'.translate(context),
                  message: state.message,
                  actionLabel: 'Try again'.translate(context),
                  onAction: _loadFoodRestaurantsForCurrentLocation,
                )
              else if (restaurants.isEmpty)
                _buildFoodEmptyState(
                  icon: Icons.storefront_rounded,
                  title: 'No nearby restaurants'.translate(context),
                  message: 'Try refreshing or changing your location.'
                      .translate(context),
                  actionLabel: 'Refresh'.translate(context),
                  onAction: _loadFoodRestaurantsForCurrentLocation,
                )
              else
                _buildFoodMarketplace(filteredRestaurants, restaurants),
            ],
          ),
        );
      },
    );
  }

  List<FoodRestaurant> _filteredFoodRestaurants(
    List<FoodRestaurant> restaurants,
  ) {
    final query = _foodSearchQuery.trim().toLowerCase();
    final category = _foodCategories[_selectedFoodCategory].keyword;

    return restaurants.where((restaurant) {
      final searchable = [
        restaurant.name,
        ...restaurant.categories.map((category) => category.name),
        ...restaurant.categories
            .expand((category) => category.items)
            .map((item) => item.name),
      ].join(' ').toLowerCase();
      final matchesSearch = query.isEmpty || searchable.contains(query);
      final matchesCategory = category.isEmpty || searchable.contains(category);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildFoodHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF7A1A),
            themeColor,
            const Color(0xFFFFC247),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: .26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: .13),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Fast food delivery'.translate(context),
                      style: regular2(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Cravings delivered\nto your door'.translate(context),
                style: heading1(context).copyWith(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browse restaurants, compare ratings, and order in minutes.'
                    .translate(context),
                style: regular2(context).copyWith(
                  color: Colors.white.withValues(alpha: .92),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _selectFoodLocationFromMap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (_foodDeliveryAddress.isNotEmpty
                                    ? _foodDeliveryAddress
                                    : (_currentAddress.isNotEmpty
                                          ? _currentAddress
                                          : 'Set delivery location'))
                                .translate(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: regular2(context).copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Change'.translate(context),
                          style: regular2(context).copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _foodHeroButton(
                    label: 'All restaurants'.translate(context),
                    icon: Icons.storefront_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FoodHomeScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _foodHeroButton(
                    label: 'Orders'.translate(context),
                    icon: Icons.receipt_long_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FoodOrdersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _foodHeroButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: themeColor, size: 18),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: regular2(context).copyWith(
                      color: blackColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _foodSearchController,
        onChanged: (value) => setState(() => _foodSearchQuery = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search biryani, pizza, burger...'.translate(context),
          hintStyle: regular2(context).copyWith(color: grey2, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: themeColor.withValues(alpha: .8),
          ),
          suffixIcon: _buildFoodSearchActions(),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSearchActions() {
    return SizedBox(
      width: _foodSearchQuery.isEmpty ? 96 : 128,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_foodSearchQuery.isNotEmpty)
            IconButton(
              tooltip: 'Clear'.translate(context),
              onPressed: () {
                _foodSearchController.clear();
                setState(() => _foodSearchQuery = '');
              },
              icon: Icon(Icons.close_rounded, color: grey2, size: 20),
            ),
          IconButton(
            tooltip: 'Use current location'.translate(context),
            onPressed: _loadFoodRestaurantsForCurrentLocation,
            icon: Icon(Icons.my_location_rounded, color: themeColor, size: 20),
          ),
          IconButton(
            tooltip: 'Select from map'.translate(context),
            onPressed: _selectFoodLocationFromMap,
            icon: Icon(Icons.map_rounded, color: grey2, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCategoryRail() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _foodCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = _foodCategories[index];
          final isSelected = _selectedFoodCategory == index;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _selectedFoodCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 78,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? themeColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? themeColor
                      : Colors.black.withValues(alpha: .06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? themeColor : Colors.black).withValues(
                      alpha: isSelected ? .18 : .05,
                    ),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: isSelected ? Colors.white : themeColor,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.title.translate(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: regular2(context).copyWith(
                      color: isSelected ? Colors.white : blackColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodMarketplace(
    List<FoodRestaurant> filteredRestaurants,
    List<FoodRestaurant> allRestaurants,
  ) {
    if (filteredRestaurants.isEmpty) {
      return _buildFoodEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No match found'.translate(context),
        message: 'Try another keyword or category.'.translate(context),
        actionLabel: 'Clear filters'.translate(context),
        onAction: () {
          _foodSearchController.clear();
          setState(() {
            _foodSearchQuery = '';
            _selectedFoodCategory = 0;
          });
        },
      );
    }

    final featured = filteredRestaurants.take(5).toList();
    final popularItems = _foodItemPreviews(filteredRestaurants);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _foodSectionHeader(
          title: 'Featured near you'.translate(context),
          subtitle:
              '${allRestaurants.length} ${'restaurants available'.translate(context)}',
          action: 'View all'.translate(context),
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FoodHomeScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              return _buildFeaturedFoodCard(featured[index]);
            },
          ),
        ),
        if (popularItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          _foodSectionHeader(
            title: 'Popular items'.translate(context),
            subtitle: 'Tap an item to open its restaurant'.translate(context),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: popularItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                return _buildFoodItemPreviewCard(popularItems[index]);
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        _foodSectionHeader(
          title: 'Restaurants for you'.translate(context),
          subtitle: 'Fresh meals, quick checkout'.translate(context),
        ),
        const SizedBox(height: 12),
        ...filteredRestaurants.take(8).map((restaurant) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCompactFoodRestaurantCard(restaurant),
          );
        }),
      ],
    );
  }

  List<_FoodItemPreview> _foodItemPreviews(List<FoodRestaurant> restaurants) {
    final previews = <_FoodItemPreview>[];
    for (final restaurant in restaurants) {
      for (final category in restaurant.categories) {
        for (final item in category.items) {
          previews.add(
            _FoodItemPreview(
              restaurant: restaurant,
              categoryName: category.name,
              item: item,
            ),
          );
          if (previews.length >= 12) return previews;
        }
      }
    }
    return previews;
  }

  Widget _foodSectionHeader({
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: heading2Grey1(
                  context,
                ).copyWith(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: regular2(context).copyWith(
                  color: grey2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (action != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: regular2(
                context,
              ).copyWith(color: themeColor, fontWeight: FontWeight.w900),
            ),
          ),
      ],
    );
  }

  Widget _buildFoodItemPreviewCard(_FoodItemPreview preview) {
    final imageUrl = _resolveFoodImage(preview.item.image);

    return SizedBox(
      width: 166,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openFoodRestaurant(preview.restaurant),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: SizedBox(
                    height: 94,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? _foodImagePlaceholder()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _foodImagePlaceholder(),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: heading3(context).copyWith(
                          color: blackColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preview.restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: regular2(context).copyWith(
                          color: grey2,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '\$${preview.item.basePrice.toStringAsFixed(0)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: heading3(context).copyWith(
                                color: themeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              preview.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: regular2(context).copyWith(
                                color: themeColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedFoodCard(FoodRestaurant restaurant) {
    final imageUrl = _resolveFoodImage(
      restaurant.coverImage ?? restaurant.logoImage,
    );
    final availabilityLabel = restaurant.isAcceptingOrders ? 'Open' : 'Closed';

    return SizedBox(
      width: 235,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openFoodRestaurant(restaurant),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .07),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SizedBox(
                    height: 122,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? _foodImagePlaceholder()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _foodImagePlaceholder(),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: heading3(context).copyWith(
                          color: blackColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _foodMetaChip(
                            restaurant.isAcceptingOrders
                                ? Icons.storefront_rounded
                                : Icons.lock_clock_rounded,
                            availabilityLabel,
                            restaurant.isAcceptingOrders
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 7),
                          _foodMetaChip(
                            Icons.star_rounded,
                            (restaurant.rating ?? 4.5).toStringAsFixed(1),
                            const Color(0xFFFFB000),
                          ),
                          const SizedBox(width: 7),
                          _foodMetaChip(
                            Icons.timer_rounded,
                            '20-35 min',
                            themeColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFoodRestaurantCard(FoodRestaurant restaurant) {
    final imageUrl = _resolveFoodImage(
      restaurant.logoImage ?? restaurant.coverImage,
    );
    final availabilityLabel = restaurant.isAcceptingOrders ? 'Open' : 'Closed';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openFoodRestaurant(restaurant),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .055),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: imageUrl.isEmpty
                      ? _foodImagePlaceholder()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _foodImagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: heading3(context).copyWith(
                        color: blackColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Free browsing - Cash on delivery'.translate(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: regular2(context).copyWith(
                        color: grey2,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _foodMetaChip(
                          Icons.star_rounded,
                          (restaurant.rating ?? 4.5).toStringAsFixed(1),
                          const Color(0xFFFFB000),
                        ),
                        const SizedBox(width: 7),
                        _foodMetaChip(
                          restaurant.isAcceptingOrders
                              ? Icons.storefront_rounded
                              : Icons.lock_clock_rounded,
                          availabilityLabel,
                          restaurant.isAcceptingOrders
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: grey2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodMetaChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: regular2(context).copyWith(
              color: blackColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLoadingCards() {
    return Column(
      children: List.generate(4, (index) {
        return Container(
          height: index == 0 ? 150 : 92,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .72),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFoodEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: themeColor),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: heading3(
              context,
            ).copyWith(color: blackColor, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: regular2(context).copyWith(color: grey2, fontSize: 12),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _foodImagePlaceholder() {
    return Container(
      color: const Color(0xFFFFF1D7),
      child: Icon(Icons.restaurant_rounded, color: themeColor, size: 34),
    );
  }

  String _resolveFoodImage(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final normalized = value.startsWith('/') ? value : '/$value';
    return '${Config.baseDomain}$normalized';
  }

  void _openFoodRestaurant(FoodRestaurant restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FoodMenuScreen(restaurant: restaurant)),
    );
  }

  Widget _buildRideContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              if (recentDropLocations.isNotEmpty) _buildRecentSearchesSection(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    color: themeColor,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Choose Your Ride".translate(context),
                      style: heading2Grey1(
                        context,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              BlocBuilder<GetVehicleDataCubit, GetVehicleDataState>(
                builder: (context, state) {
                  List<ItemTypes> itemList = [];
                  if (state is GetItemTypeSuccess &&
                      state.itemTypes.isNotEmpty) {
                    itemList = state.itemTypes;
                    context
                        .read<SetVehicleCategoryCubit>()
                        .updateSetVehicleCategoryList(itemList);
                  }
                  bool isLoading = state is GetVehicleLoading;
                  return _buildVehicleGrid(itemList, isLoading);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParcelContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildVehicleSelectionSection(),
            const SizedBox(height: 30),
            _buildDeliveryNotes(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: Colors.green.shade600, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "Delivery Notes".translate(context),
                style: heading3Grey1(context).copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDeliveryNoteItem("Ensure proper packaging"),
          _buildDeliveryNoteItem("Add clear delivery instructions"),
          _buildDeliveryNoteItem("Include receiver contact info"),
        ],
      ),
    );
  }

  Widget _buildDeliveryNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.translate(context),
              style: regular2(context).copyWith(
                fontSize: 12,
                height: 1.45,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.local_shipping_rounded, color: themeColor, size: 21),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Select Delivery Vehicle".translate(context),
                style: heading2Grey1(
                  context,
                ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "Choose the right vehicle for your parcel size".translate(context),
          style: regular2(
            context,
          ).copyWith(color: Colors.grey[600], fontSize: 11),
        ),
        const SizedBox(height: 12),
        BlocBuilder<GetVehicleDataCubit, GetVehicleDataState>(
          builder: (context, state) {
            List<ItemTypes> itemList = [];
            if (state is GetItemTypeSuccess && state.itemTypes.isNotEmpty) {
              itemList = state.itemTypes;
              context
                  .read<SetVehicleCategoryCubit>()
                  .updateSetVehicleCategoryList(itemList);
            }
            bool isLoading = state is GetVehicleLoading;
            return _buildVehicleGrid(itemList, isLoading);
          },
        ),
      ],
    );
  }

  Widget _buildRecentSearchesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history, color: themeColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Recent".translate(context),
                    style: heading3Grey1(
                      context,
                    ).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (recentDropLocations.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    box.delete('recent_drop_locations');
                    _loadRecentDropLocations();
                  },
                  child: Text(
                    "Clear".translate(context),
                    style: regular2(context).copyWith(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (recentDropLocations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "No recent searches".translate(context),
                  style: regular2(
                    context,
                  ).copyWith(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            )
          else
            Column(
              children: recentDropLocations.take(2).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _handleRecentSearchTap(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: themeColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.location_on, size: 16, color: themeColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['address'] ?? "",
                              style: regular(context).copyWith(
                                fontSize: 12.5,
                                color: notifires.getGrey1whiteColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _handleRecentSearchTap(Map<String, String> item) {
    if (_currentAddress.isEmpty) {
      showAlert = false;
      startLiveLocationTracking();
      setState(() {});
      return;
    }

    context.read<SelectedAddressCubit>().dropOffAddressController.text =
        item['address'] ?? "";
    context.read<BookRideRealTimeDataBaseCubit>().updateDropOffLatAndLng(
      dropoffAddressLatitude: item['lat'] ?? "",
      dropoffAddressLongitude: item['lng'] ?? "",
    );

    final bookRide = context.read<BookRideRealTimeDataBaseCubit>();
    bookRide.updatePickupAddress(pickupAddress: _currentAddress);
    bookRide.updateDropOffAddress(dropoffAddress: item['address'] ?? "");
    box.delete("current_parcel_data");

    if (bookRide.state.pickupAddress.isNotEmpty &&
        bookRide.state.dropoffAddress.isNotEmpty &&
        bookRide.state.pickupAddressLatitude.isNotEmpty &&
        bookRide.state.pickupAddressLongitude.isNotEmpty &&
        bookRide.state.dropoffAddressLatitude.isNotEmpty &&
        bookRide.state.dropoffAddressLongitude.isNotEmpty) {
      goTo(const LoadingNearbySearchScreen());
    }
  }

  Widget _buildVehicleGrid(List<ItemTypes> items, bool isLoading) {
    if (items.isEmpty && !isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.car_repair, color: Colors.grey[300], size: 60),
              const SizedBox(height: 12),
              Text(
                "No vehicles available".translate(context),
                style: regular2(context).copyWith(color: Colors.grey[400]),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  context.read<GetServiceTypeDataCubit>().getServiceType();
                  setState(() {
                    _selectedTab = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Retry".translate(context),
                    style: regular2(context).copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: isLoading ? 8 : items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        if (isLoading) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        final item = items[index];
        return _buildVehicleCard(item);
      },
    );
  }

  Widget _buildVehicleCard(ItemTypes item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (_selectedTab == 0) {
            context.read<VehicleDataUpdateCubit>().updateVehicleTypeSelectedId(
              item.id,
            );
            context.read<SelectedAddressCubit>().pickupAddressController.text =
                _currentAddress;
            context.read<GetSuggestionAddressCubit>().getSuggestions("");
            box.delete('current_parcel_data');

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UserSearchLocation(currentAddress: _currentAddress),
              ),
            );
            _loadRecentDropLocations();
          } else {
            context.read<SelectedAddressCubit>().pickupAddressController.text =
                _currentAddress;
            context.read<GetSuggestionAddressCubit>().getSuggestions("");
            context.read<VehicleDataUpdateCubit>().updateVehicleTypeSelectedId(
              item.id,
            );
            _showParcelDetailsDialog(item.maxWeight ?? "");
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.network(
                    item.image ?? "",
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.directions_car, color: themeColor, size: 30),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name ?? "",
                style: heading3(context).copyWith(
                  color: blackColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void getCurrency(BuildContext context) {
  context.read<GeneralCubit>().fetchGeneralSetting(context);
}

class _FoodCategoryShortcut {
  const _FoodCategoryShortcut(this.title, this.icon, this.keyword);

  final String title;
  final IconData icon;
  final String keyword;
}

class _FoodItemPreview {
  const _FoodItemPreview({
    required this.restaurant,
    required this.categoryName,
    required this.item,
  });

  final FoodRestaurant restaurant;
  final String categoryName;
  final FoodMenuItem item;
}

class _AnimatedTopChrome extends StatelessWidget {
  const _AnimatedTopChrome({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          ),
        );
      },
      child: visible
          ? KeyedSubtree(
              key: const ValueKey('home-top-chrome-visible'),
              child: child,
            )
          : const SizedBox(
              key: ValueKey('home-top-chrome-hidden'),
              height: 0,
              width: double.infinity,
            ),
    );
  }
}

class _AnimatedHomeBanner extends StatelessWidget {
  const _AnimatedHomeBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.06),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          ),
        );
      },
      child: visible
          ? const Column(
              key: ValueKey('home-banner-visible'),
              children: [AutoImageSlider(), SizedBox(height: 15)],
            )
          : const SizedBox(
              key: ValueKey('home-banner-hidden'),
              height: 0,
              width: double.infinity,
            ),
    );
  }
}

class AutoImageSlider extends StatefulWidget {
  const AutoImageSlider({super.key});

  @override
  State<AutoImageSlider> createState() => _AutoImageSliderState();
}

class _AutoImageSliderState extends State<AutoImageSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  void startAutoSlide(int length) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SlidersCubit, SlidersState>(
      builder: (context, state) {
        if (state is SlidersLoading) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 115,
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          );
        }

        if (state is SlidersSuccess) {
          List<SliderData> sliders = state.sliderResponse.data ?? [];

          if (sliders.isEmpty) {
            return const SizedBox.shrink();
          }

          startAutoSlide(sliders.length);

          return SizedBox(
            height: 115,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: sliders.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slider = sliders[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: GestureDetector(
                          onTap: () async {
                            final url = slider.url;
                            if (url != null &&
                                await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {}
                          },
                          child: Image.network(
                            slider.image ?? '',
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[300]),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.image)),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Dots Indicator
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      sliders.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentIndex == index ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SlidersFailed) {
          return const SizedBox();
        }

        return const SizedBox.shrink();
      },
    );
  }
}
