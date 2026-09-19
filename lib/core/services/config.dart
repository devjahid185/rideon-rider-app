class Config {
  static const googleKey = "AIzaSyCm-rRAsfqyVZuth4dXJQ11cU24rV-5Zzw";
  // Temporary base domain URL for setup (please add your final URL here)
  static const String baseDomain = 'https://admin.wgnmove.com';
  // static const String baseDomain = 'https://innovittree.in';
  // Do not change any code below this line. ==================================================

  static const String version = '/api/v1/';
  static const String bearerVersion = '/api/';
  static const String baseUrl = '$baseDomain$version';
  static const String baseUrlForBearer = '$baseDomain$bearerVersion';
  static const String secretKey = '49382716504938271650493827165049';
  static const String generateToken = 'generateToken';
  static const String registerUser = 'userRegister';
  static const String socialLogin = 'socialLogin';
  static const String verifyResetToken = 'verifyResetToken';
  static const String fcmUpdate = 'fcmUpdate';
  static const String otpVerification = 'otpVerification';
  static const String resendTokenEmailChange = 'ResendTokenEmailChange';
  static const String updateBookingStatusByUser = 'updateBookingStatusByUser';
  static const String rideAudioRecording = 'ride-audio-recordings';
  static const String resendOtp = 'ResendOtp';
  static const String changeEmail = 'changeEmail';
  static const String sendMobileLoginOtp = 'sendMobileLoginOtp';
  static const String checkEmail = 'checkEmail';
  static const String userMobileLogin = 'userMobileLogin';
  static const String getAllCategories = 'getAllCategories';
  static const String checkMobileNumber = 'checkMobileNumber';
  static const String changeMobileNumber = 'changeMobileNumber';
  static const String getItemPrices = 'getItemPrices';
  static const String bookItem = 'bookItem';
  static const String giveReviewByUser = 'giveReviewByUser';
  static const String updatePaymentStatusByUser = 'updatePaymentStatusByUser';
  static const String bookingRecord = 'bookingRecord';
  static const String deleteAccount = 'deleteAccount';
  static const String editProfile = 'editProfile';
  static const String uploadProfileImage = 'uploadProfileImage';
  static const String getgeneralSettings = 'getgeneralSettings';
  static const String staticPage = 'StaticPage';
  static const String sos = 'sos';
  static const String sliders = 'sliders';
  static const String serviceTypes = 'service-types';
  static const String getItemTypesByService = 'item-types/by-service-type';

  // Food Delivery
  static const String foodNearbyRestaurants = 'food/restaurants/nearby';
  static const String foodRestaurantMenu = 'food/restaurants'; // /{id}/menu
  static const String foodCreateOrder = 'food/order/create';
  static const String foodOrderDetails = 'food/order'; // /{id}
  static const String foodMyOrders = 'food/orders/my';
  static const String foodAvailableOrders = 'food/orders/available';
  static const String foodAcceptOrder = 'food/order'; // /{id}/accept
  static const String foodUpdateOrderStatus = 'food/order'; // /{id}/status
  static const String foodOrderTimeline = 'food/order'; // /{id}/timeline
}
