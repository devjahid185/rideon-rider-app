import 'package:flutter/material.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../core/utils/theme/project_color.dart';
import '../../core/utils/theme/theme_style.dart';
import '../screens/Search/search_map_screen.dart';

Widget selectWithLocation({BuildContext? context}) {
  return PopupMenuButton<int>(
      color: whiteColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0), // reduced padding
          onTap: () async {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>   const SearchMapScreen(checkStatus: true),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 18), // smaller icon
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Select Pickup Location".translate(context),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5, // smaller font
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          onTap: () async {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchMapScreen(checkStatus: false),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Select Drop-off Location".translate(context),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],


      offset: const Offset(50, 50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 8),
        decoration: BoxDecoration(
            color: themeColor,
            border: Border.all(color: themeColor.withValues(alpha: .4),width: 1),
            borderRadius: BorderRadius.circular(8)
        ),
        child: Row(mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_outlined,color:Colors.red,size: 20,),
                 const SizedBox(width: 4,),
              Padding(
                padding: const EdgeInsets.only(left: 4,right: 4),
                child: Text("Select From Map".translate(context!),
                    style:
                    heading2Grey1(context).copyWith(fontSize: 13, color: whiteColor)),
              ),
            ]),
      ));
}



