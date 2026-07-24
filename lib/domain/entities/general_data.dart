class GeneralDataModel {
  int? status;
  String? message;
  Data? data;
  String? error;

  GeneralDataModel({this.status, this.message, this.data, this.error});

  factory GeneralDataModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return GeneralDataModel();
    return GeneralDataModel(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
      error: json['error'] as String?,
    );
  }
}

class Data {
  MetaData? metaData;

  Data({this.metaData});

  factory Data.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Data();
    return Data(
      metaData:
      json['metaData'] != null ? MetaData.fromJson(json['metaData']) : null,
    );
  }
}

class MetaData {
  String? generalDefaultCurrency;
  String? generalDefaultLanguage;
  String? socialnetworkGoogleLogin;
  String? onlinePayment;
  String? generalDefaultPhoneCountry;
  String? generalDefaultCountryCode;
  String? firebaseUpdateInterval;
  String? locationAccuracyThreshold;
  String? backgroundLocationInterval;
  String? driverSearchInterval;
  String? useGoogleAfterPickup;
  String? useGoogleBeforePickup;
  String? minimumHitsTime;
  String? useGoogleSourceDestination;
  String? title;
  String? itemSettingImage;
  String? lastActiveApp;

  MetaData({
    this.generalDefaultCurrency,
    this.generalDefaultLanguage,
    this.socialnetworkGoogleLogin,
    this.onlinePayment,
    this.generalDefaultPhoneCountry,
    this.generalDefaultCountryCode,
    this.firebaseUpdateInterval,
    this.locationAccuracyThreshold,
    this.backgroundLocationInterval,
    this.driverSearchInterval,
    this.useGoogleAfterPickup,
    this.useGoogleBeforePickup,
    this.minimumHitsTime,
    this.useGoogleSourceDestination,
    this.title,
    this.itemSettingImage,
    this.lastActiveApp,
  });

  factory MetaData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MetaData();
    return MetaData(
      generalDefaultCurrency: json['general_default_currency'] as String?,
      generalDefaultLanguage: json['general_default_language'] as String?,
      socialnetworkGoogleLogin: json['socialnetwork_google_login'] as String?,
      onlinePayment: json['onlinepayment'] as String?,
      generalDefaultPhoneCountry:
      json['general_default_phone_country'] as String?,
      generalDefaultCountryCode:
      json['general_default_country_code'] as String?,
      firebaseUpdateInterval: json['firebase_update_interval'] as String?,
      locationAccuracyThreshold:
      json['location_accuracy_threshold'] as String?,
      backgroundLocationInterval:
      json['background_location_interval'] as String?,
      driverSearchInterval: json['driver_search_interval'] as String?,
      useGoogleAfterPickup: json['use_google_after_pickup'] as String?,
      useGoogleBeforePickup: json['use_google_before_pickup'] as String?,
      minimumHitsTime: json['minimum_hits_time'] as String?,
      useGoogleSourceDestination: json['use_google_source_destination'] as String?,
      title: json['title'] as String?,
      itemSettingImage: json['item_setting_image'] as String?,
      lastActiveApp: json['last_active'] as String?,
    );
  }
}