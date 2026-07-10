// // DataBase get database => Get.find();
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// //DataBase dataBase = Get.put(DataBase());

// class DataBase extends GetxController {
//   final Future<SharedPreferences> _pref = SharedPreferences.getInstance();

//   String _transactionPin = '';

//   String _confirmTransactionPin = '';

//   String _recommended_by = '';

//   String _reqMessage = '';

//   String _isSeeen = '';

//   Color? _color;

//   bool _isLoading = false;

//   bool _isSeen = false;

//   bool _isSet = false;

//   String _isSett = '';

//   String _token = '';

//   String _location = '';

//   String _state = '';

//   String _userName = '';

//   String _userId = '';

//   String _profileId = '';

//   String _acctName = '';

//   String _acctNumber = '';

//   String _bankName = '';

//   String _businessBrandName = '';

//   String _brmId = '';

//   String _brmCode = '';

//   String _brmPhone = '';

//   String _brmAddress = '';

//   String _address = '';

//   String _brmName = '';

//   String _dateAssigned = '';

//   String _businessType = '';

//   String _profileImage = '';

//   String _phone = '';

//   String _email = '';

//   String _first_name = '';

//   String _last_name = '';

//   String get recommended_by => _recommended_by;

//   String get token => _token;

//   bool get isSeen => _isSeen;

//   String get address => _address;

//   String get isSett => _isSett;

//   String get isSeeen => _isSeeen;

//   String get brm => _brmId;

//   String get brmCode => _brmCode;

//   String get brmName => _brmName;

//   bool get isSet => _isSet;

//   String get brmAddress => _brmAddress;

//   String get brmPhone => _brmPhone;

//   String get dateAssigned => _dateAssigned;

//   String get location => _location;

//   String get state => _state;

//   String get userName => _userName;

//   String get userId => _userId;

//   String get profileId => _profileId;

//   String get acctNumber => _acctNumber;

//   String get acctName => _acctName;

//   String get bankName => _bankName;

//   String get businessBrandName => _businessBrandName;

//   String get businessType => _businessType;

//   String get profileImage => _profileImage;

//   String get phone => _phone;

//   String get email => _email;

//   String get first_name => _first_name;

//   String get last_name => _last_name;

//   bool get isLoading => _isLoading;

//   Color? get color => _color;

//   String get reqMessage => _reqMessage;

//   String get transactionPin => _transactionPin;

//   String get confirmTransactionPin => _confirmTransactionPin;

// // logOut()async{
// //   final SharedPreferences _pref = await SharedPreferences.getInstance();
// //   await _pref.clear();

// // }

//   saveToken(String token) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('token', token);

//     return true;
//   }

//   Future<bool> saveTransactionPin(String transactionPin) async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (await sharedPreferences.setString('transactionPin', transactionPin)) {
//       return true;
//     }

//     return false;
//   }

//   saveRecommendedBy(String recommended_by) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('recommended_by', recommended_by);

//     return true;
//   }

//   saveBrmCode(String brmCode) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmCode', brmCode);

//     return true;
//   }

//   saveAddress(String address) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('address', address);

//     return true;
//   }

//   saveSeeen(String isSeeen) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('isSeeen', isSeeen);

//     return true;
//   }

//   saveIsSet(String isSett) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('isSett', isSett);

//     return true;
//   }

//   saveBrmName(String brmName) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmName', brmName);

//     return true;
//   }

//   saveBrmPhone(String? brmPhone) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmPhone', brmPhone!);

//     return true;
//   }

//   saveBrmAddress(String brmAddress) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmAddress', brmAddress);

//     return true;
//   }

//   saveBrmDateAssigned(String brmDateAssigned) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmDateAssigned', brmDateAssigned);

//     return true;
//   }

//   saveLocation(String location) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('location', location);

//     return true;
//   }

//   saveState(String state) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('state', state);

//     return true;
//   }

//   saveUserName(String userName) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('userName', userName);

//     return true;
//   }

//   saveUserId(int userId) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setInt('userId', userId);

//     return true;
//   }

//   saveProfileId(String profileId) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('profileId', profileId);

//     return true;
//   }

//   saveAcctNumber(String acctNumber) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('acctNumber', acctNumber);

