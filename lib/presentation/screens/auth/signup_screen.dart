import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/screens/onboarding/language_select_screen.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/apple_login_cubit.dart';
import '../../cubits/auth/google_login_cubit.dart';
import '../../cubits/auth/signup_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/form_validations.dart';
import '../Account/static_screen.dart';
import '../Home/item_home_screen.dart';
import 'google_update_screen.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  TextEditingController textEditingSignUpControllerFirstName =
      TextEditingController();
  TextEditingController textEditingSignUpControllerEmail =
      TextEditingController();
  TextEditingController textEditingSingUpControllerlastName =
      TextEditingController();
  TextEditingController textEditingSingUpControllerPhoneNumber =
      TextEditingController();
  TextEditingController textEditingSignUpControllerPassword =
      TextEditingController();

  bool isChecked = false;
  String selectedCountryCode = "+1";
  String defaultCountry = "US";

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    context.read<SetCountryCubit>().reset();
    super.initState();
    isNumeric=false;
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return PopScope(
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
                BlocListener<AuthSignUpCubit, AuthSignUpState>(
                    listener: (context, state) {
                  if (state is SignUpLoading) {
                    Widgets.showLoader(context);
                  } else if (state is SignUpSuccess) {
                    Widgets.hideLoder(context);
                    context.read<AuthSignUpCubit>().resetState();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OtpScreen(
                                  number: state.loginModel.data!.phone,
                                  countryCode:
                                      state.loginModel.data!.phoneCountry,
                                  otpValue: state.loginModel.data!.otpValue,
                                  email: "",
                                  defaultCountry:
                                      state.loginModel.data!.defaultCountry,
                                  changeMobile: false,
                                  loginWithSocialMedia: false,
                                  routeString: "SignUp",
                                )));
                  } else if (state is SignUpFailure) {
                    Widgets.hideLoder(context);
                    showErrorToastMessage(state.error);
                  }
                }),
                BlocListener<GoogleLoginCubit, GoogleLoginState>(
                  listener: (context, state) {
                    if (state is GoogleLoginSucess) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ItemHomeScreen()));
                    } else if (state is AddPhoneNumberState) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GoogleUpdate(
                                    email: state.loginModel.data?.email ?? "",
                                  )));
                    } else if (state is GoogleLoginFailure) {
                      showErrorToastMessage(state.error);
                    }
                  },
                ),
                BlocListener<AppleLoginCubit, AppleLoginState>(
                  listener: (context, state) {
                    if (state is AppleLoginSuccess) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ItemHomeScreen()));
                    } else if (state is AddPhoneNumberAppleState) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoogleUpdate()));
                    } else if (state is AppleLoginFailure) {
                      closeLoading();
                      showErrorToastMessage(state.error);
                    }
                  },
                )
              ],
              child: Stack(
                children: [
                  Positioned(
                      left: 0,
                      top: 0,
                      child: SvgPicture.asset("assets/images/EllipseTop.svg",)),

                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: Dimensions.containerWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeLarge,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 130),
                                  commonlyUserLogo(),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Get Started".translate(context),
                                      style: heading1(context)),
                                  Text(
                                      "Create an account to continue."
                                          .translate(context),
                                      style: regular2(context).copyWith(
                                          color: notifires.getGrey3whiteColor)),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFieldAdvance(
                                    onTap: (){
                                      isNumeric=false;
                                      setState(() {

                                      });
                                    },
                                    inputAlignment: TextAlign.start,
                                    txt: "Name".translate(context),
                                    icons: Icon(
                                      Icons.person_2_outlined,
                                      color: blackColor,
                                    ),
                                    textEditingControllerCommon:
                                        textEditingSignUpControllerFirstName,
                                    inputType: TextInputType.name,
                                    validator: (value) {
                                      if (isValidName(value!)) {
                                        return null;
                                      } else {
                                        return "Please enter the name"
                                            .translate(context);
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  BlocBuilder<SetCountryCubit, SetCountryState>(
                                      builder: (context, state) {
                                    return IntelPhoneFieldRefs(
                                      onTap: (){
                                        isNumeric=true;
                                        setState(() {

                                        });
                                      },
                                      key: ValueKey(state.countryCode),
                                      defultcountry: state.countryCode,
                                      textEditingControllerCommons:
                                          textEditingSingUpControllerPhoneNumber,
                                      oncountryChanged: (number) {
                                        context.read<SetCountryCubit>().reset();
                                        textEditingSingUpControllerPhoneNumber
                                            .clear();
                                        context
                                            .read<SetCountryCubit>()
                                            .setCountry(
                                                dialCode: number.dialCode,
                                                countryCode: number.code);
                                      },
                           
                                      validator: (phoneNumber) {
                                        if (phoneNumber == null ||
                                            phoneNumber.number.isEmpty) {
                                          return "Please enter your phone number"
                                              .translate(context);
                                        }
                                        int expectedLength = phoneLengths[
                                                phoneNumber.countryISOCode] ??
                                            10;
                                        if (phoneNumber.number.length !=
                                            expectedLength) {
                                          return "${"Phone number must be".translate(context)} $expectedLength ${"digits".translate(context)}";
                                        }
                                        return null;
                                      },
                                    );
                                  }),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  TextFieldAdvance(
                                    onTap: (){
                                      isNumeric=false;
                                      setState(() {

                                      });
                                    },
                                    inputAlignment: TextAlign.start,
                                    txt: "Email".translate(context),
                                    icons: Icon(
                                      Icons.mail_outline_outlined,
                                      color: blackColor,
                                    ),
                                    textEditingControllerCommon:
                                        textEditingSignUpControllerEmail,
                                    inputType: TextInputType.emailAddress,
                                    validator: (value) {
                                      return validateEmail(value!, context);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints:
                                            const BoxConstraints.expand(
                                                width: 33, height: 40),
                                        color: Colors.transparent,
                                        padding:
                                            const EdgeInsets.only(right: 5),
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: Checkbox(
                                            activeColor: themeColor,
                                            focusColor: whiteColor,
                                            value: isChecked,
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                isChecked = newValue!;
                                              });
                                            },
                                            checkColor: whiteColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      Dimensions.radiusSmall),
                                            ),
                                            side: BorderSide(
                                                color: notifires
                                                    .getGrey3whiteColor,
                                                width: 2.0),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              useRootNavigator: true,
                                              backgroundColor: notifires.getbgcolor,
                                              isScrollControlled: true,
                                              useSafeArea: true,
                                              context: context,
                                              builder: (BuildContext context) {

                                                return  const StaticScreen(
                                                    data: "Terms and Conditions");
                                              },
                                            );
                                          },
                                          child: Text.rich(TextSpan(
                                              text:
                                                  "By creating an account, you agree to our ".translate(context)+"\n"
                                                      .translate(context),
                                              style: regular3(context)
                                                  .copyWith(fontSize: 14),
                                              children: [
                                                TextSpan(
                                                    text:
                                                    "\n${"Terms and Condition"
                                                        .translate(context)}",
                                                    style: heading3Grey1(
                                                            context)
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight.w200,
                                                            color: themeColor,
                                                            fontSize: 14))
                                              ])),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 50),
                                  CustomsButtons(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          if (isChecked == false) {
                                            showErrorToastMessage(
                                                "Please select the terms and condition."
                                                    .translate(context));
                                            return;
                                          }
                                          if (textEditingSingUpControllerPhoneNumber
                                              .text.isEmpty) {
                                            showErrorToastMessage(
                                                "Fill valid mobile number"
                                                    .translate(context));
                                            return;
                                          }
                                          context
                                              .read<AuthSignUpCubit>()
                                              .signUp(
                                                context: context,
                                                name:
                                                    textEditingSignUpControllerFirstName
                                                        .text,
                                                phoneCountry: context
                                                        .read<SetCountryCubit>()
                                                        .state
                                                        .dialCode
                                                        .startsWith("+")
                                                    ? context
                                                        .read<SetCountryCubit>()
                                                        .state
                                                        .dialCode
                                                    : "+${context.read<SetCountryCubit>().state.dialCode}",
                                                defaultCountry: context
                                                    .read<SetCountryCubit>()
                                                    .state
                                                    .countryCode,
                                                phoneNumber:
                                                    textEditingSingUpControllerPhoneNumber
                                                        .text,
                                                email:
                                                    textEditingSignUpControllerEmail
                                                        .text,
                                              );
                                        }
                                      },
                                      textColor: whiteColor,
                                      text: "Sign up",
                                      backgroundColor: themeColor),
                                  const SizedBox(
                                    height: 40,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                          height: 2,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.08,
                                          color: notifires.getGrey4whiteColor),
                                      const SizedBox(width: 10),
                                      Text(
                                        "or Sign up with".translate(context),
                                        style: regular3(context),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                          height: 1.5,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.08,
                                          color: notifires.getGrey4whiteColor),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            context.read<GoogleLoginCubit>().googleLogin(context);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: themeColor.withValues(alpha: .3),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: SvgPicture.asset("assets/images/google_icon.svg"),
                                          ),
                                        ),
                                        if (Platform.isIOS) const SizedBox(width: 25),
                                        if (Platform.isIOS)
                                          InkWell(
                                            onTap: () {
                                              context.read<AppleLoginCubit>().appleLogin(context);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: themeColor.withValues(alpha: .3),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: SvgPicture.asset("assets/images/apple_icon.svg"),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 50,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Already have an account?"
                                            .translate(context),
                                        style: regular3(context).copyWith(
                                            color:
                                                notifires.getGrey2whiteColor),
                                      ),
                                      const SizedBox(width: 5),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LoginScreen()));
                                        },
                                        child: Text(
                                          "Sign in".translate(context),
                                          style: heading1(context).copyWith(
                                            color: blackColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 250),
                                ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                  top: 70,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      languageButton(onTap: (){

                        goTo(const SelectLanguageScreen(isBack: true,));
                      },),
                    ],
                  )),
                  const SizedBox(height: 40),
                ],
              ))),
    );
  }
}


