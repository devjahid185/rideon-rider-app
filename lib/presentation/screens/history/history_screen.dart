import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/history_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/history/history_cubit.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool? isBackButton;
  const HistoryScreen({super.key, this.isBackButton});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryCubit>().getHistoryData(
          context: context,
          bookingKeyMap: {"typeId": "completed", "offset": "$offset"});
    });
  }

  int offset = 0;
  List<Bookings> bookings = [];

  BookingRideData? bookingRideData;

  String formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return "";

      final inputDate = DateTime.tryParse(dateStr);
      if (inputDate == null) return dateStr;

      final formattedDate = DateFormat("dd MMM yyyy").format(inputDate);
      return formattedDate;
    } catch (e) {
      return dateStr;
    }
  }

  bool isShimmer = true;

  RefreshController refreshController = RefreshController();

  void onLoading() {
    isShimmer = false;
    context.read<HistoryCubit>().getHistoryData(
        context: context,
        bookingKeyMap: {"typeId": "completed", "offset": "$offset"});
    refreshController.loadComplete();
  }

  void onRefresh() {
    bookings.clear();
    offset = 0;
    isShimmer = true;
    context.read<HistoryCubit>().getHistoryData(
        context: context,
        bookingKeyMap: {"typeId": "completed", "offset": "$offset"});
    refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (widget.isBackButton == true) {
          return true;
        }

        return false;
      },
      child: Scaffold(
        backgroundColor: whiteColor,
        appBar: AppBar(
          leadingWidth: 140,
          backgroundColor: whiteColor,
          surfaceTintColor: whiteColor,
          leading: InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 25, right: 25),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    size: 25,
                    color: grey2,
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("History".translate(context),
                style: regularBlack(context).copyWith(fontSize: 24)),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("Rides".translate(context),
                style: regularBlack(context).copyWith(fontSize: 20)),
          ),
          Divider(color: grey5),
          Expanded(
            child: BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
              if (state is HistoryLoading && isShimmer) {
                return ListView.builder(
                  itemCount: 6, // number of shimmer placeholders
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Shimmer.fromColors(
                        baseColor: grey5,
                        highlightColor: grey4,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
              if (state is HistorySuccess) {
                isShimmer = true;
                bookings.addAll(state.bookings ?? []);
                offset = state.historyModel?.data?.offset ?? 0;
              }
              return SmartRefresher(
                controller: refreshController,
                onLoading: onLoading,
                onRefresh: onRefresh,
                enablePullUp: offset == -1 ? false : true,
                child: bookings.isEmpty
                    ? Center(
                        child: Text(
                        "Order history not found".translate(context),
                        style: headingBlack(context),
                      ))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 50),
                        itemCount: bookings.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox();
                        },
                        itemBuilder: (context, index) {
                          final ride = bookings[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HistoryDetailScreen(rideData: ride),
                                  // builder: (context) => RideReceiptScreen( ),
                                ),
                              );
                            },
                            child: Card(
                              color: notifires.getbgcolor,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// Top Row: Date & Fare
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatDate(ride.rideDate ?? ""),
                                          style: headingBlackBold(context)
                                              .copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          "${ride.currencyCode} ${ride.amountToPay}",
                                          style: headingBlackBold(context)
                                              .copyWith(
                                            color: Colors.green.shade700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              height: 45,
                                              width: 28,
                                              decoration: BoxDecoration(
                                                color: themeColor,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 10),
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(
                                                  color: whiteColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Image.asset(
                                                "assets/images/line2.png",
                                                color: blackColor,
                                                scale: 3),
                                            const SizedBox(height: 5),
                                            Container(
                                              height: 45,
                                              width: 28,
                                              decoration: BoxDecoration(
                                                color: whiteColor,
                                                border: Border.all(
                                                    width: 1, color: grey4),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              alignment: Alignment.topCenter,
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                    top: 10),
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(
                                                  color: blackColor,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                ride.pickupLocation?.address ??
                                                    "",
                                                style: headingBlack(context)
                                                    .copyWith(fontSize: 14),
                                                softWrap: true,
                                              ),
                                              const SizedBox(height: 28),
                                              Text(
                                                ride.dropoffLocation?.address ??
                                                    "",
                                                style: headingBlack(context)
                                                    .copyWith(fontSize: 14),
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    /// Status Badge
                                    if (ride.status != null &&
                                        ride.status!.isNotEmpty)
                                      Row(
                                        children: [
                                          Align(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: getStatusBackground(
                                                    ride.status!),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Text(
                                                ride.status!.translate(context),
                                                style: headingBlack(context)
                                                    .copyWith(
                                                  color: getStatusColor(
                                                      ride.status!),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          (ride.deliveryPhotos ?? []).isEmpty
                                              ? Icon(
                                                  Icons.local_taxi_rounded,
                                                  size: 22,
                                                  color: themeColor,
                                                )
                                              : Icon(
                                                  Icons.shopping_bag_rounded,
                                                  size: 22,
                                                  color: themeColor,
                                                ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              );
            }),
          ),
        ]),
      ),
    );
  }
}

class RideHistory {
  final String dateTime;
  final String location;
  final double price;
  final String status;

  RideHistory({
    required this.dateTime,
    required this.location,
    required this.price,
    required this.status,
  });
}