//     return true;
//   }

//   saveAcctName(String acctName) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('acctName', acctName);

//     return true;
//   }

//   saveMainCategory(String category) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('category', category);

//     return true;
//   }

//   saveBankName(String bankName) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('bankName', bankName);

//     return true;
//   }

//   saveBusinessBrandName(String businessBrandName) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('businessBrandName', businessBrandName);

//     _businessBrandName = businessBrandName;

//     return true;
//   }

//   saveBrmId(String brmId) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('brmId', brmId);

//     _businessBrandName = brmId;

//     return true;
//   }

//   saveBusinessType(String businessType) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('businessType', businessType);

//     _businessType = businessType;

//     return true;
//   }

//   saveProfileImage(File? image) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('image', image as String);

//     return true;
//   }

//   savePhoneNumber(String phone) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('phone', phone);

//     return true;
//   }

//     saveRole(String role) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('role', role);

//     return true;
//   }

//   saveEmail(String email) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('email', email);

//     return true;
//   }

//     saveFullName(String full_name) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('full_name', full_name);

//     return true;
//   }

//   saveFirstName(String first_name) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('first_name', first_name);

//     return true;
//   }

//   saveLastName(String last_name) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('last_name', last_name);

//     return true;
//   }

//     saveReferalCode(String refCode) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('refCode', refCode);

//     return true;
//   }

//     saveReferalCount(String refCount) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('refCount', refCount);

//     return true;
//   }

//     saveRefererId(String referId) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('referId', referId);

//     return true;
//   }

//    updateStatus(bool status) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setBool('status', status);

//     return true;
//   }

// // Save Profile Photo
//   Future<bool> saveBIo(String bio) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('bio', bio);
//     return true;
//   }

// // Save Profile Photo
//   Future<bool> saveProfilePhoto(String profilePhotoPath) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('profilePhoto', profilePhotoPath);
//     return true;
//   }

// // Save Cover Photo
//   Future<bool> saveCoverPhoto(String coverPhotoPath) async {
//     SharedPreferences sharedPreferences = await _pref;
//     await sharedPreferences.setString('coverPhoto', coverPhotoPath);
//     return true;
//   }

// // Get Profile Photo
//   Future<String> getProfilePhoto() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('profilePhoto')) {
//       String profilePhotoPath = sharedPreferences.getString('profilePhoto')!;
//       return profilePhotoPath;
//     } else {
//       return ''; // Return an empty string if no profile photo is saved
//     }
//   }

// // Get Profile Photo
//   Future<String> getMainCategory() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('category')) {
//       String category = sharedPreferences.getString('category')!;
//       return category;
//     } else {
//       return ''; // Return an empty string if no profile photo is saved
//     }
//   }

// // Get Cover Photo
//   Future<String> getCoverPhoto() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('coverPhoto')) {
//       String coverPhotoPath = sharedPreferences.getString('coverPhoto')!;
//       return coverPhotoPath;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }

// // Get Cover Photo
//   Future<String> getBio() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('bio')) {
//       String bio = sharedPreferences.getString('bio')!;
//       return bio;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }

//   // Get Cover Photo
//   Future<String> getReferId() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('referId')) {
//       String referId = sharedPreferences.getString('referId')!;
//       return referId;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }


//   // Get Cover Photo
//   Future<String> getRefCode() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('refCode')) {
//       String refCode = sharedPreferences.getString('refCode')!;
//       return refCode;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }

//   // Get Cover Photo
//   Future<String> getRefCount() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('refCount')) {
//       String refCount = sharedPreferences.getString('refCount')!;
//       return refCount;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }


//   // Get Cover Photo
//   Future<String> getRole() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('role')) {
//       String role = sharedPreferences.getString('role')!;
//       return role;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }

//   // Get Cover Photo
//   Future<String> getFullName() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('full_name')) {
//       String fullName = sharedPreferences.getString('full_name')!;
//       return fullName;
//     } else {
//       return ''; // Return an empty string if no cover photo is saved
//     }
//   }


