// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../presentation/cubits/localizations_cubit.dart';
import '../../presentation/cubits/profile/delete_account_cubit.dart';
import '../../presentation/screens/Auth/login_screen.dart';

Widget commonlyUserLogo() {
  return Image.asset(
    'assets/images/logos.png',height: 100,
  );
}

class CustomsButtons extends StatelessWidget {
  final String text;
  final Color? textColor;
  final Color backgroundColor;
  final IconData? icon;
  final VoidCallback onPressed;

  const CustomsButtons(
      {super.key,
      required this.text,
      required this.backgroundColor,
      required this.onPressed,
      this.icon,
      this.textColor});

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ??
        (backgroundColor.computeLuminance() < 0.45 ? Colors.white : Colors.black87);
    return ConstrainedBox(
      constraints:
          const BoxConstraints.expand(width: double.infinity, height: 50.0),
      child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 10),
              backgroundColor: backgroundColor,
              foregroundColor: effectiveTextColor,
              iconColor: effectiveTextColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                text.translate(context),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style:
                    largeHeadingMedium.copyWith(color: effectiveTextColor, fontSize: 14,fontWeight: FontWeight.normal),
              ),
              if (icon != null) const SizedBox(width: 10),
              if (icon != null) Icon(icon, color: effectiveTextColor),
            ],
          )),
    );
  }
}

class CustomAppBars extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color? iconColor;
  final Color titleColor;
  final VoidCallback? onBackButtonPressed;
  final List<Widget>? actions;
  final double elevation;
  final bool? centerTitle;

  const CustomAppBars(
      {super.key,
      required this.title,
      required this.backgroundColor,
      this.iconColor,
      required this.titleColor,
      this.onBackButtonPressed,
      this.actions,
      this.elevation = 0.0,
      this.centerTitle});

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return AppBar(
      centerTitle: true,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: elevation,
      leadingWidth: 85,
      leading: GestureDetector(
        onTap: onBackButtonPressed ??
            () {
              Navigator.pop(context);
            },
        child: Padding(
          padding:
              const EdgeInsets.only(left: 20, top: 8, bottom: 8, right: 20),
          child: PhysicalModel(
            color: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 1.0,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                  color: notifires.getblackwhiteColor,
                  borderRadius: BorderRadius.circular(30)),
              child: Icon(Icons.arrow_back_ios_new,
                  color: notifires.getGrey3whiteColor),
            ),
          ),
        ),
      ),
      title: Text(title,
          style: heading2Grey1(context).copyWith(color: titleColor)),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ignore: prefer_typing_uninitialized_variables
var closeLoading;
showLoading() {
  closeLoading = BotToast.showLoading();
}
showErrorToastMessage(String message) {
  BotToast.showCustomText(
    duration: const Duration(seconds: 3),
    align: Alignment.bottomCenter.add(const Alignment(0, -0.12)), // Moves up slightly
    toastBuilder: (context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15), // Adds bottom padding
        child: CustomToastMessages(
          message: message.toString(),
          error: true,
        ),
      );
    },
  );
}

showToastMessage(String message) {
  BotToast.showCustomText(
    align: Alignment.bottomCenter.add(const Alignment(0, -0.12)), // Moves
    toastBuilder: (_) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: CustomToastMessages(
        message: message,
        error:
        false, // add this if you are supporting both success & error cases
      ),
    ),
    duration: const Duration(seconds: 3),

// prevents it from showing across routes/screens
  );
}

class CustomToastMessages extends StatefulWidget {
  final String message;
  final bool? error;

  const CustomToastMessages({
    super.key,
    required this.message,
    this.error,
  });

  @override
  _CustomToastMessagesState createState() => _CustomToastMessagesState();
}

