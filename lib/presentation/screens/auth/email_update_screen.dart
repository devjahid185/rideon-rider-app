import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../../app/route_settings.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';
import '../../cubits/auth/change_email_cubit.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/form_validations.dart';
import 'email_otp_screen.dart';

class EmailUpdateScreen extends StatefulWidget {
  const EmailUpdateScreen({super.key});

  @override
  State<EmailUpdateScreen> createState() => _EmailUpdateScreenState();
}

class _EmailUpdateScreenState extends State<EmailUpdateScreen> {
  TextEditingController emailText = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (loginModel != null) {
      if (loginModel!.data!.email != null) {
        emailText.text = loginModel!.data!.email!;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      body: BlocListener<ChangeEmailCubits, ChangeEmailState>(
          listener: (context, state) {
            if (state is ChangeEmailLoading) {
              Widgets.showLoader(context);
            } else if (state is ChangeEmailSuccess) {
              Widgets.hideLoder(context);

              goToWithReplacement(EmailOtpScreen(
                otpValue: state.checkEmail.data!.otp!,
                email: emailText.text,
                changeEmail: true,
              ));
            } else if (state is ChangeEmailFailure) {
              Widgets.hideLoder(context);

              showErrorToastMessage(state.error);
            }
          },
          child: Stack(
            children: [
              Positioned(
                  right: 0,
                  top: 0,
                  child: SvgPicture.asset(
                    "assets/images/vector_top.svg",
                  )),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
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
                          "Change Email ID".translate(context),
                          style: heading1(context),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Enter your email address to update it effortlessly"
                              .translate(context),
                          style: regular2(context),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Form(
                          key: formKey,
                          child: Column(
                            children: [
                              TextFieldAdvance(
                                inputAlignment: TextAlign.start,
                                txt: "Enter Your Email".translate(context),
                                textEditingControllerCommon: emailText,
                                inputType: TextInputType.emailAddress,
                                validator: (value) {
                                  return validateEmail(value!, context);
                                },
                                icons: Icon(Icons.mail,
                                    color: notifires.getwhiteblackColor
                                        .withOpacity(0.4)),
                              ),
                              const SizedBox(height: 35),
                              CustomsButtons(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      context
                                          .read<ChangeEmailCubits>()
                                          .changeEmail(emailText.text);
                                    }
                                  },
                                  text: "Submit".translate(context),
                                  textColor: whiteColor,
                                  backgroundColor: themeColor),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
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
                                  navigatorKey.currentState!.pop();
                                },
                                child: Text(
                                  "Go Back".translate(context),
                                  style: boldstyle(context)
                                      .copyWith(color: blackColor),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }
}


