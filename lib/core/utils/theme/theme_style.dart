import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';

//Dimensions //
class Dimensions {
  static double fontSizeExtraSmall = 10;
  static double fontSizeSmall = 12;
  static double fontSizeDefault = 14;
  static double fontSizeLarge = 20;
  static double fontSizeExtraLarge = 18;
  static double fontSizeOverLarge = 25;
  static double fontSizeLargeNew = 22;
  static double fontSizeExtraLargeNew = 25;
  static double fontSizeOverLargeNew = 30;
  static const double paddingSizeExtraSmall = 5.0;
  static const double paddingSizeSmall = 12.0;
  static const double paddingSizeDefault = 15.0;
  static const double paddingSizeLarge = 15.0;
  static const double paddingSizeExtraLarge = 25.0;
  static const double radiusSmall = 5.0;
  static const double radiusDefault = 10.0;
  static const double radiusLarge = 20.0;
  static const double radiusExtraLarge = 30.0;
  static const double webMaxWidth = 1170;
  static const int messageInputLength = 250;
  static double get containerWidth => 1200.0;
  static const double containerWidthAppbar = 1235.0;
}

final appBarNormal = TextStyle(
    fontFamily: 'Poppins Regular',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: blackColor);

const smallHeadingMedium = TextStyle(
  fontFamily: 'Poppins Medium',
  fontWeight: FontWeight.w500,
  fontSize: 16,
);

final largeHeadingMedium = TextStyle(
  fontFamily: 'Poppins Medium',
  fontWeight: FontWeight.w700,
  fontSize: 20,
  color: blackColor,
);
final largeHeadingBlack = TextStyle(
  fontFamily: 'Poppins Black',
  fontWeight: FontWeight.w700,
  fontSize: 20,
  color: blackColor,
);

const appRegularText = TextStyle(
  fontFamily: 'Poppins Regular',
  fontWeight: FontWeight.normal,
  fontSize: 14,
);

const appRegularTextBold = TextStyle(
  fontFamily: 'Poppins Bold',
  fontWeight: FontWeight.bold,
  fontSize: 14,
);
const smallHeadingBold = TextStyle(
  fontFamily: 'Poppins Bold',
  fontWeight: FontWeight.bold,
  fontSize: 14,
);
const largeHeadingBold = TextStyle(
  fontFamily: 'Poppins Bold',
  fontWeight: FontWeight.bold,
  fontSize: 20,
);
const appSmallText = TextStyle(
  fontFamily: 'Poppins Medium',
  fontWeight: FontWeight.normal,
  fontSize: 12,
);

TextStyle heading1(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
    fontSize: 24,
    fontFamily: "Poppins Bold",
    color: notifires.getGrey2whiteColor,
  );
}

TextStyle heading2(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: "Poppins Bold",
      color: notifires.getGrey2whiteColor);
}

TextStyle heading3(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: "Poppins Bold",
      color: notifires.getGrey2whiteColor);
}

TextStyle regular2(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 14,
      fontFamily: "Poppins Regular",
      color: notifires.getGrey2whiteColor);
}

TextStyle regular(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 12,
      fontFamily: "Poppins Regular",
      color: notifires.getGrey2whiteColor);
}

TextStyle regularBlack(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 14,
      fontFamily: "Poppins Regular",
      color: notifires.getwhiteblackColor);
}

TextStyle regular3(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 16,
      fontFamily: "Poppins Regular",
      color: notifires.getGrey2whiteColor);
}

TextStyle boldstyle(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 16,
      fontFamily: "Poppins Bold",
      color: notifires.getGrey2whiteColor);
}

TextStyle heading1Grey1(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: "Poppins Bold",
    color: notifires.getGrey1whiteColor,
  );
}

TextStyle headingBlackBold(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300,
    fontFamily: "Poppins SemiBold",
    color: notifires.getwhiteblackColor,
  );
}

TextStyle headingBlack(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
    fontSize: 17,
    fontFamily: "Poppins Medium",
    color: notifires.getwhiteblackColor,
  );
}

TextStyle heading2Grey1(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
    fontSize: 17,
    fontFamily: "Poppins Medium",
    color: notifires.getGrey1whiteColor,
  );
}

TextStyle heading3Grey1(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return TextStyle(
      fontSize: 14,
      fontFamily: "Poppins Medium",
      fontWeight: FontWeight.w500,
      color: notifires.getGrey1whiteColor);
}

TextStyle jostMediumGrey1(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return GoogleFonts.jost(
    fontSize: 40,
    fontWeight: FontWeight.w500, // Use w500 for medium weight
    color: notifires.getGrey1whiteColor,
  );
}

TextStyle jostMediumGrey2(BuildContext context) {
  final notifires = Provider.of<ColorNotifires>(context);
  return GoogleFonts.jost(
    fontSize: 17,
    fontWeight: FontWeight.w500, // Use w500 for medium weight
    color: notifires.getGrey2whiteColor,
  );
}

TextStyle jostRegular(BuildContext context) {
  return GoogleFonts.jost(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Use w400 for regular weight
    color: footergreycolor2,
  );
}

TextStyle justmixed(BuildContext context) {
  return GoogleFonts.jost(
    fontSize: 12,
    color: justmixedwhiteColor,
  );
}
