import 'package:ride_on/app/route_settings.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/widgets/thanku_screen.dart';
import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../cubits/book_ride_cubit.dart';
import '../cubits/location/get_nearby_drivers_cubit.dart';
import '../cubits/location/set_marker_cubit.dart';
import '../cubits/realtime/get_ride_request_status_cubit.dart';
import '../cubits/realtime/ride_request_cubit.dart';
import '../cubits/review/review_cubit.dart';
import '../screens/Home/item_home_screen.dart';
import 'custom_text_form_field.dart';

class CustomReviewWidget extends StatefulWidget {
  final String? bookingId;
  const CustomReviewWidget({super.key, this.bookingId});

  @override
  State<CustomReviewWidget> createState() => _CustomReviewWidgetState();
}

class _CustomReviewWidgetState extends State<CustomReviewWidget> {
  String totalTime = "";

  @override
  void initState() {
    super.initState();
    fetchTotalTime(); // Call async method from initState
  }

  Future<void> fetchTotalTime() async {
    final rideId = context.read<RideRequestCubit>().state.rideId;
    final time = await getTotalTimeFromRideRequest(rideId);

    if (time != null) {
      setState(() {
        totalTime = time;
      });

    }
  }

  Future<String?> getTotalTimeFromRideRequest(String rideId) async {
    try {
      final DatabaseReference rideRequestRef =
          FirebaseDatabase.instance.ref('ride_requests/$rideId');
      final DataSnapshot snapshot = await rideRequestRef.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        if (data.containsKey('totalTime')) {
          final totalTime = data['totalTime']?.toString();

          return totalTime;
        } else {

          return null;
        }
      } else {

        return null;
      }
    } catch (error) {

      return null;
    }
  }

  TextEditingController textEditingReviewController = TextEditingController();
  String ratingData = "";
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.75,
        maxChildSize: 0.75,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(),
                    Center(
                      child: Container(
                        width: 70,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () {

                        goBack();
                        setState(() {
                          clearAllRiderData(context);
                          goToWithClear(const ItemHomeScreen());
                           

                        });
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              border: Border.all(width: 1, color: blackColor),
                              borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child:   Text("Skip".translate(context))),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BlocBuilder<RideRequestCubit, RideRequestState>(
                        builder: (context, state) {
                      return SizedBox(
                        height: 60,
                        width: 60,
                        child: state.acceptedDriverImageUrl.isNotEmpty
                            ? ClipOval(
                                child: myNetworkImage(
                                  state.acceptedDriverImageUrl,
                                ),
                              )
                            : Align(
                                alignment: Alignment.center,
                                child: Image.asset(
                                  "assets/images/drower_person.png",
                                  height: 100,
                                ),
                              ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 5),
                Column(children: [
                  BlocBuilder<RideRequestCubit, RideRequestState>(
                      builder: (context, state) {
                    return Text(
                        state.acceptedDriverName.isNotEmpty
                            ? state.acceptedDriverName
                            : "Dennis Oliver",
                        style: regularBlack(context).copyWith(
                          fontSize: 14,
                        ));
                  }),
                  const SizedBox(height: 5),
                  
                  const SizedBox(height: 5),
                  Text("How was your trip?".translate(context),
                      style: regular2(context).copyWith(
                        fontSize: 16,
                      )),
                  const SizedBox(height: 5),
                  SizedBox(
                      height: 40,
                      child: RatingBar.builder(
                        initialRating: 0,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: yelloColor,
                        ),
                        onRatingUpdate: (rating) {
                          final intRating = rating.toInt();

                          ratingData = intRating.toString();setState(() {

                          });

                        },
                      )),
                ]),
                const SizedBox(height: 30),
                TextFieldAdvance(
                    maxlines: 5,
                    backgroundColor: grey6,
                    txt: "Add a comment for the driver ...".translate(context),
                    textEditingControllerCommon: textEditingReviewController,
                    inputType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    inputAlignment: TextAlign.start),
                const SizedBox(height: 30),
                const SizedBox(height: 10),
                BlocConsumer<ReviewCubit, ReviewState>(builder: (context, state) {
                  return CustomsButtons(
                      text: "Submit",
                      backgroundColor: ratingData.isEmpty? grey4:themeColor,
                      textColor: ratingData.isEmpty ? grey3 : whiteColor,
                      onPressed: () {
                        if(ratingData.isEmpty){
                          return;
                        }
                        context.read<ReviewCubit>().resetState();
                        context.read<ReviewCubit>().submitReview(
                            context: context,
                            bookingId: widget.bookingId!,
                            rating: ratingData,
                            message: textEditingReviewController.text);
                      });
                }, listener: (context, state) {
                  if (state is ReviewLoading) {
                    Widgets.showLoader(context);
                  }
                  if (state is ReviewSuceess) {
                    Widgets.hideLoder(context);


                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ThankuScreen(rating: int.parse(ratingData),msg: textEditingReviewController.text,)));
                  }
                  if (state is ReviewFailure) {
                    Widgets.hideLoder(context);
                  }
                }),
                const SizedBox(
                  height: 300,
                )
              ],
            ),
          );
        },
      ),
    );
  }
}


void clearAllRiderData(BuildContext context){
  context.read<RideRequestCubit>().resetState();
  context.read<GetRideRequestPaymentCubit>().resetStatus();
  context.read<UserMarkerCubit>().clear();
  context.read<GetPolylineCubit>().resetPolylines();

  context.read<BookRideRealTimeDataBaseCubit>().resetState();

  context.read<RideRequestCubit>().removeProgressIndicator();
  context.read<RideRequestCubit>().removeRideMessage();
 
}