class _CustomToastMessagesState extends State<CustomToastMessages>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isError = widget.error ?? false;
    final Color color = isError ? redColor : greenColor;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin:
                const EdgeInsets.only(top: 20), // Space for floating text
                decoration: BoxDecoration(
                  color: whiteColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: color.withOpacity(0.1),
                      child: Icon(
                        isError ? Icons.warning_amber : Icons.check,
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.message.translate(context),
                        style:   const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,

                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => BotToast.removeAll(),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 14,
                        child:   Icon(
                          Icons.close,
                          color: whiteColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating "Error!" or "Success!" text
              Positioned(
                top: 0,
                left: 16,
                child: Text(
                  isError ? "Error!".translate(context) : "Success!".translate(context),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: whiteColor.withOpacity(0.9),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showDynamicBottomSheets(BuildContext context,
    {required String title,
    required String description,
    required String firstButtontxt,
    required String secondButtontxt,
    required final VoidCallback onpressed,
    required final VoidCallback onpressed1}) {
  showModalBottomSheet(
    isScrollControlled: false,
    constraints:
        const BoxConstraints.expand(width: double.infinity, height: 240),
    context: context,
    builder: (context) {
      return DynamicBottomSheetContent(
        title: title,
        description: description,
        firstButtontxt: firstButtontxt,
        secondButtontxt: secondButtontxt,
        onpressed: onpressed,
        onpressed1: onpressed1,
      );
    },
  );
}

class DynamicBottomSheetContent extends StatefulWidget {
  final String title;
  final String description;
  final String firstButtontxt;
  final String secondButtontxt;
  final VoidCallback onpressed;
  final VoidCallback onpressed1;

  const DynamicBottomSheetContent(
      {super.key,
      required this.title,
      required this.description,
      required this.firstButtontxt,
      required this.secondButtontxt,
      required this.onpressed,
      required this.onpressed1});

  @override
  State<DynamicBottomSheetContent> createState() =>
      _DynamicBottomSheetContentState();
}

class _DynamicBottomSheetContentState extends State<DynamicBottomSheetContent> {
  bool isCancelSelected = true; // Initially, the "Cancel" button is selected
  bool isDeleteSelected = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: notifires.getblackwhiteColor,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0), topRight: Radius.circular(0))),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
              child: Text(widget.title.translate(context),
                  style: heading2Grey1(context).copyWith())),
          const SizedBox(height: 20),
          Divider(
            height: 1,
            color: notifires.getGrey3whiteColor,
          ),
          const SizedBox(height: 15),
          Flexible(
              child: Text(widget.description.translate(context),
                  style: heading3Grey1(context))),
          const SizedBox(height: 30),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              // height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.38),
                      child: ElevatedButton(
                        onPressed: widget.onpressed,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: notifires.getBoxColor,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge),
                          ),
                        ),
                        child: Text(widget.firstButtontxt.translate(context),
                            style: heading3(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.38),
                      child: ElevatedButton(
                        onPressed: widget.onpressed1,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          iconColor: Colors.white,
                          foregroundColor: Colors.white,
                          // onPrimary: WhiteColor, // Customize the text color
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1.0, color: themeColor),
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusLarge),
                          ),
                        ),
                        child: Text(widget.secondButtontxt.translate(context),
                            style: heading3(context)
                                .copyWith(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

Future<Uint8List> createCustomMarkerImage(String imageUrl) async {
  ui.Image profileImage;

  try {
    if (imageUrl.isEmpty) throw Exception("Empty URL");

    // Try loading network image
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final Image image = Image.network(imageUrl, fit: BoxFit.cover);

    image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            completer.complete(info.image);
          }, onError: (error, stackTrace) {
            completer.completeError(error);
          }),
        );

    profileImage = await completer.future;
  } catch (e) {
    // Fallback: load default asset image
    final ByteData data = await rootBundle.load('assets/images/logos.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    profileImage = frame.image;
  }

  // Marker size setup
  const double circleSize = 100.0;
  const double pinHeight = 40.0;
  const double totalHeight = circleSize + pinHeight;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  final Paint whitePaint = Paint()..color = Colors.white;
  const double circleRadius = circleSize / 2;

  // Draw circular white background
  canvas.drawCircle(
      const Offset(circleRadius, circleRadius), circleRadius, whitePaint);

  // Clip only image part
  final Path imageClipPath = Path()
    ..addOval(Rect.fromCircle(
        center: const Offset(circleRadius, circleRadius),
        radius: circleRadius - 6));
  canvas.save();
  canvas.clipPath(imageClipPath);

  // Draw image
  paintImage(
    canvas: canvas,
    rect: const Rect.fromLTWH(6, 6, circleSize - 12, circleSize - 12),
    image: profileImage,
    fit: BoxFit.cover,
  );
  canvas.restore();

  // Draw pin triangle
  final Paint pinPaint = Paint()..color = Colors.red;
  final Path pinPath = Path()
    ..moveTo(circleRadius - 10, circleSize - 2)
    ..lineTo(circleRadius + 10, circleSize - 2)
    ..lineTo(circleRadius, totalHeight)
    ..close();

  canvas.drawPath(pinPath, pinPaint);

  // Final marker image
  final ui.Image finalImage = await recorder
      .endRecording()
      .toImage(circleSize.toInt(), totalHeight.toInt());

  final ByteData? byteData =
      await finalImage.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

logout(BuildContext context) async {
  var boxs = await Hive.openBox('appBox');
  await boxs.clear();

  box.delete('HomeData');
  appLocale = const Locale('en');
  context.read<LanguageCubit>().loadCurrentLanguage();
  bool defaultDarkMode = false;

  box.put("getDarkValue", defaultDarkMode);
  notifires.setIsDark = defaultDarkMode;
  token = "";
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const LoginScreen()),
    (Route<dynamic> route) => false,
  );
}

