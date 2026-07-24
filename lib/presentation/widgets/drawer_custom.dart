// ignore: file_names
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../core/utils/common_widget.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../cubits/book_ride_cubit.dart';
import '../cubits/logout_cubit.dart';
import '../cubits/profile/edit_profile_cubit.dart';
import '../cubits/realtime/update_ride_request_parameter.dart';
import '../screens/Account/profile_screen.dart';
import '../screens/Account/setting_screen.dart';
import '../screens/Account/static_screen.dart';
import '../screens/Auth/login_screen.dart';
import '../screens/food/food_home_screen.dart';
import '../screens/history/history_screen.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  void initState() {
    context.read<MyImageCubit>().updateMyImage(myImage);
    context
        .read<BookRideRealTimeDataBaseCubit>()
        .updateUserImageUrl(userImageUrl: myImage);
    context.read<UpdateRideRequestParameterCubit>().updateFirebaseUserParameter(
        rideId: context.read<BookRideRealTimeDataBaseCubit>().state.rideId,
        userParameter: {"userImageUrl": myImage});
    context.read<NameCubit>().updateName(loginModel?.data?.firstName ?? "");
    context.read<EmailCubit>().updateEmail(loginModel?.data?.email ?? "");

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(50),
      ),
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.75,
        backgroundColor: whiteColor,
        surfaceTintColor: whiteColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Row(children: [
                      Icon(Icons.arrow_back_ios_new,
                          color: blackColor, size: 15),
                      const SizedBox(width: 4),
                      Text("Back".translate(context),
                          style: heading3Grey1(context))
                    ]),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      goTo(const EditProfile());
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<MyImageCubit, dynamic>(
                            builder: (context, state) {
                          return myImage.isEmpty
                              ? Icon(
                                  CupertinoIcons.profile_circled,
                                  size: 60,
                                  color: blackColor,
                                )
                              : SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: ClipOval(
                                    child: myNetworkImage(
                                        context.read<MyImageCubit>().state),
                                  ),
                                );
                        }),
                        const SizedBox(height: 10),
                        BlocBuilder<NameCubit, dynamic>(
                            builder: (context, state) {
                          return Row(
                            children: [
                              Text(context.read<NameCubit>().state,
                                  style: headingBlack(context)
                                      .copyWith(fontSize: 14)),
                            ],
                          );
                        }),
                        BlocBuilder<EmailCubit, dynamic>(
                            builder: (context, state) {
                          return Row(
                            children: [
                              Text(context.read<EmailCubit>().state,
                                  style: headingBlack(context)
                                      .copyWith(fontSize: 14)),
                            ],
                          );
                        }),
                        const SizedBox(height: 30),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomRowItem(
                    imagePath: "assets/images/history_image.svg",
                    title: "History".translate(context),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: grey5),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomRowItem(
                    imagePath: "assets/images/About Us.svg",
                    title: "About Us".translate(context),
                    onTap: () {
                      Navigator.of(context).pop();
                      goTo(const StaticScreen(
                        data: "About Us",
                        isBack: true,
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: grey5,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomRowItem(
                    imagePath: "assets/images/Settings.svg",
                    title: "Settings".translate(context),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: grey5,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomRowItem(
                    imagePath: "assets/images/Help and Support.svg",
                    title: "Help and Support".translate(context),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StaticScreen(
                                    data: "Help and Support",
                                    isBack: true,
                                  )));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: grey5,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: CustomRowItem(
                    imagePath: "assets/images/history_image.svg",
                    title: "Food Delivery".translate(context),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodHomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: grey5,
                ),
                const SizedBox(height: 4),
                BlocConsumer<LogoutCubit, LogoutState>(
                  listener: (context, state) {
                    if (state is LogoutFailure) {
                      showErrorToastMessage("Logout Failed: ${state.error}");
                    } else if (state is LogoutSuccess) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                    }
                  },
                  builder: (context, state) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: CustomRowItem(
                        imagePath: "assets/images/Logout.svg",
                        title: "Logout".translate(context),
                        onTap: () {
                          showDynamicBottomSheets(context,
                              title: "Logout"
                                  .translate(context)
                                  .translate(context),
                              description: "Are you sure You Want to Logout?"
                                  .translate(context)
                                  .translate(context),
                              firstButtontxt: "Cancel".translate(context),
                              secondButtontxt: "Yes".translate(context),
                              onpressed: () {
                            Navigator.pop(context);
                          }, onpressed1: () async {
                            token = "";
                            context.read<LogoutCubit>().logout(context);
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class CustomRowItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final VoidCallback? onTap; // Add onTap callback

  const CustomRowItem(
      {super.key, required this.imagePath, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            imagePath,
            width: 15,
            height: 15,
          ),
          const SizedBox(width: 10),
          Text(
            title.translate(context),
            style: heading3Grey1(context),
          ),
        ],
      ),
    );
  }
}


