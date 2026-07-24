import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ride_on/core/utils/translate.dart';

import '../../../core/extensions/change_language.dart';
import '../../../core/services/data_store.dart';
import '../../../core/utils/common_widget.dart';
import '../../../core/utils/theme/project_color.dart';
import '../../../core/utils/theme/theme_style.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isdark = box.get("getDarkValue") ?? false;

  bool darkMode = true;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    notifires = Provider.of<ColorNotifires>(context, listen: true);

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: Dimensions.containerWidth,
        child: Scaffold(
          backgroundColor: notifires.getbgcolor,
          appBar: CustomAppBars(
            onBackButtonPressed: () {
              Navigator.pop(context);
            },
            title: "Settings".translate(context),
            backgroundColor: notifires.getbgcolor,
            iconColor: notifires.getwhiteblackColor,
            titleColor: notifires.getwhiteblackColor,
          ),
          body: SingleChildScrollView(
            child: Column(children: [


              InkWell(
                onTap: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChangeLanguage()));
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
                        Icon(
                          Icons.language,
                          color: notifires.getGrey3whiteColor,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          "Change Language".translate(context),
                          style: regular3(context)
                              .copyWith(color: notifires.getGrey2whiteColor),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: notifires.getGrey3whiteColor,
                          size: 17,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return const DeleteConfirmationDialogs();
                      },
                    );
                  },
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                        color: notifires.getBoxColor,
                        borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    width: double.maxFinite,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
                        Icon(
                          Icons.delete,
                          color: notifires.getGrey3whiteColor,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          "Delete Account".translate(context),
                          style: regular3(context)
                              .copyWith(color: notifires.getGrey2whiteColor),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: notifires.getGrey3whiteColor,
                          size: 17,
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}