buildShowDialog(BuildContext context) {
  return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: blackColor.withOpacity(0.1),
      builder: (BuildContext context) {
        return Center(
                child: CircularProgressIndicator(
                    color: yelloColor2, strokeWidth: 3))

            ;
      });
}

class Widgets {
  static bool isLoadingShowing = false;

  static void showLoader(BuildContext context) async {
    if (isLoadingShowing) {
      return;
    }
    isLoadingShowing = true;
    showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (BuildContext context) {
          return AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.black.withOpacity(0.2),
            ),
            child: SafeArea(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  return;
                },
                child: Center(
                    child: CircularProgressIndicator(
                  color: yelloColor2,
                )),
              ),
            ),
          );
        });
  }

  static void hideLoder(BuildContext context) {
    if (isLoadingShowing) {
      isLoadingShowing = false;
      Navigator.of(context).pop();
    }
  }
}

class SearchWidgets {
  static bool isLoadingShowing = false;

  static void showLoader(BuildContext context) async {
    if (isLoadingShowing) {
      return;
    }
    isLoadingShowing = true;
    showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: true,
        builder: (BuildContext context) {
          return AnnotatedRegion(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.black.withOpacity(0.2),
            ),
            child: SafeArea(
              child: PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  return;
                },
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset("assets/images/search_loading.gif",
                          height: 70),
                      Text("Request sent to nearby drivers",
                          style:
                              headingBlack(context).copyWith(color: whiteColor))
                    ],
                  ),
                )),
              ),
            ),
          );
        });
  }

  static void hideLoder(BuildContext context) {
    if (isLoadingShowing) {
      isLoadingShowing = false;
      Navigator.of(context).pop();
    }
  }
}

// ignore: non_constant_identifier_names
Widget ShimmerLoader() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      margin: const EdgeInsets.only(right: 5),
      height: 80,
      width: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
    
    ),
  );
}

class CustomAppBarNew extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;
  final bool? isCenterTitle;
  final bool? isBackButton;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? fontSize;
  const CustomAppBarNew({
    super.key,
    required this.title,
    this.titleColor,
    this.onBackTap,
    this.fontSize,
    this.backgroundColor,
    this.isCenterTitle,
    this.isBackButton,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      surfaceTintColor: backgroundColor ?? Colors.white,
      backgroundColor: backgroundColor ?? Colors.white,
      centerTitle: isCenterTitle ?? true,
      title: Text(title.translate(context),
          style: headingBlack(context).copyWith(
              fontSize: fontSize ?? 22, color: titleColor ?? blackColor)),
      leading: isBackButton == true
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Transform.translate(
                offset: const Offset(0, 0),
                child: InkWell(
                  onTap: onBackTap ?? () => Navigator.of(context).pop(),
                  child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: backgroundColor ?? notifires.getbgcolor,
                          border:
                              Border.all(color: notifires.getGrey3whiteColor)),
                      child: Icon(Icons.arrow_back,
                          size: 20, color: notifires.getwhiteblackColor)),
                ),
              ),
            ),
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

Widget zoomButton({IconData? icon, VoidCallback? onPressed}) {
  return Material(
    elevation: 2,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon),
      ),
    ),
  );
}

void goTo(Widget screen) {
  navigatorKey.currentState!.push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

dialogExit(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: notifires.getboxcolor,
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Icon(
                Icons.error,
                size: 75,
                color: redColor,
              ),
              Text(
                'Do you want to exit?'.translate(context),
                textAlign: TextAlign.center,
                style: headingBlack(context)
                    .copyWith(color: notifires.getwhiteblackColor),
              )
            ],
          ),
        ),
        actions: <Widget>[
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  border: Border.all(color: grey5),
                                  color: grey4,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(
                                "Cancel".translate(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ))))),
                  Expanded(
                      child: InkWell(
                          onTap: () {
                            Navigator.pop(context);

                            SystemNavigator.pop();
                          },
                          child: Container(
                              margin: const EdgeInsets.only(left: 8, right: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  border: Border.all(color: blackColor),
                                  color: blackColor,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(
                                "Exit".translate(context),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ))))),
                ],
              ),
              const SizedBox(
                height: 8,
              )
            ],
          )
        ],
      );
    },
  );
}