//   // Get vendor status
//   Future<bool> getStatus() async {
//     SharedPreferences sharedPreferences = await _pref;
//     if (sharedPreferences.containsKey('status')) {
//       bool status = sharedPreferences.getBool('status')!;
//       return status;
//     } else {
//       return false; // Return an empty string if no cover photo is saved
//     }
//   }

//   // static Future<void> saveNotifications(
//   //     List<NotificationElement> notifications) async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final notificationData = notifications.map((n) => n.toJson()).toList();
//   //   prefs.setString('notifications', notificationData.toString());
//   // }

//   // static Future<List<NotificationElement>> loadNotifications() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   final notificationData = prefs.getString('notifications');
//   //   if (notificationData != null) {
//   //     final List<dynamic> jsonList = jsonDecode(notificationData);
//   //     return jsonList
//   //         .map((json) => NotificationElement.fromJson(json))
//   //         .toList();
//   //   }
//   //   return [];
//   // }

//   Future<String> getToken() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('token')) {
//       String data = sharedPreferences.getString('token')!;
//       _token = data;

//       return data;
//     } else {
//       _token = '';

//       return '';
//     }
//   }

//   Future<String> getAddress() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('address')) {
//       String data = sharedPreferences.getString('address')!;
//       _address = data;

//       return data;
//     } else {
//       _address = '';

//       return '';
//     }
//   }

//   Future<String> getBrmId() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmId')) {
//       String data = sharedPreferences.getString('brmId')!;
//       _brmId = data;

//       return data;
//     } else {
//       _brmId = '';

//       return '';
//     }
//   }

//   Future<String> getBrmCode() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmCode')) {
//       String data = sharedPreferences.getString('brmCode')!;
//       _brmCode = data;

//       return data;
//     } else {
//       _brmCode = '';

//       return '';
//     }
//   }

//   Future<String> getBrmPhone() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmPhone')) {
//       String data = sharedPreferences.getString('brmPhone')!;
//       _brmPhone = data;

//       return data;
//     } else {
//       _brmPhone = '';

//       return '';
//     }
//   }

//   Future<String> getBrmName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmName')) {
//       String data = sharedPreferences.getString('brmName')!;
//       _brmName = data;

//       return data;
//     } else {
//       _brmName = '';

//       return '';
//     }
//   }

//   Future<String> getBrmAddress() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmAddress')) {
//       String data = sharedPreferences.getString('brmAddress')!;
//       _brmAddress = data;

//       return data;
//     } else {
//       _brmAddress = '';

//       return '';
//     }
//   }

//   Future<bool> getIsSeeen() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('isSeeen')) {
//       String data = sharedPreferences.getString('isSeeen')!;
//       _isSeeen = data;

//       return true;
//     } else {
//       _brmAddress = '';

//       return false;
//     }
//   }

//   Future<String> getIsSett() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('isSett')) {
//       String data = sharedPreferences.getString('isSett')!;
//       _isSett = data;

//       return _isSett;
//     } else {
//       _isSett = 'N/A';

//       return _isSett;
//     }
//   }

//   Future<String> getBrmDateAssigned() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('brmDateAssigned')) {
//       String data = sharedPreferences.getString('brmDateAssigned')!;
//       _dateAssigned = data;

//       return data;
//     } else {
//       _dateAssigned = '';

//       return '';
//     }
//   }

//   Future<String> getTransactionPin() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('transactionPin')) {
//       String data = sharedPreferences.getString('transactionPin')!;
//       _token = data;

//       return data;
//     } else {
//       _token = '';

//       return '';
//     }
//   }

//   Future<String> getPhone() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('phone')) {
//       String data = sharedPreferences.getString('phone')!;
//       _phone = data;

//       return data;
//     } else {
//       _phone = '';

//       return '';
//     }
//   }

//   Future<String> getLocation() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('location')) {
//       String data = sharedPreferences.getString('location')!;
//       _phone = data;

//       return data;
//     } else {
//       _phone = '';

//       return '';
//     }
//   }

//   Future<String> getState() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('state')) {
//       String data = sharedPreferences.getString('state')!;
//       _phone = data;

//       return data;
//     } else {
//       _phone = '';

//       return '';
//     }
//   }

//   Future<String> getUserId() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('userId')) {
//       String data = sharedPreferences.getString('userId')!;
//       _userId = data;

