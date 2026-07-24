import 'package:ride_on/data/repositories/auth_repository.dart';
import 'package:ride_on/data/repositories/food_repository.dart';
import 'package:ride_on/data/repositories/history_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:ride_on/presentation/cubits/food_cubit.dart';
import 'package:ride_on/presentation/cubits/payment/coupon_cubit.dart';
import 'package:ride_on/presentation/cubits/slider_cubit.dart';
import 'package:ride_on/presentation/cubits/sos_cubit.dart';
import 'package:ride_on/presentation/cubits/vehicle_data/get_service_type_cubit.dart';
import '../data/repositories/payment_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/review_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../presentation/cubits/auth/apple_login_cubit.dart';
import '../presentation/cubits/auth/change_email_cubit.dart';
import '../presentation/cubits/auth/change_phone_number_cubit.dart';
import '../presentation/cubits/auth/email_otp_cubit.dart';
import '../presentation/cubits/auth/google_login_cubit.dart';
import '../presentation/cubits/auth/login_cubit.dart';
import '../presentation/cubits/auth/otp_verify_cubit.dart';
import '../presentation/cubits/auth/resend_otp_cubit.dart';
import '../presentation/cubits/auth/signup_cubit.dart';
import '../presentation/cubits/auth/user_authenticate_cubit.dart';
import '../presentation/cubits/book_ride_cubit.dart';
import '../presentation/cubits/general_cubit.dart';
import '../presentation/cubits/history/history_cubit.dart';
import '../presentation/cubits/localizations_cubit.dart';
import '../presentation/cubits/location/get_item_price_cubit.dart';
import '../presentation/cubits/location/get_nearby_drivers_cubit.dart';
import '../presentation/cubits/location/set_marker_cubit.dart';
import '../presentation/cubits/location/user_current_location_cubit.dart';
import '../presentation/cubits/logout_cubit.dart';
import '../presentation/cubits/payment/payment_cubit.dart';
import '../presentation/cubits/profile/delete_account_cubit.dart';
import '../presentation/cubits/profile/edit_profile_cubit.dart';
import '../presentation/cubits/realtime/check_ride_request_cubit.dart';
import '../presentation/cubits/realtime/get_ride_request_status_cubit.dart';
import '../presentation/cubits/realtime/ride_request_cubit.dart';
import '../presentation/cubits/realtime/update_ride_request_parameter.dart';
import '../presentation/cubits/review/review_cubit.dart';
import '../presentation/cubits/static_page.dart';
import '../presentation/cubits/vehicle_data/get_vehicle_cetgegory_cubit.dart';

class RegisterCubits {
  List<SingleChildWidget> providers = [
    BlocProvider(create: (context) => LanguageCubit()),
    BlocProvider(create: (context) => LCodeCubit()),
    BlocProvider(create: (context) => AuthLoginCubit(AuthRepository())),
    BlocProvider(create: (context) => AppleLoginCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthSignUpCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthOtpVerifyCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthResendOtpCubit(AuthRepository())),
    BlocProvider(create: (context) => AuthUserAuthenticateCubit(AuthRepository())),
    BlocProvider(create: (context) => GetVehicleDataCubit(VehicleRepository())),
    BlocProvider(create: (context) => DeleteAccountCubit(ProfileRepository())),
    BlocProvider(create: (context) => SlidersCubit(ProfileRepository())),
    BlocProvider(create: (context) => VehicleDataUpdateCubit()),
    BlocProvider(create: (context) => GoogleLoginCubit(AuthRepository())),
    BlocProvider(create: (context) => SetCountryCubit()),
    BlocProvider(create: (context) => LogoutCubit()),
    BlocProvider(create: (context) => BookRideRealTimeDataBaseCubit()),
    BlocProvider(create: (context) => LocationUserCubit()),
    BlocProvider(create: (context) => UpdateCurrentAddressCubit()),
    BlocProvider(create: (context) => SelectedAddressCubit()),
    BlocProvider(create: (context) => GetSuggestionAddressCubit()),
    BlocProvider(create: (context) => GetCordinatesCubit()),
    BlocProvider(create: (context) => DriverNearByCubit()),
    BlocProvider(create: (context) => DriverMapCubit()),
    BlocProvider(create: (context) => GetPolylineCubit()),
    BlocProvider(create: (context) => SetVehicleCategoryCubit()),
    BlocProvider(create: (context) => MarkerCubit()),
    BlocProvider(create: (context) => GetUpdatedLocationCubit()),
    BlocProvider(create: (context) => GetItemPriceCubit(VehicleRepository())),
    BlocProvider(create: (context) => GetServiceTypeDataCubit(VehicleRepository())),
    BlocProvider(create: (context) => GetDistanceRouteCubit()),
    BlocProvider(create: (context) => BookRideUserCubit(VehicleRepository())),
    BlocProvider(create: (context) => RideRequestCubit()),
    BlocProvider(create: (context) => GetRideRequestStatusCubit()),
    BlocProvider(create: (context) => ReviewCubit(ReviewRepository())),
    BlocProvider(create: (context) => UpdatePaymentByUserCubit(PaymentRepository())),
    BlocProvider(create: (context) => PaymentCubit()),
    BlocProvider(create: (context) => UpdateRideRequestParameterCubit()),
    BlocProvider(create: (context) => HistoryCubit(HistoryRepository())),
    BlocProvider(create: (context) => UpdateProfileCubit(ProfileRepository())),
    BlocProvider(create: (context) => MyImageCubit()),
    BlocProvider(create: (context) => NameCubit()),
    BlocProvider(create: (context) => PhoneCubit()),
    BlocProvider(create: (context) => EmailCubit()),
    BlocProvider(create: (context) => ChangeEmailCubits(AuthRepository())),
    BlocProvider(create: (context) => ChangePhoneCubits(AuthRepository())),
    BlocProvider(create: (context) => EmailOtpCubit(AuthRepository())),
    BlocProvider(create: (context) => UpdateSearchMapAddressCubit()),
    BlocProvider(create: (context) => GeneralCubit(ProfileRepository())),
    BlocProvider(create: (context) => SosCubit(ProfileRepository())),
    BlocProvider(create: (context) => StaticPageCubits(ProfileRepository())),
    BlocProvider(create: (context) => CheckStatusCubit()),
    BlocProvider(create: (context) => GetRideRequestPaymentCubit()),
    BlocProvider(create: (context) =>UpdateRideStatusInDatabaseCubit(VehicleRepository())),
    BlocProvider(create: (context) => UserMarkerCubit()),
    BlocProvider(create: (context) => LanguageCubit()),
    BlocProvider(create: (context) => FirebaseUpdateIntervalCubit()),
    BlocProvider(create: (context) => LocationAccuracyThresholdCubit()),
    BlocProvider(create: (context) => BackgroundLocationIntervalCubit()),
    BlocProvider(create: (context) => DriverSearchIntervalCubit()),
    BlocProvider(create: (context) => UseGoogleBeforePickupCubit()),
    BlocProvider(create: (context) => UseGoogleAfterPickupCubit()),
    BlocProvider(create: (context) => UseGoogleSourceDestination()),
    BlocProvider(create: (context) => MinimumHitsTimeToUpdateTime()),
    BlocProvider(create: (context) => LastActiveApp()),
    BlocProvider(create: (context) => CouponCubit(PaymentRepository())),
    BlocProvider(create: (context) => ServiceTypeId()),
    BlocProvider(create: (context) => FoodCubit(FoodRepository())),
  ];
}
