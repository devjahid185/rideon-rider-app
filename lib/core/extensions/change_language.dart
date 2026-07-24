import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/utils/translate.dart';
import '../../presentation/cubits/localizations_cubit.dart';
import '../utils/common_widget.dart';
import '../utils/theme/project_color.dart';
import '../utils/theme/theme_style.dart';

class ChangeLanguage extends StatefulWidget {
  const ChangeLanguage({super.key});

  @override
  State<ChangeLanguage> createState() => _ChangeLanguageState();
}

class _ChangeLanguageState extends State<ChangeLanguage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = lanBox.get("lanValue") ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: notifires.getbgcolor,
      appBar: CustomAppBars(
        title: "Language".translate(context),
        backgroundColor: notifires.getbgcolor,
        centerTitle: false,
        iconColor: notifires.getwhiteblackColor,
        titleColor: notifires.getwhiteblackColor,
      ),
      body: BlocBuilder<LanguageCubit, LanguageState>(
        builder: (context, state) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: locale.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;

              return GestureDetector(
                onTap: () => _onLanguageSelect(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeColor.withValues(alpha: .10)
                        : notifires.getwhiteblackColor.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? themeColor.withValues(alpha: .7)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        size: 18,
                        color: blackColor,
                      ),
                      const SizedBox(width: 15),
                      Text(
                        locale[index]['name'],
                        style: appBarNormal.copyWith(
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: notifires.getwhiteblackColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _flagAvatar(locale[index]['locale']),
                      const Spacer(),
                      _radioDot(isSelected),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onLanguageSelect(int index) {
    context.read<LanguageCubit>().changeLanguage(locale[index]['locale']);

    lanBox.put('lCode', locale[index]['locale']);
    lanBox.put("lanValue", index);

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _flagAvatar(String localeCode) {
    String flag = "🌐";

    switch (localeCode) {
      case "en":
        flag = "🇺🇸";
        break;
      case "ar":
        flag = "🇸🇦";
        break;
      case "hi":
        flag = "🇮🇳";
        break;
      case "fr":
        flag = "🇫🇷";
        break;
    }

    return Container(
      height: 26,
      width: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(flag, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _radioDot(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? themeColor : Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: themeColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