//       return data;
//     } else {
//       _userId = '';

//       return '';
//     }
//   }

//   Future<String> getUserName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('userName')) {
//       String data = sharedPreferences.getString('userName')!;
//       _userName = data;

//       return data;
//     } else {
//       _userName = '';

//       return '';
//     }
//   }

//   Future<String> getRecommendedBy() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('recommended_by')) {
//       String data = sharedPreferences.getString('recommended_by')!;
//       _userName = data;

//       return data;
//     } else {
//       _userName = '';

//       return '';
//     }
//   }

//   Future<String> getProfileId() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('profileId')) {
//       String data = sharedPreferences.getString('profileId')!;
//       _profileId = data;

//       return data;
//     } else {
//       _profileId = '';

//       return '';
//     }
//   }

//   Future<String> getAcctNumber() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('acctNumber')) {
//       String data = sharedPreferences.getString('acctNumber')!;
//       _acctNumber = data;

//       return data;
//     } else {
//       _acctNumber = '';

//       return '';
//     }
//   }

//   Future<String> getAcctName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('acctName')) {
//       String data = sharedPreferences.getString('acctName')!;
//       _acctName = data;

//       return data;
//     } else {
//       _acctName = '';

//       return '';
//     }
//   }

//   Future<String> getBankName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('bankName')) {
//       String data = sharedPreferences.getString('bankName')!;
//       _bankName = data;

//       return data;
//     } else {
//       _bankName = '';

//       return '';
//     }
//   }

//   Future<String> getBusinessBrandName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('businessBrandName')) {
//       String businessBrandName =
//           sharedPreferences.getString('businessBrandName')!;
//       _businessBrandName = businessBrandName;

//       return businessBrandName;
//     } else {
//       _businessBrandName = '';

//       return '';
//     }
//   }

//   Future<String> getBusinessType() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('businessType')) {
//       String businessType = sharedPreferences.getString('businessType')!;
//       _businessType = businessType;

//       return businessType;
//     } else {
//       _businessType = '';

//       return '';
//     }
//   }

//   Future<String> getProfileImage() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('image')) {
//       String data = sharedPreferences.getString('image')!;
//       _profileImage = data;

//       return data;
//     } else {
//       _profileImage = '';

//       return '';
//     }
//   }

//   Future<String> getEmail() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('email')) {
//       String data = sharedPreferences.getString('email')!;
//       _email = data;

//       return data;
//     } else {
//       _email = '';

//       return '';
//     }
//   }

//   Future<String> getFirstName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('first_name')) {
//       String data = sharedPreferences.getString('first_name')!;
//       _first_name = data;

//       return data;
//     } else {
//       _first_name = '';

//       return '';
//     }
//   }

//   Future<String> getLastName() async {
//     SharedPreferences sharedPreferences = await _pref;

//     if (sharedPreferences.containsKey('last_name')) {
//       String data = sharedPreferences.getString('last_name')!;
//       _profileImage = data;

//       return data;
//     } else {
//       _profileImage = '';

//       return '';
//     }
//   }

//   Future updateUserP(BuildContext? context) async {
//     _isLoading = true;

//     final sharedPreferences = await _pref;
//     sharedPreferences.clear();

//     _isLoading = false;
//     _reqMessage = 'Log Out Successfull';
//     _color = _color = const Color.fromARGB(255, 15, 175, 20);

//     // Navigator.of(context!)
//     //     .pushNamedAndRemoveUntil("/OnboardingPage", (route) => false);

//     return true;
//   }

//   Future logOut() async {
//     // _isLoading = true;

//     final sharedPreferences = await _pref;
//     sharedPreferences.clear();

//     // _isLoading = false;
//     // _reqMessage = 'Log Out Successfull';
//     // _color = _color = const Color.fromARGB(255, 15, 175, 20);

//     // Navigator.of(context!)
//     //     .pushNamedAndRemoveUntil("/OnboardingPage", (route) => false);

//     // return true;
//   }

//   void status(status) {}


//   // Add these methods to your existing DataBase class in local_storage.dart

// // If you're using SharedPreferences:
// Future<void> saveThemeMode(String themeMode) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString('theme_mode', themeMode);
// }

