import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/location/user_current_location_cubit.dart';

import '../../widgets/menu_popup_widget.dart';
import 'loading_nearby_search_screen.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserSearchLocation extends StatefulWidget {
  final String? currentAddress;
  const UserSearchLocation({super.key, this.currentAddress});

  @override
  State<UserSearchLocation> createState() => _UserSearchLocationState();
}

class _UserSearchLocationState extends State<UserSearchLocation> {
  final focusNode1 = FocusNode();
  final focusNode2 = FocusNode();
  bool isPickUp = true;
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    final cubit = context.read<SelectedAddressCubit>();
    cubit.pickupAddressController.text = widget.currentAddress ?? "";
    cubit.dropOffAddressController.text = "";
    // box.delete("recent_drop_locations");
    _loadRecentDropLocations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GetSuggestionAddressCubit>().getSuggestions("");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBars(
        title: "",
        backgroundColor: notifires.getbgcolor,
        titleColor: notifires.getGrey1whiteColor,
      ),
      backgroundColor: whiteColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<GetCordinatesCubit, GetCordinatesState>(
            listener: _handleCoordinateUpdate,
          )
        ],
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationFields(),
              Divider(color: grey5),
              _buildSuggestionsList(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCoordinateUpdate(BuildContext context, GetCordinatesState state) {
    final addressCubit = context.read<SelectedAddressCubit>();
    final bookRideCubit = context.read<BookRideRealTimeDataBaseCubit>();

    if (state is GetCordinatesSuccess) {
      final isPickup = addressCubit.state.isCheckedSelectedPickup;

      if (isPickup) {
        bookRideCubit.updatePickupLatAndLng(
          pickupAddressLatitude: state.lattiude.toString(),
          pickupAddressLongitude: state.longitude.toString(),
        );
        focusNode1.unfocus();
      } else {
        bookRideCubit.updateDropOffLatAndLng(
          dropoffAddressLatitude: state.lattiude.toString(),
          dropoffAddressLongitude: state.longitude.toString(),
        );
        focusNode2.unfocus();
        _proceedToNearbyDrivers();
      }

      context.read<GetSuggestionAddressCubit>().removeAddress();
    }
  }

  Future<void> getCurrentLocationAndAddress() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();

        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          await Geolocator.openAppSettings(); // Prompt user to open settings
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      final lat = position.latitude;
      final lng = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks.first;

      String fullAddress = [
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.trim().isNotEmpty)
          place.subThoroughfare,
        if (place.thoroughfare != null && place.thoroughfare!.trim().isNotEmpty)
          place.thoroughfare,
        if (place.subLocality != null && place.subLocality!.trim().isNotEmpty)
          place.subLocality,
        if (place.locality != null && place.locality!.trim().isNotEmpty)
          place.locality,
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.trim().isNotEmpty)
          place.subAdministrativeArea,
        if (place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea,
        if (place.postalCode != null && place.postalCode!.trim().isNotEmpty)
          place.postalCode,
        if (place.country != null && place.country!.trim().isNotEmpty)
          place.country,
      ].join(", ");

      // ignore: use_build_context_synchronously
      final selectedCubit = context.read<SelectedAddressCubit>();
      // ignore: use_build_context_synchronously
      final bookRide = context.read<BookRideRealTimeDataBaseCubit>();

      selectedCubit.pickupAddressController.text = fullAddress;
      bookRide.updatePickupLatAndLng(
        pickupAddressLatitude: lat.toString(),
        pickupAddressLongitude: lng.toString(),
      );
      bookRide.updatePickupAddress(pickupAddress: fullAddress);

      setState(() {});
    } catch (e) {
      // showErrorToastMessage("Unable to fetch location: $e");
    }
  }

  List<Map<String, String>> recentDropLocations = [];

  void _loadRecentDropLocations() {
    final storedList = box.get('recent_drop_locations', defaultValue: []);
    if (storedList is List) {
      recentDropLocations =
          storedList.map((e) => Map<String, String>.from(e)).toList();
    }
    setState(() {});
  }

  void _addRecentDropLocation(String address, String lat, String lng) {
    // Duplicate remove
    recentDropLocations.removeWhere((item) => item['address'] == address);
    // Add at start
    recentDropLocations.insert(0, {
      "address": address,
      "lat": lat,
      "lng": lng,
    });

    // Max 10 limit
    if (recentDropLocations.length > 5) {
      recentDropLocations = recentDropLocations.sublist(0, 5);
    }

    // Save in Hive
    box.put('recent_drop_locations', recentDropLocations);
  }

  Widget _buildLocationFields() {
    final cubit = context.read<SelectedAddressCubit>();
    bool dropTextFilled = cubit.dropOffAddressController.text.isNotEmpty;

    Widget customTextField({
      required String label,
      required TextEditingController controller,
      required FocusNode focusNode,
      required IconData prefixIcon,
      required Color iconColor,
      required String hint,
      required void Function()? onTap,
      required void Function(String)? onChanged,
      Widget? suffixIcon,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: heading3Grey1(context).copyWith(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              onTap: onTap,
              onChanged: onChanged,
              style: heading3Grey1(context).copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: regular2(context),
                prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: BlocBuilder<SelectedAddressCubit, SelectedAddressState>(
          builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ðŸš— Pickup Location
            customTextField(
              label: "Pickup Location".translate(context),
              controller: cubit.pickupAddressController,
              focusNode: focusNode1,
              prefixIcon: Icons.radio_button_checked,
              iconColor: Colors.green.shade700,
              hint: "Enter pickup location".translate(context),
              onTap: () {
                setState(() => isPickUp = true);
                cubit.updateIsSelectePickupdAddress(
                    isCheckedSelectedPickup: true);
                cubit.updateIsSelectedDropOffAddress(
                    isCheckedSelectedDropOff: false);
                context.read<GetSuggestionAddressCubit>().removeAddress();
              },
              onChanged: (query) {
                setState(() {});

                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () {
                  if (query.length >= 2) {
                    context.read<GetSuggestionAddressCubit>().getSuggestions(query);

                  }
                });

              },
              suffixIcon: IconButton(
                icon: Icon(Icons.my_location_rounded, color: themeColor),
                onPressed: getCurrentLocationAndAddress,
              ),
            ),

            const SizedBox(height: 20),

            // ðŸ Drop Location
            customTextField(
              label: "Drop Location".translate(context),
              controller: cubit.dropOffAddressController,
              focusNode: focusNode2,
              prefixIcon: Icons.location_on_outlined,
              iconColor: Colors.red.shade600,
              hint: "Enter drop location".translate(context),
              onTap: () {
                setState(() => isPickUp = false);
                cubit.updateIsSelectePickupdAddress(
                    isCheckedSelectedPickup: false);
                cubit.updateIsSelectedDropOffAddress(
                    isCheckedSelectedDropOff: true);
                context.read<GetSuggestionAddressCubit>().removeAddress();
              },
              onChanged: (query) {
                setState(() {});

                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () {
                  if (query.length >= 2) {
                    context.read<GetSuggestionAddressCubit>().getSuggestions(query);
                    dropTextFilled =
                        cubit.dropOffAddressController.text.isNotEmpty;
                  }
                });

              },
              suffixIcon: dropTextFilled
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        cubit.dropOffAddressController.clear();
                        setState(() {});
                        context
                            .read<GetSuggestionAddressCubit>()
                            .removeAddress();
                      },
                    )
                  : null,
            ),

            const SizedBox(height: 24),

            // ðŸŒ Optional: Nearby locations or manual selector
            selectWithLocation(context: context),
          ],
        );
      }),
    );
  }

  bool showButton = true;

  Widget _buildSuggestionsList() {
    return BlocBuilder<GetSuggestionAddressCubit, GetSuggestionAddressState>(
      builder: (context, state) {
        final suggestions = (state is GetSuggestionAddressSuccess)
            ? state.suggestions ?? []
            : [];

        if (suggestions.isEmpty) {
          return _buildNearbyDriverButton();
        }

        return Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            itemBuilder: (_, index) {
              final address = suggestions[index];
              return ListTile(
                leading: ClipOval(
                  child: Container(
                      height: 40,
                      width: 40,
                      color: themeColor,
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.white,
                        size: 20,
                      )),
                ),
                title: RichText(
                  text: TextSpan(
                    children: _formatSuggestion(address),
                    style: regular(context)
                        .copyWith(color: notifires.getGrey1whiteColor),
                  ),
                ),
                onTap: () {
                  showButton = false;
                  final selectedCubit = context.read<SelectedAddressCubit>();
                  final isPickup = selectedCubit.state.isCheckedSelectedPickup;

                  if (isPickup) {
                    selectedCubit.pickupAddressController.text = address;
                  } else {
                    selectedCubit.dropOffAddressController.text = address;
                  }

                  context.read<GetSuggestionAddressCubit>().removeAddress();
                  context
                      .read<GetCordinatesCubit>()
                      .getCoordinates(address: address);

                  // Refresh UI
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }

  bool isClicked = false;
  Widget _buildNearbyDriverButton() {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: ListView(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (context
                    .read<SelectedAddressCubit>()
                    .dropOffAddressController
                    .text
                    .isEmpty &&
                recentDropLocations.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Recent Drop Searches".translate(context),
                  style: heading3Grey1(context).copyWith(fontSize: 14),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentDropLocations.length,
                itemBuilder: (context, index) {
                  final item = recentDropLocations[index];
                  return ListTile(
                    leading: Icon(Icons.history, color: themeColor),
                    title: Text(
                      item['address'] ?? "",
                      style: regular(context)
                          .copyWith(color: notifires.getGrey1whiteColor),
                    ),
                    onTap: () {
                      showButton = false;
                      context
                          .read<SelectedAddressCubit>()
                          .dropOffAddressController
                          .text = item['address'] ?? "";
                      context
                          .read<BookRideRealTimeDataBaseCubit>()
                          .updateDropOffLatAndLng(
                            dropoffAddressLatitude: item['lat'] ?? "",
                            dropoffAddressLongitude: item['lng'] ?? "",
                          );

                      final selected = context.read<SelectedAddressCubit>();
                      final bookRide =
                          context.read<BookRideRealTimeDataBaseCubit>();

                      if (selected.pickupAddressController.text.isEmpty ||
                          selected.dropOffAddressController.text.isEmpty) {
                        showErrorToastMessage(
                            "Please select both addresses".translate(context));
                        return;
                      }

                      bookRide.updatePickupAddress(
                        pickupAddress: selected.pickupAddressController.text,
                      );
                      bookRide.updateDropOffAddress(
                        dropoffAddress: selected.dropOffAddressController.text,
                      );

                      if (bookRide.state.pickupAddress.isNotEmpty &&
                          bookRide.state.dropoffAddress.isNotEmpty &&
                          bookRide.state.pickupAddressLatitude.isNotEmpty &&
                          bookRide.state.pickupAddressLongitude.isNotEmpty &&
                          bookRide.state.dropoffAddressLatitude.isNotEmpty &&
                          bookRide.state.dropoffAddressLongitude.isNotEmpty) {
                        goTo(const LoadingNearbySearchScreen());

                        showButton = true;
                      }

                      setState(() {});
                    },
                  );
                },
              ),
            ],
            if (context
                    .read<SelectedAddressCubit>()
                    .dropOffAddressController
                    .text
                    .isNotEmpty &&
                showButton)
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomsButtons(
                  text: "Find nearby drivers".translate(context),
                  textColor: whiteColor,
                  backgroundColor: themeColor,
                  onPressed: _proceedToNearbyDrivers,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _proceedToNearbyDrivers() {
    final selected = context.read<SelectedAddressCubit>();
    final bookRide = context.read<BookRideRealTimeDataBaseCubit>();

    if (selected.pickupAddressController.text.isEmpty ||
        selected.dropOffAddressController.text.isEmpty) {
      showErrorToastMessage("Please select both addresses".translate(context));
      return;
    }

    bookRide.updatePickupAddress(
      pickupAddress: selected.pickupAddressController.text,
    );
    bookRide.updateDropOffAddress(
      dropoffAddress: selected.dropOffAddressController.text,
    );

    if (bookRide.state.pickupAddress.isNotEmpty &&
        bookRide.state.dropoffAddress.isNotEmpty &&
        bookRide.state.pickupAddressLatitude.isNotEmpty &&
        bookRide.state.pickupAddressLongitude.isNotEmpty &&
        bookRide.state.dropoffAddressLatitude.isNotEmpty &&
        bookRide.state.dropoffAddressLongitude.isNotEmpty) {
      _addRecentDropLocation(
        selected.dropOffAddressController.text,
        bookRide.state.dropoffAddressLatitude.toString(),
        bookRide.state.dropoffAddressLongitude.toString(),
      );
      showButton = true;
      goTo(const LoadingNearbySearchScreen());
      showButton = true;
      setState(() {});
    }
  }

  List<TextSpan> _formatSuggestion(String suggestion) {
    final parts = suggestion.split(',');
    return [
      TextSpan(
          text: parts.first.trim(),
          style: heading3Grey1(context).copyWith(fontSize: 15)),
      if (parts.length > 1)
        TextSpan(
          text: "\n${parts.sublist(1).join(',').trim()}",
          style: regular(context).copyWith(color: grey2),
        ),
    ];
  }
}



