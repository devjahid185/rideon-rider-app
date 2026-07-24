import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/screens/search/selection_vehicle_screen.dart';
import '../../../app/route_settings.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/location/get_item_price_cubit.dart';
import '../../cubits/location/get_nearby_drivers_cubit.dart';

class LoadingNearbySearchScreen extends StatefulWidget {
  const LoadingNearbySearchScreen({super.key});

  @override
  State<LoadingNearbySearchScreen> createState() => _LoadingNearbySearchScreenState();
}

class _LoadingNearbySearchScreenState extends State<LoadingNearbySearchScreen> {

  Set<Polyline> _polylines = {};
  String? _errorMessage;



  @override
  void initState() {
    super.initState();
    context.read<GetDistanceRouteCubit>().removeDistanceState();
    context.read<GetDistanceRouteCubit>().getDistanceAndFares(
      context: context,
      pickupLat: context.read<BookRideRealTimeDataBaseCubit>().state.pickupAddressLatitude,
      pickupLng: context.read<BookRideRealTimeDataBaseCubit>().state.pickupAddressLongitude,
      dropOffLat: context.read<BookRideRealTimeDataBaseCubit>().state.dropoffAddressLatitude,
      dropOffLng: context.read<BookRideRealTimeDataBaseCubit>().state.dropoffAddressLongitude,
    );
    _fetchAllDataWithSetState();
  }

  Future<void> _fetchAllDataWithSetState() async {
    try {
      final rideCubit = context.read<BookRideRealTimeDataBaseCubit>().state;

      // Parse coordinates safely
      final pickupLat = double.tryParse(rideCubit.pickupAddressLatitude);
      final pickupLng = double.tryParse(rideCubit.pickupAddressLongitude);
      final dropoffLat = double.tryParse(rideCubit.dropoffAddressLatitude);
      final dropoffLng = double.tryParse(rideCubit.dropoffAddressLongitude);

      // Validate coordinates
      if (pickupLat == null ||
          pickupLng == null ||
          dropoffLat == null ||
          dropoffLng == null ||
          pickupLat == 0.0 ||
          pickupLng == 0.0 ||
          dropoffLat == 0.0 ||
          dropoffLng == 0.0) {
        setState(() {
          _errorMessage = 'Invalid coordinates provided';
        });
        return;
      }

      // Fetch polyline
      if (_polylines.isEmpty) {
        context.read<GetPolylineCubit>().getPolyline(
          isPickupRoute: false,
          sourcelat: pickupLat,
          sourcelng: pickupLng,
          destinationlat: dropoffLat,
          destinationlng: dropoffLng,
        );
      }



      bool polylineFetched = false;

      bool distanceFetched = false;

      List<Map<String, dynamic>> vehicleFares = [];
      double? distance;
      int timeoutCounter = 0;
      const int timeoutMs = 20000;

      final polylineSubscription = context.read<GetPolylineCubit>().stream.listen((state) {
        if (state is GetPolylineUpdated && state.polylines != null) {
          _polylines = state.polylines!;
          polylineFetched = true;

        } else if (state is GetPolylineUpdatedError) {
          _errorMessage = "Unable to find the specified route.";
          setState(() {});

        }
      });


      final distanceSubscription = context.read<GetDistanceRouteCubit>().stream.listen((state) {
        if (state.vehicleFares.isNotEmpty && state.distance != null) {
          vehicleFares = state.vehicleFares;
          distance = state.distance;
          distanceFetched = true;

        }
      });


      await Future.doWhile(() async {
        if (_errorMessage != null || (polylineFetched && distanceFetched)) {
          return false; // Exit loop
        }
        await Future.delayed(const Duration(milliseconds: 100));
        timeoutCounter += 100;
        if (timeoutCounter >= timeoutMs) {
          _errorMessage = 'Request timed out';
          setState(() {});

          return false;
        }
        return true;
      });

      await polylineSubscription.cancel();

      await distanceSubscription.cancel();

      if (_errorMessage != null) {
        return;
      }


     if (distance != null) {
  // Too short distance (â‰¤ 0.1 km)
  if (distance! <= 0.1) {
    setState(() {
      _errorMessage =
          'Distance is too short (â‰¤ 0.1 km). Please select a farther drop-off location.';
    });
    return;
  }

 
}


      if (mounted) {
        goToWithReplacement(SelectionVehicleScreen(

          polylines: _polylines,
          fareList: vehicleFares, // Pass vehicle fares to next screen
        ));
      }
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      setState(() {});

    }
  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [

            Positioned(
              top: 0,left: 0,right: 0,
                bottom: MediaQuery.sizeOf(context).height/2,
                child: Image.asset("assets/images/basemap_image.png",fit: BoxFit.cover,width: double.maxFinite,height: double.maxFinite,)),
            Positioned(
              top: 80,
              left: 80,
              right: 80,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset("assets/images/tabler_loader.svg"),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage?.translate(context) ?? "Searching for rides...".translate(context))),
                    ],
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Positioned(
                top: 80,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {


                        goBack();
                      },
                      child: ClipOval(
                        child: Container(
                          height: 40,
                          width: 40,
                          color: themeColor,
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.45,
              maxChildSize: 0.75,
              builder: (_, controller) => _buildBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 3,
            decoration: BoxDecoration(color: grey4, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          SvgPicture.asset(
            "assets/images/serach_ride_img.svg",
            colorFilter: const ColorFilter.mode(Colors.orange, BlendMode.srcIn),
          ),
          Text(
            "Searching for cars nearby".translate(context),
            style: heading2Grey1(context).copyWith(),
          ),
          const SizedBox(height: 5),
          Text(
            "Please wait while we find you the best ride..".translate(context),
            style: regular2(context).copyWith(),
          ),
          const SizedBox(height: 30),
          BlocBuilder<BookRideRealTimeDataBaseCubit, BookRideState>(
            builder: (context, state) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _buildIconCircle(icon: Icons.radio_button_checked, color: greentext),
                    Container(
                      height: 40,
                      width: 2,
                      color: Colors.grey.shade300,
                    ),
                    _buildIconCircle(icon: Icons.location_on, color: Colors.redAccent),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Pickup".translate(context)),
                      const SizedBox(height: 4),
                      _buildAddress(state.pickupAddress, context),
                      const SizedBox(height: 14),
                      _buildLabel("Drop-off".translate(context)),
                      const SizedBox(height: 4),
                      _buildAddress(state.dropoffAddress, context),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CustomsButtons(
            text: "Cancel".translate(context),
            backgroundColor: themeColor,
            textColor: whiteColor,
            onPressed: () {
              context.read<DriverNearByCubit>().resetNearByDriverState();
              context.read<GetPolylineCubit>().resetPolylines();
              context.read<DriverMapCubit>().resetState();
              context.read<GetDistanceRouteCubit>().removeDistanceState();
              goBack();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconCircle({required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildAddress(String address, BuildContext context) {
    return Text(
      address,
      style: boldstyle(context).copyWith(fontSize: 12),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}