// Future<String?> getThemeMode() async {
//   final prefs = await SharedPreferences.getInstance();
//   return prefs.getString('theme_mode');
// }

// // // If you're using GetStorage:
// // Future<void> saveThemeMode(String themeMode) async {
// //   final box = GetStorage();
// //   await box.write('theme_mode', themeMode);
// // }

// // Future<String?> getThemeMode() async {
// //   final box = GetStorage();
// //   return box.read('theme_mode');
// // }

// // If you're using another storage method, adapt accordingly
// }

// DataBase get database => Get.find();
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

//DataBase dataBase = Get.put(DataBase());

class DataBase extends GetxController {
  final Future<SharedPreferences> _pref = SharedPreferences.getInstance();

  String _transactionPin = '';

  String _confirmTransactionPin = '';

  String _recommended_by = '';

  String _reqMessage = '';

  String _isSeeen = '';

  Color? _color;

  bool _isLoading = false;

  bool _isSeen = false;

  bool _isSet = false;

  String _isSett = '';

  String _token = '';

  String _location = '';

  String _state = '';

  String _userName = '';

  String _userId = '';

  String _profileId = '';

  String _acctName = '';

  String _acctNumber = '';

  String _bankName = '';

  String _businessBrandName = '';

  String _brmId = '';

  String _brmCode = '';

  String _brmPhone = '';

  String _brmAddress = '';

  String _address = '';

  String _brmName = '';

  String _dateAssigned = '';

  String _businessType = '';

  String _profileImage = '';

  String _phone = '';

  String _email = '';

  String _first_name = '';

  String _last_name = '';

  String get recommended_by => _recommended_by;

  String get token => _token;

  bool get isSeen => _isSeen;

  String get address => _address;

  String get isSett => _isSett;

  String get isSeeen => _isSeeen;

  String get brm => _brmId;

  String get brmCode => _brmCode;

  String get brmName => _brmName;

  bool get isSet => _isSet;

  String get brmAddress => _brmAddress;

  String get brmPhone => _brmPhone;

  String get dateAssigned => _dateAssigned;

  String get location => _location;

  String get state => _state;

  String get userName => _userName;

  String get userId => _userId;

  String get profileId => _profileId;

  String get acctNumber => _acctNumber;

  String get acctName => _acctName;

  String get bankName => _bankName;

  String get businessBrandName => _businessBrandName;

  String get businessType => _businessType;

  String get profileImage => _profileImage;

  String get phone => _phone;

  String get email => _email;

  String get first_name => _first_name;

  String get last_name => _last_name;

  bool get isLoading => _isLoading;

  Color? get color => _color;

  String get reqMessage => _reqMessage;

  String get transactionPin => _transactionPin;

  String get confirmTransactionPin => _confirmTransactionPin;

// logOut()async{
//   final SharedPreferences _pref = await SharedPreferences.getInstance();
//   await _pref.clear();

// }

  saveToken(String token) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('token', token);

