import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/domain/entities/sos_data.dart';
import 'package:ride_on/presentation/cubits/sos_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class SosButtonWidget extends StatefulWidget {
  const SosButtonWidget({super.key});

  @override
  State<SosButtonWidget> createState() => _SosButtonWidgetState();
}

class _SosButtonWidgetState extends State<SosButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 18, bottom: 18,left: 15),
          child: ScaleTransition(
            scale: _animation,
            child: GestureDetector(
              onTap: () {
                context.read<SosCubit>().getSosList(context);
                _showSosDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFF3B30), Color(0xffFF5E57)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: .50),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

   void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .85),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha:0.2), blurRadius: 20)
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                child: BlocBuilder<SosCubit, SosState>(
                  builder: (context, state) {
                    if (state is SosLoading) {
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.redAccent.shade200,
                          ),
                        ),
                      );
                    }

                    if (state is SosFailed) {
                      return _errorDialog(context, state.error);
                    }

                    List<Sos> sosList = [];
                    if (state is SosSuccess) {
                      sosList = state.sosData.sos ?? [];
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xffFF3B30), Color(0xffFF6B6B)],
                            ),
                          ),
                          child: const Icon(Icons.sos_rounded,
                              size: 55, color: Colors.white),
                        ),

                        const SizedBox(height: 16),

                          Text(
                          "Emergency Support".translate(context),
                          style: heading1Grey1(context).copyWith(color: redColor),
                        ),

                        const SizedBox(height: 6),

                          Text(
                          "Choose a contact to call instantly".translate(context),
                          style: regular2(context),
                        ),

                        const SizedBox(height: 22),

                        if (sosList.isEmpty)
                            Text(
                            "No SOS contacts available!".translate(context),
                            style: regular2(context),
                          )
                        else
                          Column(
                            children: sosList.map((e) {
                              return _modernSosCard(
                                name: e.name ?? "Unknown",
                                number: e.sosNumber ?? "",
                                onCall: () {
                                  Navigator.pop(context);
                                  _makePhoneCall(e.sosNumber ?? "");
                                },
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 20),

                        _cancelButton(context),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

   Widget _errorDialog(BuildContext context, String msg) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          msg,
          style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

   Widget _modernSosCard({
    required String name,
    required String number,
    required VoidCallback onCall,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: whiteColor,
        boxShadow: [
          BoxShadow(
            color: blackColor.withValues(alpha: .07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onCall,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xffFF5A5A), Color(0xffFF7E7E)],
                  ),
                ),
                child:   Icon(Icons.call, color: whiteColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: heading3(context).copyWith(color: blackColor)),
                    const SizedBox(height: 4),
                    Text(
                      number,
                      style: regular(context),
                    ),
                  ],
                ),
              ),
                Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: blackColor,
              )
            ],
          ),
        ),
      ),
    );
  }

   Widget _cancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child:   Text(
        "Close".translate(context),
        style: heading3(context),
      ),
    );
  }
}