class PaymentConfirmationDialogs extends StatefulWidget {
  final String? desc;
  final String? firstButtontext;
  final String? secondButtontext;
  final String? text;
  final Function()? onPressed;

  const PaymentConfirmationDialogs(
      {super.key,
      this.desc,
      this.firstButtontext,
      this.secondButtontext,
      this.text,
      this.onPressed});

  @override
  _PaymentConfirmationDialogsState createState() =>
      _PaymentConfirmationDialogsState();
}

class _PaymentConfirmationDialogsState
    extends State<PaymentConfirmationDialogs> {
  bool isCancelSelected = true;
  bool isDeleteSelected = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.26,
        decoration: BoxDecoration(
          color: notifires.getboxcolor,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Icon(Icons.payment_rounded,
                size: 70, color: blackColor), // Customize the icon
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('${widget.text}'.translate(context),
                  textAlign: TextAlign.center,
                  style: regular(context).copyWith(
                      fontSize: 16, color: notifires.getwhiteblackColor)),
            ), // Customize the text style
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                // height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints.expand(height: 40),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              Navigator.pop(context);
                              isCancelSelected = true;
                              isDeleteSelected =
                                  false; // Mark "Cancel" as selected
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: notifires.getBoxColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Cancel'.translate(context),
                              style: heading3Grey1(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints.expand(height: 40),
                        child: InkWell(
                          onTap: widget.onPressed,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: blackColor,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text('Confirm'.translate(context),
                                style: heading3Grey1(context)
                                    .copyWith(color: whiteColor)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Completed':
      return appgreen;
    case 'Cancelled':
      return redColor;
    case 'Declined':
      return redColor;
    case 'Pending':
      return orangeColor; // define if not yet
    case 'Accepted':
    case 'Arrived':
    case 'Live':
      return blueColor; // define as per your theme
    case 'Confirmed':
      return Colors.deepPurple; // custom if needed
    case 'Expired':
    case 'Refunded':
      return greyColor2; // soft grey maybe
    default:
      return Colors.black54;
  }
}

Color getStatusBackground(String status) {
  return getStatusColor(status).withOpacity(0.2);
}

void goBack() {
  navigatorKey.currentState!.pop();
}

int fileSizeThreshold = 1024 * 1024;
int goodQuality = 85;
int badQuality = 50;
int maxWidth = 800;
int maxHeight = 600;

Future<String> compressAndUploadImage(String imagePath) async {
  var imageFile = File(imagePath);
  int originalSize = await imageFile.length();
  int quality = originalSize > fileSizeThreshold ? badQuality : goodQuality;
  var compressedImage = await FlutterImageCompress.compressWithFile(
    imagePath,
    quality: quality,
    minWidth: maxWidth,
    minHeight: maxHeight,
  );

  int compressedSize = compressedImage!.length;
  // ignore: unused_local_variable
  double compressionRatio = originalSize / compressedSize;

  var base64Image = base64Encode(compressedImage);

  String format = '';
  if (compressedImage.length > 8) {
    if (compressedImage[0] == 0xFF && compressedImage[1] == 0xD8) {
      format = 'jpeg';
    } else if (compressedImage[0] == 0x89 && compressedImage[1] == 0x50) {
      format = 'png';
    }
  }

  String finalBase64 = "data:image/$format;base64,$base64Image";
  return finalBase64;
}

Widget myNetworkImage(String? image,
    {double height = 150.0, double width = 150.0}) {
  if (image != null && Uri.tryParse(image)?.hasAbsolutePath == true) {
    // Valid URL, proceed with loading
    return SizedBox(
      width: width,
      height: height,
      child: Image.network(
        image,
        fit: BoxFit.cover,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child;
          } else {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            );
          }
        },
        errorBuilder: (context, exception, stackTrace) {
          return getErrorImage();
        },
      ),
    );
  } else {
    return getErrorImage();
  }
}

Widget getErrorImage() {
  return Padding(
    padding: const EdgeInsets.all(10),
    child: Image.asset(
      "assets/images/logos.png",
      fit: BoxFit.contain,
    ),
  );
}

Widget myAssetImage(String? image, {double? height, double? width}) {
  if (image != null && image.isNotEmpty) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
      ),
    );
  } else {
    return getErrorImage();
  }
}