    return true;
  }

  saveRefresh(String refresh) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('refresh', refresh);

    return true;
  }

  Future<bool> saveTransactionPin(String transactionPin) async {
    SharedPreferences sharedPreferences = await _pref;
    if (await sharedPreferences.setString('transactionPin', transactionPin)) {
      return true;
    }

    return false;
  }

  saveRecommendedBy(String recommended_by) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('recommended_by', recommended_by);

    return true;
  }

  saveBrmCode(String brmCode) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmCode', brmCode);

    return true;
  }

  saveAddress(String address) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('address', address);

    return true;
  }

  saveSeeen(String isSeeen) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('isSeeen', isSeeen);

    return true;
  }

  saveIsSet(String isSett) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('isSett', isSett);

    return true;
  }

  saveBrmName(String brmName) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmName', brmName);

    return true;
  }

  saveBrmPhone(String? brmPhone) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmPhone', brmPhone!);

    return true;
  }

  saveBrmAddress(String brmAddress) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmAddress', brmAddress);

    return true;
  }

  saveBrmDateAssigned(String brmDateAssigned) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmDateAssigned', brmDateAssigned);

    return true;
  }

  saveLocation(String location) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('location', location);

    return true;
  }

  saveState(String state) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('state', state);

    return true;
  }

  saveUserName(String userName) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('userName', userName);

    return true;
  }

  saveUserId(int userId) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setInt('userId', userId);

    return true;
  }

  saveProfileId(String profileId) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('profileId', profileId);

    return true;
  }

  saveAcctNumber(String acctNumber) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('acctNumber', acctNumber);

    return true;
  }

  saveAcctName(String acctName) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('acctName', acctName);

    return true;
  }

  saveMainCategory(String category) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('category', category);

    return true;
  }

  saveBankName(String bankName) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('bankName', bankName);

    return true;
  }

  saveBusinessBrandName(String businessBrandName) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('businessBrandName', businessBrandName);

    _businessBrandName = businessBrandName;

    return true;
  }

  saveBrmId(String brmId) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('brmId', brmId);

    _businessBrandName = brmId;

    return true;
  }

  saveBusinessType(String businessType) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('businessType', businessType);

    _businessType = businessType;

    return true;
  }

  saveProfileImage(File? image) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('image', image as String);

    return true;
  }

  savePhoneNumber(String phone) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('phone', phone);

    return true;
  }

    saveRole(String role) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('role', role);

    return true;
  }

  saveEmail(String email) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('email', email);

    return true;
  }

    saveFullName(String full_name) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('full_name', full_name);

    return true;
  }

  saveFirstName(String first_name) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('first_name', first_name);

    return true;
  }

  saveLastName(String last_name) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('last_name', last_name);

    return true;
  }

    saveReferalCode(String refCode) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('refCode', refCode);

    return true;
  }

    saveReferalCount(String refCount) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('refCount', refCount);

    return true;
  }

    saveRefererId(String referId) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('referId', referId);

    return true;
  }

   updateStatus(bool status) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setBool('status', status);

    return true;
  }

// Save Profile Photo
  Future<bool> saveBIo(String bio) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('bio', bio);
    return true;
  }

// Save Profile Photo
  Future<bool> saveProfilePhoto(String profilePhotoPath) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('profilePhoto', profilePhotoPath);
    return true;
  }

// Save Cover Photo
  Future<bool> saveCoverPhoto(String coverPhotoPath) async {
    SharedPreferences sharedPreferences = await _pref;
    await sharedPreferences.setString('coverPhoto', coverPhotoPath);
    return true;
  }

// Get Profile Photo
  Future<String> getProfilePhoto() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('profilePhoto')) {
      String profilePhotoPath = sharedPreferences.getString('profilePhoto')!;
      return profilePhotoPath;
    } else {
      return ''; // Return an empty string if no profile photo is saved
    }
  }

// Get Profile Photo
  Future<String> getMainCategory() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('category')) {
      String category = sharedPreferences.getString('category')!;
      return category;
    } else {
      return ''; // Return an empty string if no profile photo is saved
    }
  }

// Get Cover Photo
  Future<String> getCoverPhoto() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('coverPhoto')) {
      String coverPhotoPath = sharedPreferences.getString('coverPhoto')!;
      return coverPhotoPath;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }

