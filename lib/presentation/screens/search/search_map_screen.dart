import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../../core/services/config.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/location/user_current_location_cubit.dart';

class SearchMapScreen extends StatefulWidget {
  final String? selectedAddressTitle;
  final bool? checkStatus;
  const SearchMapScreen(
      {super.key, this.selectedAddressTitle, this.checkStatus});
  @override
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen> {
  double selectedMapLat = 28.5865;
  double selectedMapLng = 77.3152;
  GoogleMapController? mapController;
  TextEditingController textEditingAddressSearchController =
      TextEditingController();
  FocusNode focusNode1 = FocusNode();
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      selectedMapLat = double.parse(context
          .read<BookRideRealTimeDataBaseCubit>()
          .state
          .pickupAddressLatitude);
      selectedMapLng = double.parse(context
          .read<BookRideRealTimeDataBaseCubit>()
          .state
          .pickupAddressLongitude);

      textEditingAddressSearchController.clear();
    });
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    if (mapController != null) {
      mapController!.dispose();
    }
    mapController = controller;
    if (selectedMapLat != 0 && selectedMapLng != 0) {
      mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(selectedMapLat, selectedMapLng)));
    }
  }

  void _zoomIn() {
    mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _moveToCurrentLocation({LatLng? currentLocation}) {
    selectedMapLat = currentLocation!.latitude;
    selectedMapLng = currentLocation.longitude;
    mapController?.animateCamera(CameraUpdate.newLatLng(currentLocation));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Timer? _debounce;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 55,
        elevation: 0,
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
            widget.checkStatus == true
                ? "Pickup Location".translate(context)
                : "Drop-off Location".translate(context),
            style: headingBlack(context)
                .copyWith(fontSize: 18, color: blackColor)),
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: notifires.getbgcolor,
                    border: Border.all(color: notifires.getGrey3whiteColor)),
                child: Icon(Icons.arrow_back,
                    size: 20, color: notifires.getwhiteblackColor)),
          ),
        ),
        bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 60),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 10, left: 20, right: 20),
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 60,
                    child: GooglePlaceAutoCompleteTextField(
                      containerVerticalPadding: 6,
                      focusNode: focusNode1,
                      containerHorizontalPadding: 0,
                      textStyle: regularBlack(context).copyWith(fontSize: 14),
                      textEditingController: textEditingAddressSearchController,
                      boxDecoration: BoxDecoration(
                        color: whiteColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: grey4),
                      ),
                      isLatLngRequired: true,
                      googleAPIKey: Config.googleKey,
                      countries: null,
                      inputDecoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: blackColor,
                          ),
                          hintStyle:
                              regular3(context).copyWith(color: blackColor),
                          hintText: "Search Address".translate(context),
                          border: InputBorder.none),
                      getPlaceDetailWithLatLng: (Prediction prediction) {
                        if (prediction.lat != null && prediction.lng != null) {
                          _moveToCurrentLocation(
                              currentLocation: LatLng(
                                  double.parse(prediction.lat!),
                                  double.parse(prediction.lng!)));
                        }
                      },
                      itemClick: (Prediction prediction) {},
                      itemBuilder: (context, index, Prediction prediction) {
                        return Container(
                          decoration: BoxDecoration(
                            color: notifires.getbgcolor,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: blackColor,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        prediction.description ?? "",
                                        style: regular2(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                              Divider(
                                color: blackColor,
                                thickness: 1,
                              ),
                              const SizedBox(
                                height: 5,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            )),
      ),
      body: Stack(
        children: [
          BlocBuilder<UpdateSearchMapAddressCubit, UpdateSearchMapAddressState>(
              builder: (context, state) {
            if (state is UpdateSearchMapAddresSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                textEditingAddressSearchController.text =
                    state.currentAddress.toString();
                context.read<UpdateSearchMapAddressCubit>().removeAddress();
              });
            }
            return GoogleMap(
              onMapCreated: _onMapCreated,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              zoomGesturesEnabled: true,
              compassEnabled: true,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (CameraPosition position) {
                selectedMapLat = position.target.latitude;
                selectedMapLng = position.target.longitude;
              },
              onCameraIdle: () {
                if (_debounce?.isActive ?? false) _debounce!.cancel();

                _debounce = Timer(const Duration(milliseconds: 700), () {
                  context.read<UpdateSearchMapAddressCubit>().removeAddress();
                  context
                      .read<UpdateSearchMapAddressCubit>()
                      .getAddressFromLatLng(
                          latitude: selectedMapLat, longitude: selectedMapLng);
                });
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(selectedMapLat, selectedMapLng),
                zoom: 14,
              ),
            );
          }),

          Positioned(
            top: 0,
            right: 0,
            bottom: 0, // Center vertically, offset by half icon height
            left: 0, // Center horizontally, offset by half icon width
            child: Transform.translate(
              offset: const Offset(0, -15),
              child: Center(
                child: Image.asset(
                  "assets/images/dropmarker.png",
                  height: 34,
                  width: 34,

                  alignment: Alignment
                      .bottomCenter, // Ensure pin's tip points to the location
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: zoomButton(
              icon: Icons.zoom_out,
              onPressed: () {
                _zoomOut();
              },
            ),
          ),

          // **Zoom In Button**
          Positioned(
            top: 90,
            right: 16,
            child: zoomButton(
              icon: Icons.zoom_in,
              onPressed: () {
                _zoomIn();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: whiteColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Quickly type your address or drop".translate(context),
              style: heading3Grey1(context),
            ),
            const SizedBox(height: 10),
            CustomsButtons(
              text: "Set Address",
              backgroundColor: themeColor,
              onPressed: () {
                if (textEditingAddressSearchController.text.isNotEmpty) {
                  if (widget.checkStatus == true) {
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsSelectePickupdAddress(
                            isCheckedSelectedPickup: true);
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsSelectedDropOffAddress(
                            isCheckedSelectedDropOff: false);
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsCrossIconSelectePickup(
                            icheckedCrossIconPickup: true);
                    context
                            .read<SelectedAddressCubit>()
                            .pickupAddressController
                            .text =
                        textEditingAddressSearchController.text.toString();
                    context.read<GetCordinatesCubit>().getCoordinates(
                        address:
                            textEditingAddressSearchController.text.toString());

                    Navigator.of(context).pop({
                      'address': textEditingAddressSearchController.text.toString(),
                      'lat': selectedMapLat,
                      'lng': selectedMapLng,
                      'isPickup': true,
                    });
                  } else {
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsSelectePickupdAddress(
                            isCheckedSelectedPickup: false);
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsSelectedDropOffAddress(
                            isCheckedSelectedDropOff: true);
                    context
                        .read<SelectedAddressCubit>()
                        .updateIsCrossIconSelectedDropOff(
                            ischeckedCrossIconDropOff: true);

                    context
                            .read<SelectedAddressCubit>()
                            .dropOffAddressController
                            .text =
                        textEditingAddressSearchController.text.toString();
                    context.read<GetCordinatesCubit>().getCoordinates(
                        address:
                            textEditingAddressSearchController.text.toString());

                    if (context
                            .read<SelectedAddressCubit>()
                            .dropOffAddressController
                            .text ==
                        context
                            .read<SelectedAddressCubit>()
                            .pickupAddressController
                            .text) {
                      showErrorToastMessage("Please select different address");
                      return;
                    }
                    Navigator.of(context).pop({
                      'address': textEditingAddressSearchController.text.toString(),
                      'lat': selectedMapLat,
                      'lng': selectedMapLng,
                      'isPickup': false,
                    });
                  }
                } else {
                  showErrorToastMessage(
                      "please selected the address".translate(context));
                }
              },
              textColor: whiteColor,
            ),
          ],
        ),
      ),
    );
  }
}


