import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ride_on/app/route_settings.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/otp_verify_cubit.dart';
import '../../cubits/auth/resend_otp_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../Home/item_home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String? number;
  final String? countryCode;
  final String? otpValue;
  final String? email;
  final bool? changeMobile;
  final bool? changeEmail;
  final String? defaultCountry;
  final String? routeString;
  final bool? loginWithSocialMedia;

  const OtpScreen(
      {super.key,
      this.number,
      this.routeString,
      this.countryCode,
      this.otpValue,
      this.email,
      this.changeMobile,
      this.changeEmail,
      this.defaultCountry,
      this.loginWithSocialMedia});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    isNumeric=false;

    Future.delayed(
      const Duration(seconds: 1),
      () {
        textEditingOtpController.text = widget.otpValue!;
      },
    );
    startResendTimer();
  }

  int _remainingTime = 15;
  bool _isResendEnabled = true;
  late Timer _timer;

  void startResendTimer() {
    setState(() {
      _isResendEnabled = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer.cancel();
          _isResendEnabled = true;
          _remainingTime = 0;
        }
      });
    });
  }

  TextEditingController textEditingOtpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: Dimensions.containerWidth,
        child: PopScope(
          canPop: false,
          child: Scaffold(
              bottomSheet: isNumeric==true&& Platform.isIOS?KeyboardDoneButton(
                onTap: () {
                  setState(() {
                    isNumeric = false;
                  });
                },
              ):null,
              resizeToAvoidBottomInset: false,
              backgroundColor: notifires.getbgcolor,
              body: MultiBlocListener(
                  listeners: [
                    BlocListener<AuthUserAuthenticateCubit,
                        AuthUserAuthenticateState>(listener: (context, state) {
                      if (state is UserLoading) {
                        Widgets.showLoader(context);
                      } else if (state is UserSucesss) {
                        Widgets.hideLoder(context);


                        goToWithClear(const ItemHomeScreen());
                      } else if (state is UserFailure) {
                        Widgets.hideLoder(context);
                        if (state.error.isNotEmpty) {
                          showErrorToastMessage(state.error);
                        }
                      }
                    }),
                    BlocListener<AuthOtpVerifyCubit, OtpVerifyState>(
                        listener: (context, state) {
                      if (state is OtpLoading) {
                        Widgets.showLoader(context);
                      } else if (state is OtpSuccess) {
                        Widgets.hideLoder(context);

                        goToWithClear(const ItemHomeScreen());

                      } else if (state is OtpFailure) {
                        Widgets.hideLoder(context);
                        if (state.error.isNotEmpty) {
                          showErrorToastMessage(state.error);
                        }
                      }
                    }),
                    BlocListener<AuthResendOtpCubit, ResendOtpState>(
                        listener: (context, state) {
                      if (state is ResendOtpLoading) {
                        Widgets.showLoader(context);
                      } else if (state is ResendOtpSuccess) {
                        Widgets.hideLoder(context);
                        if (state.otpValue!.isNotEmpty) {
                          textEditingOtpController.text = state.otpValue!;
                        }
                      } else if (state is ResendOtpFailure) {
                        Widgets.hideLoder(context);
                        showErrorToastMessage(state.error);
                      }
                    }),
                  ],
                  child: Stack(
                    children: [
                      Stack(
                        children: [
                          Positioned(
                              right: 0,
                              top: 0,
                              child: SvgPicture.asset(
                                "assets/images/vector_top.svg",
                               )),
                          Positioned(
                            bottom: -20,
                            left: 0,
                            child: IgnorePointer(
                              child: SvgPicture.asset(
                                "assets/images/vector_bottom.svg",

                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            top: 0,
                            right: 0,
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeLarge,
                                    vertical: Dimensions.paddingSizeExtraLarge),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 130,
                                      ),
                                      SizedBox(
                                        height: 160,
                                        child: Image.asset(
                                            "assets/images/verification.png"),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text("Verification".translate(context),
                                          style: heading1(context)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                          "Verification code was sent to your Phone number"
                                              .translate(context),
                                          style: regular(context)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                          "${widget.countryCode} ${widget.number}",
                                          style: regular3(context).copyWith(
                                              fontWeight: FontWeight.w100)),

                                      const SizedBox(height: 20),
                                      TextFormField(
                                        onTap: (){
                                          isNumeric=true;
                                          setState(() {

                                          });
                                        },
                                        style: regular3(context).copyWith(
                                            fontSize: 20,
                                            color:
                                                notifires.getGrey2whiteColor),
                                        controller: textEditingOtpController,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        onChanged: ((value) {}),
                                        decoration: InputDecoration(
                                          // prefixIcon: Icon(Icons.call_outlined),
                                          filled: true,
                                          fillColor: notifires.getBoxColor,
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusDefault),
                                            borderSide: BorderSide(
                                                color: notifires
                                                    .getGrey6whiteColor),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                Dimensions.radiusDefault),
                                            borderSide: BorderSide(
                                                color: notifires
                                                    .getGrey6whiteColor),
                                          ),
                                          hintText: "Enter OTP",
                                          hintStyle: regular(context),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              borderSide: BorderSide(
                                                  color: notifires
                                                      .getGrey6whiteColor)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                              borderSide: BorderSide(
                                                  color: notifires
                                                      .getGrey6whiteColor)),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _isResendEnabled
                                          ? SizedBox(
                                        height: 22,
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                "Didn't receive code?"
                                                    .translate(context),
                                                style: regular3(context)
                                                    .copyWith(
                                                    color: notifires
                                                        .getGrey2whiteColor)),
                                            const SizedBox(width: 5),
                                            InkWell(
                                              onTap: () async {
                                                startResendTimer();
                                                setState(() {
                                                  _remainingTime = 15;
                                                  _isResendEnabled =
                                                  false;
                                                });
                                                context
                                                    .read<
                                                    AuthResendOtpCubit>()
                                                    .resendOtp(
                                                  phone:
                                                  widget.number,
                                                  phoneCountry: widget
                                                      .countryCode!
                                                      .startsWith(
                                                      "+")
                                                      ? widget
                                                      .countryCode!
                                                      : "+${widget.countryCode!}",
                                                );
                                              },
                                              child: Text(
                                                  "Resend"
                                                      .translate(context),
                                                  style: regular2(context)
                                                      .copyWith(
                                                      color:
                                                      blackColor,
                                                      fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                      )
                                          : SizedBox(
                                        height: 22,
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Resend code in"
                                                  .translate(context),
                                              style: regular3(context)
                                                  .copyWith(
                                                  color: notifires
                                                      .getGrey2whiteColor),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text('00:$_remainingTime',
                                                style: regular2(context)
                                                    .copyWith(
                                                  color: blackColor,
                                                  fontSize: 16,
                                                ))
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 30,
                                      ),
                                      CustomsButtons(
                                          textColor: whiteColor,
                                          onPressed: () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              if (widget.routeString ==
                                                  "Login") {
                                                context
                                                    .read<
                                                        AuthUserAuthenticateCubit>()
                                                    .userAuthenticate(
                                                        context: context,
                                                        phoneNumber:
                                                            widget.number!,
                                                        phoneCountry: widget
                                                                .countryCode!
                                                                .startsWith("+")
                                                            ? widget
                                                                .countryCode!
                                                            : "+${widget.countryCode!}",
                                                        otpValue:
                                                            textEditingOtpController
                                                                .text);
                                              } else {
                                                context
                                                    .read<AuthOtpVerifyCubit>()
                                                    .otpVerification(
                                                        context: context,
                                                        phone: widget.number,
                                                        otpValue:
                                                            textEditingOtpController
                                                                .text,
                                                        countryCode: widget
                                                                .countryCode!
                                                                .startsWith("+")
                                                            ? widget
                                                                .countryCode!
                                                            : "+${widget.countryCode!}",
                                                        email: widget.email,
                                                        changeEmail:
                                                            widget.changeEmail,
                                                        changeMobile:
                                                            widget.changeMobile,
                                                        defaultCountry: widget
                                                            .defaultCountry,
                                                        loginWithGoogle: widget
                                                            .loginWithSocialMedia);
                                              }
                                            }
                                          },
                                          text: "Continue",
                                          backgroundColor: themeColor),
                                      const SizedBox(
                                        height: 30,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Try again".translate(context),
                                            style: regular3(context).copyWith(
                                                color: notifires
                                                    .getGrey2whiteColor),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          InkWell(
                                              onTap: () {
                                                goBack();
                                              },
                                              child: Text(
                                                "Go Back".translate(context),
                                                style: boldstyle(context)
                                                    .copyWith(
                                                        color: themeColor),
                                              )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ))),
        ),
      ),
    );
  }
}


