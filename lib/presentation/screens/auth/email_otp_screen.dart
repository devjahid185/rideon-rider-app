import 'dart:async';

import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/email_otp_cubit.dart';

class EmailOtpScreen extends StatefulWidget {
  final String? otpValue;
  final String? email;
  final bool? loginWithSocialMedia;
  final bool? changeEmail;
  const EmailOtpScreen(
      {super.key,
      this.otpValue,
      this.email,
      this.loginWithSocialMedia,
      this.changeEmail});

  @override
  State<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends State<EmailOtpScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

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
    return Scaffold(
        backgroundColor: notifires.getbgcolor,
        body: BlocListener<EmailOtpCubit, EmailOtpState>(
          listener: (context, state) {
            if (state is EmailOtpLoading) {
              Widgets.showLoader(context);
            }
            if (state is OtpSuccessForChangeEmailSate) {
              Widgets.hideLoder(context);

              loginModel = state.loginModel;
              showToastMessage(loginModel?.message ?? "");

              goBack();
            } else if (state is ResendEmailOtpSuccess) {
              Widgets.hideLoder(context);

              textEditingOtpController.text = state.otp;
            } else if (state is EmailOtpFailed) {
              Widgets.hideLoder(context);

              showErrorToastMessage(state.error);
            }
          },
          child: Stack(
            children: [
              Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SvgPicture.asset("assets/images/vector_top.svg"),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 80,
                              ),
                              SizedBox(
                                height: 220,
                                child: SvgPicture.asset(
                                    "assets/images/otp_verfied_image.svg"),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Text("Verification".translate(context),
                                  style: heading1Grey1(context).copyWith(
                                      color: notifires.getGrey2whiteColor)),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                  "We have sent the code verification to"
                                      .translate(context),
                                  style: regular2(context)),
                              const SizedBox(height: 10),
                              Text(
                                  widget.email!.isNotEmpty
                                      ? widget.email ?? ""
                                      : "${widget.email}".translate(context),
                                  style:
                                      regular2(context).copyWith(fontSize: 18)),
                              const SizedBox(height: 20),
                              TextFormField(
                                style: regular3(context).copyWith(
                                    fontSize: 20,
                                    color: notifires.getGrey1whiteColor),
                                controller: textEditingOtpController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                onChanged: ((value) {}),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: grey5,
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    borderSide: BorderSide(color: grey5),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        Dimensions.radiusDefault),
                                    borderSide: BorderSide(color: grey5),
                                  ),
                                  hintText: "Enter OTP".translate(context),
                                  hintStyle: regular2(context),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: grey5)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(13),
                                      borderSide: BorderSide(color: grey5)),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
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
                                              style: regular3(context).copyWith(
                                                  color: notifires
                                                      .getGrey2whiteColor)),
                                          const SizedBox(width: 5),
                                          InkWell(
                                            onTap: () async {
                                              context
                                                  .read<EmailOtpCubit>()
                                                  .resendOtpForChangeEmail({
                                                "email": widget.email,
                                                "default_currency_code": "",
                                                "selected_currency_code": "",
                                              });

                                              startResendTimer();
                                              setState(() {
                                                _remainingTime = 15;
                                                _isResendEnabled = false;
                                              });
                                            },
                                            child: Text(
                                                "Resend Code"
                                                    .translate(context),
                                                style: regular2(context)
                                                    .copyWith(
                                                        color: Colors.black,
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
                                            "Resend code in".translate(context),
                                            style: regular3(context).copyWith(
                                                color: notifires
                                                    .getGrey2whiteColor),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text('00:$_remainingTime',
                                              style: regular2(context).copyWith(
                                                color: themeColor,
                                                fontSize: 16,
                                              ))
                                        ],
                                      ),
                                    ),
                              const SizedBox(
                                height: 80,
                              ),
                              CustomsButtons(
                                  onPressed: () {
                                    context
                                        .read<EmailOtpCubit>()
                                        .emailOtpVerifyForChangeEmail(
                                            widget.email ?? "",
                                            textEditingOtpController.text);
                                  },
                                  text: "Verify".translate(context),
                                  textColor: whiteColor,
                                  backgroundColor: themeColor),
                              const SizedBox(
                                height: 60,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Try again".translate(context),
                                    style: regular3(context).copyWith(
                                        color: notifires.getGrey2whiteColor),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  InkWell(
                                      onTap: () {
                                        // Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "Go Back".translate(context),
                                        style: boldstyle(context)
                                            .copyWith(color: themeColor),
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
          ),
        ));
  }
}