// Get Cover Photo
  Future<String> getBio() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('bio')) {
      String bio = sharedPreferences.getString('bio')!;
      return bio;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }

  // Get Cover Photo
  Future<String> getReferId() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('referId')) {
      String referId = sharedPreferences.getString('referId')!;
      return referId;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }


  // Get Cover Photo
  Future<String> getRefCode() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('refCode')) {
      String refCode = sharedPreferences.getString('refCode')!;
      return refCode;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }

  // Get Cover Photo
  Future<String> getRefCount() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('refCount')) {
      String refCount = sharedPreferences.getString('refCount')!;
      return refCount;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }


  // Get Cover Photo
  Future<String> getRole() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('role')) {
      String role = sharedPreferences.getString('role')!;
      return role;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }

  // Get Cover Photo
  Future<String> getFullName() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('full_name')) {
      String fullName = sharedPreferences.getString('full_name')!;
      return fullName;
    } else {
      return ''; // Return an empty string if no cover photo is saved
    }
  }


  // Get vendor status
  Future<bool> getStatus() async {
    SharedPreferences sharedPreferences = await _pref;
    if (sharedPreferences.containsKey('status')) {
      bool status = sharedPreferences.getBool('status')!;
      return status;
    } else {
      return false; // Return an empty string if no cover photo is saved
    }
  }

  // static Future<void> saveNotifications(
  //     List<NotificationElement> notifications) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final notificationData = notifications.map((n) => n.toJson()).toList();
  //   prefs.setString('notifications', notificationData.toString());
  // }

  // static Future<List<NotificationElement>> loadNotifications() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final notificationData = prefs.getString('notifications');
  //   if (notificationData != null) {
  //     final List<dynamic> jsonList = jsonDecode(notificationData);
  //     return jsonList
  //         .map((json) => NotificationElement.fromJson(json))
  //         .toList();
  //   }
  //   return [];
  // }

  Future<String> getToken() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('token')) {
      String data = sharedPreferences.getString('token')!;
      _token = data;

      return data;
    } else {
      _token = '';

      return '';
    }
  }

  Future<String> getAddress() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('address')) {
      String data = sharedPreferences.getString('address')!;
      _address = data;

      return data;
    } else {
      _address = '';

      return '';
    }
  }

  Future<String> getBrmId() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmId')) {
      String data = sharedPreferences.getString('brmId')!;
      _brmId = data;

      return data;
    } else {
      _brmId = '';

      return '';
    }
  }

  Future<String> getBrmCode() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmCode')) {
      String data = sharedPreferences.getString('brmCode')!;
      _brmCode = data;

      return data;
    } else {
      _brmCode = '';

      return '';
    }
  }

  Future<String> getBrmPhone() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmPhone')) {
      String data = sharedPreferences.getString('brmPhone')!;
      _brmPhone = data;

      return data;
    } else {
      _brmPhone = '';

      return '';
    }
  }

  Future<String> getBrmName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmName')) {
      String data = sharedPreferences.getString('brmName')!;
      _brmName = data;

      return data;
    } else {
      _brmName = '';

      return '';
    }
  }

  Future<String> getBrmAddress() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmAddress')) {
      String data = sharedPreferences.getString('brmAddress')!;
      _brmAddress = data;

      return data;
    } else {
      _brmAddress = '';

      return '';
    }
  }

  Future<bool> getIsSeeen() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('isSeeen')) {
      String data = sharedPreferences.getString('isSeeen')!;
      _isSeeen = data;

      return true;
    } else {
      _brmAddress = '';

      return false;
    }
  }

  Future<String> getIsSett() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('isSett')) {
      String data = sharedPreferences.getString('isSett')!;
      _isSett = data;

      return _isSett;
    } else {
      _isSett = 'N/A';

      return _isSett;
    }
  }

  Future<String> getBrmDateAssigned() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('brmDateAssigned')) {
      String data = sharedPreferences.getString('brmDateAssigned')!;
      _dateAssigned = data;

      return data;
    } else {
      _dateAssigned = '';

      return '';
    }
  }

  Future<String> getTransactionPin() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('transactionPin')) {
      String data = sharedPreferences.getString('transactionPin')!;
      _token = data;

      return data;
    } else {
      _token = '';

      return '';
    }
  }

  Future<String> getPhone() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('phone')) {
      String data = sharedPreferences.getString('phone')!;
      _phone = data;

      return data;
    } else {
      _phone = '';

      return '';
    }
  }

  Future<String> getLocation() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('location')) {
      String data = sharedPreferences.getString('location')!;
      _phone = data;

      return data;
    } else {
      _phone = '';

      return '';
    }
  }

  Future<String> getState() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('state')) {
      String data = sharedPreferences.getString('state')!;
      _phone = data;

      return data;
    } else {
      _phone = '';

      return '';
    }
  }

  Future<String> getUserId() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('userId')) {
      String data = sharedPreferences.getString('userId')!;
      _userId = data;

      return data;
    } else {
      _userId = '';

      return '';
    }
  }

  Future<String> getUserName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('userName')) {
      String data = sharedPreferences.getString('userName')!;
      _userName = data;

      return data;
    } else {
      _userName = '';

      return '';
    }
  }

  Future<String> getRecommendedBy() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('recommended_by')) {
      String data = sharedPreferences.getString('recommended_by')!;
      _userName = data;

      return data;
    } else {
      _userName = '';

      return '';
    }
  }

  Future<String> getProfileId() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('profileId')) {
      String data = sharedPreferences.getString('profileId')!;
      _profileId = data;

      return data;
    } else {
      _profileId = '';

      return '';
    }
  }

  Future<String> getAcctNumber() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('acctNumber')) {
      String data = sharedPreferences.getString('acctNumber')!;
      _acctNumber = data;

      return data;
    } else {
      _acctNumber = '';

      return '';
    }
  }

  Future<String> getAcctName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('acctName')) {
      String data = sharedPreferences.getString('acctName')!;
      _acctName = data;

      return data;
    } else {
      _acctName = '';

      return '';
    }
  }

  Future<String> getBankName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('bankName')) {
      String data = sharedPreferences.getString('bankName')!;
      _bankName = data;

      return data;
    } else {
      _bankName = '';

      return '';
    }
  }

  Future<String> getBusinessBrandName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('businessBrandName')) {
      String businessBrandName =
          sharedPreferences.getString('businessBrandName')!;
      _businessBrandName = businessBrandName;

      return businessBrandName;
    } else {
      _businessBrandName = '';

      return '';
    }
  }

  Future<String> getBusinessType() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('businessType')) {
      String businessType = sharedPreferences.getString('businessType')!;
      _businessType = businessType;

      return businessType;
    } else {
      _businessType = '';

      return '';
    }
  }

  Future<String> getProfileImage() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('image')) {
      String data = sharedPreferences.getString('image')!;
      _profileImage = data;

      return data;
    } else {
      _profileImage = '';

      return '';
    }
  }

  Future<String> getEmail() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('email')) {
      String data = sharedPreferences.getString('email')!;
      _email = data;

      return data;
    } else {
      _email = '';

      return '';
    }
  }

  Future<String> getFirstName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('first_name')) {
      String data = sharedPreferences.getString('first_name')!;
      _first_name = data;

      return data;
    } else {
      _first_name = '';

      return '';
    }
  }

  Future<String> getLastName() async {
    SharedPreferences sharedPreferences = await _pref;

    if (sharedPreferences.containsKey('last_name')) {
      String data = sharedPreferences.getString('last_name')!;
      _profileImage = data;

      return data;
    } else {
      _profileImage = '';

      return '';
    }
  }

  Future updateUserP(BuildContext? context) async {
    _isLoading = true;

    final sharedPreferences = await _pref;
    sharedPreferences.clear();

    _isLoading = false;
    _reqMessage = 'Log Out Successfull';
    _color = _color = const Color.fromARGB(255, 15, 175, 20);

    // Navigator.of(context!)
    //     .pushNamedAndRemoveUntil("/OnboardingPage", (route) => false);

    return true;
  }

  Future logOut() async {
    // _isLoading = true;

    final sharedPreferences = await _pref;
    sharedPreferences.clear();

    // _isLoading = false;
    // _reqMessage = 'Log Out Successfull';
    // _color = _color = const Color.fromARGB(255, 15, 175, 20);

    // Navigator.of(context!)
    //     .pushNamedAndRemoveUntil("/OnboardingPage", (route) => false);

    // return true;
  }

  void status(status) {}


  // ── Theme mode ───────────────────────────────────────────────────────────
  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', themeMode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode');
  }

  // ── Chapter reading progress ──────────────────────────────────────────────
  Future<void> saveChapterProgress(Map<int, double> progress) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert to string map for storage
    final map = progress.map((k, v) => MapEntry(k.toString(), v.toString()));
    await prefs.setString('chapter_progress',
        map.entries.map((e) => '${e.key}:${e.value}').join(','));
  }

  Future<Map<int, double>?> getChapterProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('chapter_progress');
    if (raw == null || raw.isEmpty) { return null; }
    try {
      final map = <int, double>{};
      for (final entry in raw.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final k = int.tryParse(parts[0]);
          final v = double.tryParse(parts[1]);
          if (k != null && v != null) { map[k] = v; }
        }
      }
      return map;
    } catch (_) {
      return null;
    }
  }


}