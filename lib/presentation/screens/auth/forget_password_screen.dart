import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/form_validations.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  TextEditingController textEditingForgetPasswordControllerEmail =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    return Scaffold(
        backgroundColor: notifires.getbgcolor,
        body: Stack(
          children: [
            Stack(
              children: [
                Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset("assets/images/vector_top.svg")),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: Dimensions.containerWidth,
                        child: Form(
                            key: _formKey,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeLarge),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 120,
                                  ),
                                  SvgPicture.asset(
                                    "assets/images/forgotpass.svg",
                                  ),
                                  const SizedBox(height: 30),
                                  Text(
                                    "Reset Password".translate(context),
                                    style: heading2Grey1(context)
                                        .copyWith(fontSize: 24),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Enter the email address associated with your account,and we'll email you a link to reset your password."
                                        .translate(context),
                                    style: regular2(context),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(
                                    height: 50,
                                  ),
                                  TextFieldAdvance(
                                    inputAlignment: TextAlign.start,
                                    txt: "Email".translate(context),
                                    icons: Icon(
                                      Icons.mail,
                                      color: notifires.getwhiteblackColor
                                          .withOpacity(0.4),
                                    ),
                                    textEditingControllerCommon:
                                        textEditingForgetPasswordControllerEmail,
                                    inputType: TextInputType.emailAddress,
                                    validator: (value) {
                                      return validateEmail(value!, context);
                                    },
                                  ),
                                  const SizedBox(height: 50),
                                  CustomsButtons(
                                      onPressed: () {},
                                      text: "Send Otp".translate(context),
                                      textColor: whiteColor,
                                      backgroundColor: themeColor),
                                  const SizedBox(height: 80),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Try again".translate(context),
                                        style: regular3(context).copyWith(
                                            color:
                                                notifires.getGrey2whiteColor),
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Go Back".translate(context),
                                            style: boldstyle(context)
                                                .copyWith(color: blackColor),
                                          )),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 70,
                                  )
                                ],
                              ),
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }
}


