import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String userPoolId = 'us-east-1_uURcM4sRF';
  static const String clientId = 'fdrrjsisptunj35bh2hmosqs7';

  final userPool = CognitoUserPool(userPoolId, clientId);

  // SIGN UP
  Future<String> signUp(String email, String password, String name) async {
    try {
      final userAttributes = [
        AttributeArg(name: 'name', value: name),
        AttributeArg(name: 'email', value: email),
      ];
      await userPool.signUp(email, password, userAttributes: userAttributes);
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // CONFIRM SIGN UP (OTP)
  Future<String> confirmSignUp(String email, String code) async {
    try {
      final cognitoUser = CognitoUser(email, userPool);
      await cognitoUser.confirmRegistration(code);
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // SIGN IN
  Future<String> signIn(String email, String password) async {
    try {
      final cognitoUser = CognitoUser(email, userPool);
      final authDetails = AuthenticationDetails(
        username: email,
        password: password,
      );
      final session = await cognitoUser.authenticateUser(authDetails);
      if (session != null && session.isValid()) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('token', session.idToken.jwtToken ?? '');
        await prefs.setString('tier', 'free');
        return 'success';
      }
      return 'Login failed';
    } catch (e) {
      return e.toString();
    }
  }

  // SIGN OUT
  Future<void> signOut(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    await cognitoUser.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // GET CURRENT USER
  Future<Map<String, String>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString('email') ?? '',
      'tier': prefs.getString('tier') ?? 'free',
      'token': prefs.getString('token') ?? '',
    };
  }

  // CHECK IF LOGGED IN
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null &&
        prefs.getString('token')!.isNotEmpty;
  }
}
