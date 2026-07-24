import 'dart:convert';
import 'dart:io';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/login_data.dart' as logmod;

import 'package:ride_on/core/services/data_store.dart';

import 'package:ride_on/core/extensions/workspace.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ride_on/presentation/cubits/auth/user_authenticate_cubit.dart';

import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../cubits/auth/email_otp_cubit.dart';
import '../../cubits/book_ride_cubit.dart';
import '../../cubits/profile/edit_profile_cubit.dart';
import '../../cubits/realtime/update_ride_request_parameter.dart';
import '../../widgets/custom_text_form_field.dart';
import '../Auth/email_update_screen.dart';
import '../Auth/phone_update_screen.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {

  File? image;
  final picker = ImagePicker();
  GlobalKey buttonKey = GlobalKey();

  TextEditingController textEditingEditProfileNameController =
      TextEditingController();
  TextEditingController textEditingEditProfileEmailController =
      TextEditingController();
  TextEditingController textEditingEditProfileNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    textEditingEditProfileNameController.text =
        loginModel?.data?.firstName ?? "";

    textEditingEditProfileNumberController.text = loginModel?.data?.phone ?? "";
    textEditingEditProfileEmailController.text = loginModel?.data?.email ?? "";
    context.read<SetCountryCubit>().setCountry(dialCode: loginModel?.data?.phoneCountry??"+1", countryCode: loginModel?.data?.defaultCountry??"US");


  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final base64Img = await compressAndUploadImage(pickedFile.path);
      setState(() {
        image = File(pickedFile.path);
      });
           // ignore_for_file: use_build_context_synchronously
      context.read<UpdateProfileCubit>().uploadProfileImage(postData: {
        "profile_image": base64Img,
      });
    }
  }

  List<String> optionsList = ["male", "female", "others"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: CustomAppBarNew(
        title: "Edit Profile",
        onBackTap: () {
          goBack();
        },
      ),
      body: BlocBuilder<UpdateProfileCubit, UpdateProfileState>(
          builder: (context, state) {
        if (state is UpdateProfileLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Widgets.showLoader(context);
          });
        } else if (state is UpdateProfileSuccess) {
          Widgets.hideLoder(context);
          loginModel = logmod.LoginModel(
              data: logmod.Data.fromJson(state.loginModel.data!.toJson()));
          loginModel = loginModel;
          UserData userObj = UserData();
          userObj.saveLoginData("UserData", jsonEncode(loginModel!.toJson()));
          context.read<UpdateProfileCubit>().clear();
          context
              .read<NameCubit>()
              .updateName("${state.loginModel.data!.firstName}");

          showToastMessage(state.loginModel.message ?? "");
        } else if (state is UpdateProfileImageSuccess) {
          Widgets.hideLoder(context);

          loginModel!.data!.profileImageSetter = state.imageUrl;
          myImage = state.imageUrl;
          context
              .read<BookRideRealTimeDataBaseCubit>()
              .updateUserImageUrl(userImageUrl: state.imageUrl);

          context
              .read<UpdateRideRequestParameterCubit>()
              .updateFirebaseUserParameter(
                  rideId: context
                      .read<BookRideRealTimeDataBaseCubit>()
                      .state
                      .rideId,
                  userParameter: {"userImageUrl": state.imageUrl});

          context.read<MyImageCubit>().updateMyImage(myImage);
          UserData userObj = UserData();
          userObj.saveLoginData("UserData", jsonEncode(loginModel!.toJson()));
        } else if (state is UpdateProfileFailed) {
          Widgets.hideLoder(context);

          showErrorToastMessage(state.error);
          context.read<UpdateProfileCubit>().clear();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        myImage.isNotEmpty
                            ? Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: ClipOval(child: myNetworkImage(myImage)),
                              )
                            : Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: grey6,
                                ),
                                child: Icon(
                                  CupertinoIcons.profile_circled,
                                  size: 110,
                                  color: themeColor,
                                ),
                              ),
                        GestureDetector(
                          key: buttonKey,
                          onTap: () {
                            getButtonPosition(buttonKey);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: blackColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    TextFieldAdvance(
                        icons: Icon(Icons.person_2_outlined,
                            color: notifires.getGrey2whiteColor),
                        txt: "Enter Your Name".translate(context),
                        textEditingControllerCommon:
                            textEditingEditProfileNameController,
                        inputType: TextInputType.name,
                        inputAlignment: TextAlign.start),
                    const SizedBox(height: 20),
                    BlocBuilder<EmailOtpCubit, EmailOtpState>(
                        builder: (context, state) {
                      if (state is OtpSuccessForChangeEmailSate) {
                        textEditingEditProfileEmailController.text =
                            state.loginModel.data?.email ?? "";
                        context
                            .read<EmailCubit>()
                            .updateEmail(state.loginModel.data?.email ?? "");
                      }
                      return Stack(
                        children: [
                          TextFieldAdvance(
                              icons: Icon(Icons.email_outlined,
                                  color: notifires.getGrey2whiteColor),
                              txt: "Enter Your Email".translate(context),
                              readOnly: true,
                              textEditingControllerCommon:
                                  textEditingEditProfileEmailController,
                              inputType: TextInputType.name,
                              inputAlignment: TextAlign.start),
                          Positioned(
                              right: 10,
                              top: 0,
                              bottom: 0,
                              left: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        goTo(const EmailUpdateScreen());
                                      },
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                              color: themeColor.withValues(alpha: .7),
                                              height: 30,
                                              width: 30,
                                              child:   const Icon(
                                                Icons.mode,
                                                color: Colors.white,
                                                size: 17,
                                              )),
                                        ),
                                      )),
                                ],
                              ))
                        ],
                      );
                    }),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        TextFieldAdvance(
                            icons: Icon(Icons.call_outlined,
                                color: notifires.getGrey2whiteColor),
                            txt: "Enter Your Mobile".translate(context),
                            readOnly: true,
                            textEditingControllerCommon:
                                textEditingEditProfileNumberController,
                            inputType: TextInputType.name,
                            inputAlignment: TextAlign.start),
                        Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            left: 10,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                    onTap: () {
                                      context.read<SetCountryCubit>().setCountry(dialCode: loginModel?.data?.phoneCountry??"+1", countryCode: loginModel?.data?.defaultCountry??"US");

                                      goTo(PhoneUpdateScreen(
                                          phone:
                                              textEditingEditProfileNumberController
                                                  .text));
                                    },
                                    child: Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                            color: themeColor.withValues(alpha: .7),
                                            height: 30,
                                            width: 30,
                                            child:   const Icon(
                                              Icons.mode,
                                              color: Colors.white,
                                              size: 17,
                                            )),
                                      ),
                                    )),
                              ],
                            ))
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            CustomsButtons(
                textColor: whiteColor,
                text: "Update Profile".translate(context),
                backgroundColor: themeColor,
                onPressed: () {
                  context
                      .read<UpdateProfileCubit>()
                      .updateProfileMethod(postData: {
                    "first_name": textEditingEditProfileNameController.text,
                  });
                }),
            const SizedBox(
              height: 50,
            )
          ]),
        );
      }),
    );
  }

  void showImagePickerPopup(BuildContext context, Offset offset) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          offset.dx, offset.dy, offset.dx + 10, offset.dy + 10),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: themeColor),
              const SizedBox(width: 10),
              Text("Camera".translate(context)),
            ],
          ),
          onTap: () {
            pickImage(ImageSource.camera);
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.photo, color: themeColor),
              const SizedBox(width: 10),
              Text("Gallery".translate(context)),
            ],
          ),
          onTap: () {
            pickImage(ImageSource.gallery);
          },
        ),
      ],
      elevation: 10,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  void getButtonPosition(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    showImagePickerPopup(context, offset);
  }
}




