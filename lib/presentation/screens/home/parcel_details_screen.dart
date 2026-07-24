// ignore_for_file: void_checks

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/common_widget.dart';
import 'package:ride_on/presentation/cubits/auth/user_authenticate_cubit.dart';
import 'package:ride_on/presentation/cubits/location/user_current_location_cubit.dart';
import 'package:ride_on/presentation/widgets/custom_text_form_field.dart';
import 'package:ride_on/presentation/widgets/form_validations.dart';
import '../../../core/services/data_store.dart';
import '../Search/route_location_screen.dart';

class ParcelDetailsScreen extends StatefulWidget {
  final String maxWeight;
  const ParcelDetailsScreen({
    super.key,
    required this.maxWeight,
  });

  @override
  State<ParcelDetailsScreen> createState() => _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends State<ParcelDetailsScreen> {
  final TextEditingController _parcelNameController = TextEditingController();
  final TextEditingController _parcelWeightController = TextEditingController();
  final TextEditingController _parcelValueController = TextEditingController();
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _pickupInstructionsController =
      TextEditingController();
  final TextEditingController _specialInstructionsController =
      TextEditingController();

 

  File? parcelImage;

  @override
  void dispose() {
    _parcelNameController.dispose();
    _parcelWeightController.dispose();
    _parcelValueController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _pickupInstructionsController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  

 

 
  bool isWeightValid() {
    final enteredWeight = double.tryParse(_parcelWeightController.text);
    final maxAllowedWeight = double.tryParse(widget.maxWeight);

    if (enteredWeight == null) return false;
    if (maxAllowedWeight == null) return true;

    return enteredWeight <= maxAllowedWeight;
  }

  void _validateAndProceed() {
    if (_parcelNameController.text.isEmpty) {
      return showErrorToastMessage(
          "Please enter parcel name".translate(context));
    }
    if (_parcelWeightController.text.isEmpty) {
      return showErrorToastMessage("Please enter weight".translate(context));
    }
   

    if (!isWeightValid()) {
      return showErrorToastMessage(
        "${"Max allowed weight is".translate(context)} ${widget.maxWeight} ${"kg".translate(context)}".translate(context),
      );
    }
    if (_receiverNameController.text.isEmpty) {
      return showErrorToastMessage(
          "Please enter receiver name".translate(context));
    }
    if (_receiverPhoneController.text.isEmpty) {
      return showErrorToastMessage(
          "Please enter receiver phone".translate(context));
    }

    final parcelData = {
      'name': _parcelNameController.text,
      'weight': _parcelWeightController.text,
      'receiverName': _receiverNameController.text,
      'receiverPhone': _receiverPhoneController.text,
      'pickupInstructions': _pickupInstructionsController.text,
    };

    box.put('current_parcel_data', parcelData);

    final currentAddress =
        context.read<SelectedAddressCubit>().pickupAddressController.text;

    context.read<GetSuggestionAddressCubit>().getSuggestions("");

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserSearchLocation(currentAddress: currentAddress),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: isNumeric == true && Platform.isIOS
          ? KeyboardDoneButton(
              onTap: () {
                setState(() {
                  isNumeric = false;
                });
              },
            )
          : null,
      backgroundColor: notifires.getbgcolor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: themeColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Parcel Details".translate(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: heading2Grey1(context)
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("Parcel Name", _parcelNameController,
                prefixIcon: Icons.edit_note_rounded,
                hint: "e.g., Laptop, Documents, Electronics".translate(context)),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        "Weight (kg)", _parcelWeightController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.scale_rounded,
                        suffix: "kg".translate(context),
                        hint: "e.g., 2.5")),
               
                
              ],
            ),
            
           Text("${"Max allowed weight is".translate(context)} ${widget.maxWeight} ${"kg".translate(context)}"
                .translate(context),
                style: regular2(context)
                    .copyWith(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 135, 197, 247)
                      .withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: .2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.person_outline_rounded,
                          color: Colors.blue, size: 21),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Receiver Details".translate(context),
                            style: heading3Grey1(context)
                                .copyWith(color: Colors.blue)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextFieldAdvance(
                      onTap: () {
                        isNumeric = false;
                        setState(() {});
                      },
                      inputAlignment: TextAlign.start,
                      txt: "Receiver Name".translate(context),
                      icons: Icon(
                        Icons.person_2_outlined,
                        color: blackColor,
                      ),
                      textEditingControllerCommon: _receiverNameController,
                      inputType: TextInputType.name,
                      validator: (value) {
                        if (isValidName(value!)) {
                          return null;
                        } else {
                          return "Enter receiver full name".translate(context);
                        }
                      },
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    BlocBuilder<SetCountryCubit, SetCountryState>(
                        builder: (context, state) {
                      return IntelPhoneFieldRefs(
                        onTap: () {
                          isNumeric = true;
                          setState(() {});
                        },
                        onChanged: (value) {
                          int expectedLength =
                              phoneLengths[state.countryCode] ?? 10;

                          if (value!.number.length > expectedLength) {
                            _receiverPhoneController.text =
                                value.number.substring(0, expectedLength);

                            _receiverPhoneController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _receiverPhoneController.text.length),
                            );
                          }
                          setState(() {});
                          return null;
                        },
                        key: ValueKey(state.countryCode),
                        defultcountry: state.countryCode,
                        textEditingControllerCommons: _receiverPhoneController,
                        oncountryChanged: (number) {
                          context.read<SetCountryCubit>().reset();
                          _receiverPhoneController.clear();

                          context.read<SetCountryCubit>().setCountry(
                              dialCode: number.dialCode,
                              countryCode: number.code);
                        },
                        hintText: "Phone no".translate(context),
                        validator: (phoneNumber) {
                          if (phoneNumber == null ||
                              phoneNumber.number.isEmpty) {
                            return "Please enter receiver phone number"
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
                    }),
                  ]),
            ),
            const SizedBox(height: 15),
            _buildTextField(
                "Pickup Instructions", _pickupInstructionsController,
                maxLines: 2,
                prefixIcon: Icons.note_outlined,
                hint: "e.g., Call before arriving, Leave at door".translate(context)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.arrow_forward, color: Colors.white),
                  const SizedBox(width: 10),
                  Text("Proceed to Location".translate(context),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType,
      String? prefix,
      String? suffix,
      String? hint,
      IconData? prefixIcon,
      int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.translate(context),
          style: heading3Grey1(context)
              .copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
            color: notifires.getbgcolor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!)),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            hintText: hint?.translate(context),
            hintStyle: regular2(context)
                .copyWith(color: Colors.grey[400], fontSize: 13),
            prefixText: prefix,
            prefixStyle: regular2(context).copyWith(color: Colors.grey[600]),
            suffixText: suffix,
            suffixStyle: regular2(context).copyWith(color: Colors.grey[600]),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey[500])
                : null,
          ),
        ),
      ),
    ]);
  }
}


