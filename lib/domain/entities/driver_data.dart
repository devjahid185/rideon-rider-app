
import 'package:firebase_database/firebase_database.dart';

class Driver {
  final String id;
  final String itemTypeName;
  final double? latitude;
  final double? longitude;
  final String status;
  final String vehicleImage;
  final String timestamp;
  final String driverVehicleTypeId;
  final String? driverName;
  final String? driverNumber;
  final String? driverPhoneCountryCode;

  Driver({
    required this.id,
    required this.itemTypeName,
    required this.vehicleImage,
    this.latitude,
    this.longitude,
    required this.status,
    required this.timestamp,
    required this.driverVehicleTypeId,
    this.driverName,
    this.driverNumber,
    this.driverPhoneCountryCode,
  });

  factory Driver.fromSnapshot(DataSnapshot snapshot) {
    final location = snapshot.child('location');
    final dynamic latValue = location.child('latitude').value;
    final dynamic lngValue = location.child('longitude').value;

    return Driver(
      id: snapshot.key ?? 'unknown_id',
      itemTypeName:
          snapshot.child('itemTypeName').value?.toString() ?? 'No vehicle type',
      vehicleImage: snapshot.child('itemImage').value?.toString() ?? '',
      latitude: _safeParseDouble(latValue),
      longitude: _safeParseDouble(lngValue),
      status: snapshot.child('driverStatus').value?.toString() ?? 'inactive',
      timestamp: snapshot.child('timestamp').value?.toString() ??
          DateTime.now().toIso8601String(),
      driverVehicleTypeId:
          snapshot.child('itemTypeId').value?.toString() ?? '0',
      driverName: snapshot.child('driverName').value?.toString(),
      driverNumber: snapshot.child('driverNumber').value?.toString(),
      driverPhoneCountryCode: snapshot.child('phoneCountry').value?.toString(),
    );
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemTypeName': itemTypeName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'vehicleImage': vehicleImage,
      'timestamp': timestamp,
      'driverVehicleTypeId': driverVehicleTypeId,
      'driverName': driverName,
      'driverNumber': driverNumber,
      'phoneCountry': driverPhoneCountryCode,
    };
  }

  @override
  String toString() {
    return 'Driver{id: $id, type: $itemTypeName, lat: $latitude, lng: $longitude, '
        'status: $status, name: $driverName, number: $driverNumber}';
  }
}
