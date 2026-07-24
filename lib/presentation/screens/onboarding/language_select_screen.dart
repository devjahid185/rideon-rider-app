import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/app/route_settings.dart';
 import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/utils/common_widget.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
 import 'package:ride_on/presentation/cubits/localizations_cubit.dart';
import 'package:ride_on/presentation/screens/onboarding/on_boarding_screen.dart';

class SelectLanguageScreen extends StatefulWidget {
  final bool isBack;
  const SelectLanguageScreen({
    required this.isBack,

    super.key});

  @override
  State<SelectLanguageScreen> createState() => _SelectLanguageScreenState();
}

class _SelectLanguageScreenState extends State<SelectLanguageScreen>
    with SingleTickerProviderStateMixin {
  int _selectedValue = lanBox.get("lanValue") ?? -1;

final List<Map<String, dynamic>> localeList = [
  {"name": "English", "locale": "en", "flag": "ðŸ‡¬ðŸ‡§"},
  {"name": "Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© (Arabic)", "locale": "ar", "flag": "ðŸ‡¸ðŸ‡¦"},
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // ðŸŒˆ Beautiful gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeColor.withValues(alpha: .1),
              themeColor.withValues(alpha: .2),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                const Spacer(),
                // ðŸŒ Heading
                Text(
                  "ðŸŒ ${"Choose Your Language".translate(context)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: notifires.getwhiteblackColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Select your preferred language to continue"
                      .translate(context),
                  style: TextStyle(
                    fontSize: 15,
                    color: notifires.getwhiteblackColor.withValues(alpha:0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ðŸ”¥ Animated Language Options
                BlocBuilder<LanguageCubit, LanguageState>(
                  builder: (context, state) {
                    return Column(
                      children: List.generate(localeList.length, (index) {
                        final isSelected = _selectedValue == index;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? themeColor.withValues(alpha:0.15)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                              isSelected ? themeColor : Colors.grey.shade300,
                              width: 1.8,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: themeColor.withValues(alpha: .2),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: ListTile(
                            leading: Text(
                              localeList[index]['flag'],
                              style: const TextStyle(fontSize: 26),
                            ),
                            title: Text(
                              localeList[index]['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: notifires.getwhiteblackColor,
                              ),
                            ),
                            trailing: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: isSelected
                                  ? Icon(Icons.check_circle_rounded,
                                  color: themeColor, key: const ValueKey(1))
                                  : Icon(Icons.circle_outlined,
                                  color: Colors.grey.shade400,
                                  key: const ValueKey(2)),
                            ),
                            onTap: () {
                              context
                                  .read<LanguageCubit>()
                                  .changeLanguage(localeList[index]["locale"]);

                              lanBox.put('lCode', localeList[index]['locale']);
                              lanBox.put("lanValue", index);
                              setState(() {
                                _selectedValue = index;
                              });
                              context.read<LCodeCubit>().changeLanguage(localeList[index]['locale']);
                            },
                          ),
                        );
                      }),
                    );
                  },
                ),

                const Spacer(),

                SizedBox(
                  height: 55,
                  child: CustomsButtons(text: "Continue", backgroundColor: themeColor, onPressed: (){
                     if (_selectedValue != -1) {

                      if(widget.isBack){
                        goBack();
                      }else{
                      goToWithClear(const Onboardingscreen());}
                    }
                  }),
                ),
 
            

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