void showCancelRideBottomSheet({
  required BuildContext context,
  required VoidCallback onCancelRide,
  required VoidCallback onKeepRide,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: notifires.getbgcolor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, color: blackColor, size: 35),
            const SizedBox(height: 10),
            Text(
              "Are you sure you want to cancel your ride?",
              style: heading2Grey1(context),
              textAlign: TextAlign.center,
            ),
            Text(
              "If you cancel now, your current ride request will be aborted.",
              style: regular(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onCancelRide, // Use callback for Cancel Ride
                  child: Container(
                    alignment: Alignment.center,
                    height: 50,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: blackColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      "Cancel Ride",
                      style: regular2(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                InkWell(
                  onTap: onKeepRide, // Use callback for Keep Ride
                  child: Container(
                    alignment: Alignment.center,
                    height: 50,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: BoxDecoration(
                      color: notifires.getBoxColor,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      "Keep Ride",
                      style: regular2(context).copyWith(
                        color: grey1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}


Widget buildLocationRow({
  required IconData icon,
  required Color color,
  required Color bgColor,
  required String text,
  required BuildContext context,
}) {
  return Row(
    children: [
      ClipOval(
        child: Container(
          height: 25,
          width: 25,
          color: bgColor,
          child: Icon(icon, color: color, size: 16),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: regular(context).copyWith(color: grey1),
        ),
      ),
    ],
  );
}





class DeleteConfirmationDialogs extends StatelessWidget {
  final String? desc;
  final String? firstButtontext;
  final String? secondButtontext;

  const DeleteConfirmationDialogs({
    super.key,
    this.desc,
    this.firstButtontext,
    this.secondButtontext,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteAccountCubit, DeleteAccountState>(
      listener: (context, state) {
        if (state is DeleteAccountLoading) {
          Widgets.showLoader(context); // Your custom loader
        } else {
          Widgets.hideLoder(context);
          if (state is DeleteAccountSuccess) {
            showToastMessage(state.message);
            Navigator.pop(context);
            logout(context);
            // Close dialog
          } else if (state is DeleteAccountFailed) {
            showToastMessage(state.error);
          }
        }
      },
      child: Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        backgroundColor: Colors.transparent,
        elevation: 6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: notifires.getboxcolor,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 80, color: themeColor),
              const SizedBox(height: 16),
              Text(
                "Are you sure you want to delete your account?"
                    .translate(context),
                textAlign: TextAlign.center,
                style: regular(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: notifires.getGrey2whiteColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This action is permanent and cannot be undone."
                    .translate(context),
                textAlign: TextAlign.center,
                style: regular(context).copyWith(
                  fontSize: 14,
                  color: notifires.getGrey2whiteColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: notifires.getBoxColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color:
                                notifires.getGrey2whiteColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Cancel".translate(context),
                          style: heading3Grey1(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context
                            .read<DeleteAccountCubit>()
                            .deleteAccount(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        iconColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          "Yes, Delete".translate(context),
                          style: heading3Grey1(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MapShimmerScreen extends StatelessWidget {
  const MapShimmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // Map area shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                    ),
                  ),

                  // Back button shimmer
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Search buttons shimmer
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    right: 16,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // Go to Pickup button shimmer
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Shimmer.fromColors(
                        baseColor: Colors.amber[400]!,
                        highlightColor: Colors.amber[200]!,
                        child: Container(
                          width: 200,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer verification section
                  Row(
                    children: [
                      // Profile image shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Pickup location title
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location icon shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.green[300]!,
                        highlightColor: Colors.green[100]!,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Address text shimmer
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 20,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Call button shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey[800]!,
                        highlightColor: Colors.grey[600]!,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Arrived button shimmer
                  Shimmer.fromColors(
                    baseColor: themeColor,
                    highlightColor: themeColor,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Future<Uint8List> getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

Widget languageButton({
  required VoidCallback onTap,

}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: themeColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(Icons.language, color: themeColor, size: 18),
          const SizedBox(width: 6),
          BlocBuilder<LCodeCubit,String>(
            builder: (context,state) {
              return Text(
                state.toUpperCase(),
                style:   TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
          ),
            Icon(Icons.keyboard_arrow_down_rounded,
              color: themeColor, size: 18),
        ],
      ),
    ),
  );
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadius = 6371; // km

  double dLat = _deg2rad(lat2 - lat1);
  double dLon = _deg2rad(lon2 - lon1);

  double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

double _deg2rad(double deg) {
  return deg * (math.pi / 180);
}
