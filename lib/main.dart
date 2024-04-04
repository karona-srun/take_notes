import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:take_notes/screens/start_up_screen.dart';
import '../screens/take_note_screen.dart';
import 'app_colors.dart';
import '../screens/home_screen.dart';
import 'screens/profile_screen.dart';

bool shouldUseFirebaseEmulator = false;

late final FirebaseApp app;
late final FirebaseAuth auth;

Future<void> main() async {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.black.withOpacity(0), //top bar color
      statusBarIconBrightness: Brightness.dark, //top bar icons
      systemNavigationBarColor: Colors.white, //bottom bar color
      systemNavigationBarIconBrightness: Brightness.dark, //bottom bar icons
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'កត់ត្រា',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 255, 255, 255)),
        primarySwatch: Colors.orange,
        primaryColor: Colors.black,
        highlightColor: AppColors.myColorBackground,
        focusColor: AppColors.myColorBackground,
        splashColor: AppColors.myColorBackground,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const StartUpScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PageController pageController = PageController();
  int _currentIndex = 0;
  bool keyboardOpen = false;
  final List<Widget> _tabs = [
    const HomeScreen(),
    const TakeNoteScreen(),
    const ProfileScreen(),
  ];
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardIsOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.myColorTittle,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (_) {
          // FocusScope.of(context).requestFocus(FocusNode());
          // FocusManager.instance.primaryFocus?.unfocus();
        },
        child: PageView(controller: pageController, children: <Widget>[
          _tabs[_currentIndex],
        ]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Visibility(
        visible: !keyboardIsOpen,
        child: Container(
          margin: EdgeInsets.only(top: 0),
          width: 60,
          height: 60,
          child: FloatingActionButton(
            backgroundColor: Colors.orange,
            splashColor: Colors.orange,
            onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            },
            elevation: 0,
            shape: RoundedRectangleBorder(
                side: BorderSide(width: 2, color: Colors.orange),
                borderRadius: BorderRadius.circular(100)),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        fixedColor: AppColors.myColorActiveIcon,
        backgroundColor: AppColors.myColorTittle,
        unselectedItemColor: AppColors.myColorIcon,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Hanuman',
          color: AppColors.myColorIcon,
          fontWeight: FontWeight.w500,
        ),
        selectedLabelStyle: TextStyle(
          fontFamily: 'Hanuman',
          color: AppColors.myColorActiveIcon,
          fontWeight: FontWeight.w500,
        ),
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 0),
            curve: Curves.ease,
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icon/notes_outline.png',
                color: AppColors.myColorIcon,
                width: 24,
                height: 24,
                fit: BoxFit.cover),
            activeIcon: Image.asset('assets/images/icon/notes.png',
                color: AppColors.myColorActiveIcon,
                width: 24,
                height: 24,
                fit: BoxFit.cover),
            label: 'ប្រតិបត្តិការ',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add,
              color: AppColors.myColorIcon,
              size: 24,
            ),
            activeIcon: Icon(
              Icons.add,
              color: AppColors.myColorActiveIcon,
              size: 24,
            ),
            label: 'កត់ត្រា',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/images/icon/menu.png',
                color: AppColors.myColorIcon,
                width: 24,
                height: 24,
                fit: BoxFit.cover),
            activeIcon: Image.asset('assets/images/icon/menu_fill.png',
                color: AppColors.myColorActiveIcon,
                width: 24,
                height: 24,
                fit: BoxFit.cover),
            label: 'ផ្សេងទៀត',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
