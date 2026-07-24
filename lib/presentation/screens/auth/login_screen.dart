import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/screens/Auth/signup_screen.dart';
import 'package:ride_on/presentation/screens/onboarding/language_select_screen.dart';
import '../../../core/extensions/workspace.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/apple_login_cubit.dart';
import '../../cubits/auth/google_login_cubit.dart';
import '../../cubits/auth/login_cubit.dart';
import '../../cubits/auth/user_authenticate_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../Home/item_home_screen.dart';
import 'google_update_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController textEditingLoginControllerPhoneNumber =
      TextEditingController();
  TextEditingController textEditingLoginControllerPassword =
      TextEditingController();

  bool isChecked = false;

  final _formKey = GlobalKey<FormState>();
  String selectedCountryCode = "+1";
  String defaultCountry = "US";

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
                BlocListener<AuthLoginCubit, AuthLoginState>(
                    listener: (context, state) {
                  if (state is LoginLoading) {
                    Widgets.showLoader(context);
                  } else if (state is LoginSuccess) {
                    Widgets.hideLoder(context);
                    context.read<AuthLoginCubit>().resetState();

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OtpScreen(
                                  number: textEditingLoginControllerPhoneNumber
                                      .text,
                                  countryCode:
                                      state.loginModel.data?.phoneCountry!,
                                  defaultCountry: defaultCountry,
                                  routeString: "Login",
                                  otpValue: state.loginModel.data!.resetToken!,
                                )));
                  } else if (state is LoginFailure) {
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
                                  const SizedBox(height: 150),
                                  commonlyUserLogo(),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text("Sign in".translate(context),
                                      style: heading1(context)),
                                  Text("Welcome Back".translate(context),
                                      style: regular2(context).copyWith(
                                          color: notifires.getGrey3whiteColor)),
                                  const SizedBox(
                                    height: 20,
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
                                      onChanged: (value) {

                                        final countryCode = value?.countryISOCode ?? '';
                                        String number = value?.number ?? '';

                                        if (countryCode == 'MY' && number.startsWith('0')) {

                                          number = number.substring(1);
                                          textEditingLoginControllerPhoneNumber.text = number;
                                          textEditingLoginControllerPhoneNumber.selection = TextSelection.fromPosition(
                                            TextPosition(offset: number.length),
                                          );
                                        }
                                        return null;


                                      },
                                      key: ValueKey(state.countryCode),
                                      defultcountry: state.countryCode,
                                      textEditingControllerCommons:
                                          textEditingLoginControllerPhoneNumber,
                                      oncountryChanged: (number) {
                                        context.read<SetCountryCubit>().reset();
                                        textEditingLoginControllerPhoneNumber
                                            .clear();

                                        context
                                            .read<SetCountryCubit>()
                                            .setCountry(
                                                dialCode: number.dialCode,
                                                countryCode: number.code);
                                      },
                                      hintText: "Phone no".translate(context),

                                      validator: (phoneNumber) {
                                        if (phoneNumber == null || phoneNumber.number.isEmpty) {
                                          return "Please enter your phone number".translate(context);
                                        }

                                        final countryCode = phoneNumber.countryISOCode;
                                        final expectedLength = phoneLengths[countryCode] ?? 10;

                                        String cleanedNumber = phoneNumber.number.replaceAll(RegExp(r'\D'), '');
                                        if (cleanedNumber.startsWith('0')) {
                                          cleanedNumber = cleanedNumber.substring(1);
                                        }



                                        if (cleanedNumber.length != expectedLength) {
                                          return "${"Phone number must be".translate(context)} $expectedLength ${"digits".translate(context)}";
                                        }

                                        return null;
                                      },
                                    );
                                  }),
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const SizedBox(height: 20),
                                  CustomsButtons(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          if (textEditingLoginControllerPhoneNumber
                                              .text.isEmpty) {
                                            showErrorToastMessage(
                                                "Please enter the phone number"
                                                    .translate(context));
                                            return;
                                          }
                                          context.read<AuthLoginCubit>().login(
                                              context: context,
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
                                              phoneNumber:
                                                  textEditingLoginControllerPhoneNumber
                                                      .text);
                                        }
                                      },
                                      textColor: whiteColor,
                                      text: "Sign in",
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
                                        "or Sign in with".translate(context),
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
                                    height: 30,
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
                                        "Don't have an account?"
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
                                                      const SignUp()));
                                        },
                                        child: Text(
                                          "Sign Up".translate(context),
                                          style:
                                              heading3Grey1(context).copyWith(
                                            color: blackColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 300)
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
                ],
              ))),
    );
  }
}


