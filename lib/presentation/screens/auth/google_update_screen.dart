import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/google_login_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class GoogleUpdate extends StatefulWidget {
  final String? email;
  const GoogleUpdate({super.key, this.email});

  @override
  State<GoogleUpdate> createState() => _GoogleUpdateState();
}

class _GoogleUpdateState extends State<GoogleUpdate> {
  final _formKey = GlobalKey<FormState>();
  DateTime birthday = DateTime(1997, 3, 5);

  TextEditingController textEditingPhoneUpdateController =
      TextEditingController();



  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: notifires.getbgcolor,
        appBar: CustomAppBars(
          onBackButtonPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          title: "Update Personal Info".translate(context),
          backgroundColor: whiteColor,
          iconColor: notifires.getblackblue,
          titleColor: notifires.getblackblue,
        ),
        body: MultiBlocListener(
            listeners: [
              BlocListener<GoogleLoginCubit, GoogleLoginState>(
                listener: (context, state) {
                  if (state is GoogleUpdatePhoneSuccess) {
                    goTo(OtpScreen(
                      routeString: "",
                      number: textEditingPhoneUpdateController.text,
                      countryCode:
                      state.checkMobileModel.data?.phoneCountry!,
                      otpValue: "${state.checkMobileModel.data!.otp}",
                      defaultCountry: context
                          .read<SetCountryCubit>()
                          .state
                          .countryCode,
                      email: widget.email ?? "",
                      changeMobile: true,
                      loginWithSocialMedia: true,
                    ));

                  } else if (state is GoogleCheckFailureState) {
                    showErrorToastMessage(state.error);
                  }
                },
              ),
            ],
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 40,
                      ),
                      Text("Mobile Number".translate(context),
                          style: headingBlack(context)),
                      const SizedBox(
                        height: 20,
                      ),
                      BlocBuilder<SetCountryCubit, SetCountryState>(
                          builder: (context, state) {
                        return IntelPhoneFieldRefs(
                          key: ValueKey(state.countryCode),
                          validator: (phoneNumber) {
                            if (phoneNumber == null ||
                                phoneNumber.number.isEmpty) {
                              return "Please enter your phone number";
                            }

                            int expectedLength =
                                phoneLengths[phoneNumber.countryISOCode] ?? 10;
                            if (phoneNumber.number.length != expectedLength) {
                              return "${"Phone number must be".translate(context)} $expectedLength ${"digits".translate(context)}";
                            }
                            return null;
                          },
                          defultcountry: state.countryCode,
                          textEditingControllerCommons:
                              textEditingPhoneUpdateController,
                          selectedcountry: selectedCountry,
                          oncountryChanged: (value) {
                            context.read<SetCountryCubit>().reset();
                            textEditingPhoneUpdateController.clear();
                            context.read<SetCountryCubit>().setCountry(
                                dialCode: value.dialCode,
                                countryCode: value.code);

                            setState(() {

                            });
                          },
                          onChanged: (value) {
                            int expectedLength =
                                phoneLengths[defaultCountry] ?? 10;

                            if (value!.number.length > expectedLength) {
                              textEditingPhoneUpdateController.text =
                                  value.number.substring(0, expectedLength);
                              textEditingPhoneUpdateController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                    offset: textEditingPhoneUpdateController
                                        .text.length),
                              );
                            }
                            return null;
                          },
                        );
                      }),
                      const SizedBox(
                        height: 40,
                      ),
                      CustomsButtons(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              loginWithSocialMedia = true;
                              context.read<GoogleLoginCubit>().updatePhonePhone(
                                  context,
                                  socialEmail: widget.email ?? "",
                                  phone: textEditingPhoneUpdateController.text,
                                  countryCode: context
                                          .read<SetCountryCubit>()
                                          .state
                                          .dialCode
                                          .startsWith("+")
                                      ? context
                                          .read<SetCountryCubit>()
                                          .state
                                          .dialCode
                                      : "+${context.read<SetCountryCubit>().state.dialCode}",
                                  defaultCode: context
                                      .read<SetCountryCubit>()
                                      .state
                                      .countryCode);
                            }
                          },
                          text: "Update".translate(context),
                          textColor: whiteColor,
                          backgroundColor: themeColor),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }
}


