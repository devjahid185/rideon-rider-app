import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../../app/route_settings.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/change_phone_number_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import 'otp_screen.dart';

class PhoneUpdateScreen extends StatefulWidget {
  final bool? fromProfile;
  final String phone;
  const PhoneUpdateScreen({super.key, this.fromProfile, required this.phone});
  @override
  State<PhoneUpdateScreen> createState() => _PhoneUpdateScreenState();
}

class _PhoneUpdateScreenState extends State<PhoneUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController phoneText = TextEditingController();

  @override
  void initState() {
    super.initState();
    isNumeric = false;
    phoneText.text = widget.phone;
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return Align(
      alignment: Alignment.center,
      child: Form(
        key: _formKey,
        child: Scaffold(
          bottomSheet: isNumeric==true&& Platform.isIOS?KeyboardDoneButton(
            onTap: () {
              setState(() {
                isNumeric = false;
              });
            },
          ):null,
          backgroundColor: notifires.getbgcolor,
          body: BlocListener<ChangePhoneCubits, ChangePhoneState>(
            listener: (context, state) {
              if (state is ChangePhoneLoading) {
                Widgets.showLoader(context);
              } else if (state is ChangePhoneSuccess) {
                Widgets.hideLoder(context);
                goToWithReplacement(OtpScreen(
                  number: phoneText.text,
                  otpValue: "${state.checkMobileModel.data!.otp}",
                  countryCode: context.read<SetCountryCubit>().state.dialCode,
                  email: "",
                  changeMobile: true,
                ));
              } else if (state is ChangePhoneFailure) {
                Widgets.hideLoder(context);

                showErrorToastMessage(state.error);
              }
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge,
                    vertical: Dimensions.paddingSizeExtraLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 120,
                    ),
                    SvgPicture.asset("assets/images/forgotpass.svg"),
                    const SizedBox(height: 30),
                    Text(
                      "Change Phone Number".translate(context),
                      style: heading1(context),
                    ),
                    const SizedBox(height: 30),
                    BlocBuilder<SetCountryCubit, SetCountryState>(
                      builder: (context, state) {
                        return IntelPhoneFieldRefs(
                          onTap: (){
                            isNumeric=true;
                            setState(() {

                            });
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          defultcountry: state.countryCode,
                          selectedcountry: state.dialCode,
                          textEditingControllerCommons: phoneText,
                          oncountryChanged: (number) {
                            context.read<SetCountryCubit>().setCountry(
                                  dialCode: number.dialCode,
                                  countryCode: number.code,
                                );
                            phoneText.clear();
                          },
                          validator: (phoneNumber) {
                            if (phoneNumber == null ||
                                phoneNumber.number.isEmpty) {
                              return "Please enter your phone number"
                                  .translate(context);
                            }
                            int expectedLength =
                                phoneLengths[phoneNumber.countryISOCode] ?? 10;
                            if (phoneNumber.number.length != expectedLength) {
                              return "${"Phone number must be".translate(context)} $expectedLength ${"digits".translate(context)}";
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 35),
                    CustomsButtons(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<ChangePhoneCubits>().changePhone(
                                phone: phoneText.text,
                                phoneCountry: context
                                    .read<SetCountryCubit>()
                                    .state
                                    .dialCode,
                                defaultCuntry: context
                                    .read<SetCountryCubit>()
                                    .state
                                    .countryCode);
                          }
                        },
                        text: "Submit".translate(context),
                        textColor: whiteColor,
                        backgroundColor: themeColor),
                    const SizedBox(height: 100),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Try again".translate(context),
                          style: regular3(context)
                              .copyWith(color: notifires.getGrey2whiteColor),
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
      ),
    );
  }
}


