import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:convert' show json;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:toasty_snackbar/toasty_snackbar.dart';

import '../screens/main_screen.dart';

import '../app_colors.dart';

class StartUpScreen extends StatefulWidget {
  const StartUpScreen({super.key});

  @override
  State<StartUpScreen> createState() => _StartUpScreenState();
}

class _StartUpScreenState extends State<StartUpScreen> {
  ValueNotifier userCredential = ValueNotifier('');
  bool shouldUseFirebaseEmulator = false;
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false; // has granted permissions?
  String _contactText = '';

  static const List<String> scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional clientId
    // clientId: 'your-client_id.apps.googleusercontent.com',
    scopes: scopes,
  );

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
// #docregion CanAccessScopes
      // In mobile, being authenticated means being authorized...
      bool isAuthorized = account != null;
      // However, on web...
      if (kIsWeb && account != null) {
        isAuthorized = await _googleSignIn.canAccessScopes(scopes);
      }
// #enddocregion CanAccessScopes
      print(account);
      setState(() {
        _currentUser = account;
        _isAuthorized = isAuthorized;
      });

      // Now that we know that the user can access the required scopes, the app
      // can call the REST API.
      if (isAuthorized) {
        unawaited(_handleGetContact(account!));
      }
    });

    // In the web, _googleSignIn.signInSilently() triggers the One Tap UX.
    //
    // It is recommended by Google Identity Services to render both the One Tap UX
    // and the Google Sign In button together to "reduce friction and improve
    // sign-in rates" ([docs](https://developers.google.com/identity/gsi/web/guides/display-button#html)).
    _googleSignIn.signInSilently();
  }

  // Calls the People API REST endpoint for the signed-in user to retrieve information.
  Future<void> _handleGetContact(GoogleSignInAccount user) async {
    setState(() {
      _contactText = 'Loading contact info...';
    });
    final http.Response response = await http.get(
      Uri.parse('https://people.googleapis.com/v1/people/me/connections'
          '?requestMask.includeField=person.names'),
      headers: await user.authHeaders,
    );
    if (response.statusCode != 200) {
      setState(() {
        _contactText = 'People API gave a ${response.statusCode} '
            'response. Check logs for details.';
      });
      print('People API ${response.statusCode} response: ${response.body}');
      return;
    }
    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;
    final String? namedContact = _pickFirstNamedContact(data);
    setState(() {
      if (namedContact != null) {
        _contactText = 'I see you know $namedContact!';
      } else {
        _contactText = 'No contacts to display.';
      }
    });
  }

  String? _pickFirstNamedContact(Map<String, dynamic> data) {
    final List<dynamic>? connections = data['connections'] as List<dynamic>?;
    final Map<String, dynamic>? contact = connections?.firstWhere(
      (dynamic contact) => (contact as Map<Object?, dynamic>)['names'] != null,
      orElse: () => null,
    ) as Map<String, dynamic>?;
    if (contact != null) {
      final List<dynamic> names = contact['names'] as List<dynamic>;
      final Map<String, dynamic>? name = names.firstWhere(
        (dynamic name) =>
            (name as Map<Object?, dynamic>)['displayName'] != null,
        orElse: () => null,
      ) as Map<String, dynamic>?;
      if (name != null) {
        return name['displayName'] as String?;
      }
    }
    return null;
  }

  // This is the on-click handler for the Sign In button that is rendered by Flutter.
  //
  // On the web, the on-click handler of the Sign In button is owned by the JS
  // SDK, so this method can be considered mobile only.
  // #docregion SignIn
  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }
  // #enddocregion SignIn

  // Prompts the user to authorize `scopes`.
  //
  // This action is **required** in platforms that don't perform Authentication
  // and Authorization at the same time (like the web).
  //
  // On the web, this must be called from an user interaction (button click).
  // #docregion RequestScopes
  Future<void> _handleAuthorizeScopes() async {
    final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
    // #enddocregion RequestScopes
    setState(() {
      _isAuthorized = isAuthorized;
    });
    // #docregion RequestScopes
    if (isAuthorized) {
      unawaited(_handleGetContact(_currentUser!));
    }
    // #enddocregion RequestScopes
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.myColorTittle,
        centerTitle: true,
        scrolledUnderElevation: 0.0,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: AppColors.myColorBackground,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Container(
          margin: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  margin: const EdgeInsets.all(0.0),
                  width: MediaQuery.of(context).size.width - 50,
                  child: Image.asset("assets/images/concept_set_up.png")),
              Container(
                margin: const EdgeInsets.only(top: 20.0, bottom: 10),
                width: MediaQuery.of(context).size.width - 50,
                child: Text(
                  "Start tracking your money effectively",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      letterSpacing: -1,
                      wordSpacing: 0.0,
                      color: Colors.amber[600],
                      fontSize: 24,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 0.0, bottom: 20),
                width: MediaQuery.of(context).size.width - 50,
                child: const Text(
                  "Keep your data safe by storage it in the cloud.",
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      letterSpacing: -1,
                      wordSpacing: 0.0,
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.normal),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                height: 50.0,
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                          color: Colors.amber), // Set border color here
                    ),
                  ),
                  onPressed: () {
                    // Navigator.pushAndRemoveUntil<dynamic>(
                    //     context,
                    //     MaterialPageRoute<dynamic>(
                    //       builder: (BuildContext context) => const MainScreen(),
                    //     ),
                    //     (route) => false);
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.success,
                      text: 'Transaction Completed Successfully!',
                      autoCloseDuration: const Duration(seconds: 4),
                      showConfirmBtn: false,
                    );
                  },
                  icon: Image.asset(
                    "assets/images/icon/email.png",
                    width: 30,
                    height: 30,
                  ),
                  label: const Text(
                    'បន្តជាមួយអ៊ីមែល',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "Hanuman"),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 10),
                height: 50.0,
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                          color: Colors.amber), // Set border color here
                    ),
                  ),
                  // onPressed: () {
                  // Navigator.pushAndRemoveUntil<dynamic>(
                  //     context,
                  //     MaterialPageRoute<dynamic>(
                  //       builder: (BuildContext context) => MainScreen(),
                  //     ),
                  //     (route) => false);

                  // },
                  onPressed: () async {
                    _handleSignIn();
                    // Navigator.of(context).pushReplacement(
                    //   MaterialPageRoute(
                    //     builder: (context) => UserInfoScreen(
                    //       user: user,
                    //     ),
                    //   ),
                    // Navigator.pushAndRemoveUntil<dynamic>(
                    //     context,
                    //     MaterialPageRoute<dynamic>(
                    //       builder: (BuildContext context) => const MainScreen(),
                    //     ),
                    //     (route) => false);
                  },
                  icon: Image.asset(
                    "assets/images/icon/google.png",
                    width: 30,
                    height: 30,
                  ),
                  label: const Text(
                    'បន្តជាមួយ Google',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "Hanuman"),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 5, bottom: 5),
                height: 50.0,
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                          color: Colors.amber), // Set border color here
                    ),
                  ),
                  onPressed: () {
                    _handleAuthorizeScopes();
                    // Navigator.pushAndRemoveUntil<dynamic>(
                    //     context,
                    //     MaterialPageRoute<dynamic>(
                    //       builder: (BuildContext context) => const MainScreen(),
                    //     ),
                    //     (route) => false);
                  },
                  icon: Image.asset(
                    "assets/images/icon/facebook.png",
                    width: 30,
                    height: 30,
                  ),
                  label: const Text(
                    'បន្តជាមួយ Facebook',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: "Hanuman"),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
