import 'package:flutter/material.dart';

class AppColors {
  static const Color kAppColor = Color(0xFF013954);
  static const Color kWhite = Colors.white;
  static const Color kGhostWhite = Color(0xFFf5f5f7);
  static const Color kLightAppColor = Color(0xFF017db9);
  static const Color kShadeGray = Color.fromARGB(255, 32, 32, 32);

  static const Color kMilkyRed = Color.fromARGB(231, 221, 190, 188);
  static Color kBlack = Colors.black;
  static Color kRed = Colors.red;
  static Color kRedAccent = Colors.redAccent;
  static Color kError = const Color(0xFFf8d7da);
  static Color kSuccess = const Color(0xFFd4edda);
  static Color kSuccessLight = const Color(0xFFc5e7cd);
  static const Color kGreen = Colors.green;
  static const Color kGrey = Colors.grey;
  static const Color kMilkyGrey = Color.fromARGB(199, 203, 186, 186);
  static const Color kPurple = Colors.purple;
  static const Color kPurpleA = Colors.purpleAccent;
  static const Color kDeepPurple = Colors.deepPurple;
  static const Color kDeepPurpleA = Colors.deepPurpleAccent;
  static const Color kPink = Colors.pink;
  static const Color kYellow = Colors.yellow;
  static const Color kPinkA = Colors.pinkAccent;
  static const Color kBlue = Colors.blue;
  static const Color kBlueA = Colors.blueAccent;
  static const Color kLightBlue = Colors.lightBlue;
  static const Color kLightBlueA = Colors.lightBlueAccent;
  static const Color kOrange = Colors.orange;
  static const Color kOrangeA = Colors.orangeAccent;
  static const Color kDeepOrange = Colors.deepOrange;
  static const Color kDeepOrangeA = Colors.deepOrangeAccent;
  static const Color kDefaultError = const Color(0xFFBA1A1A);
  static const Color kbuletext = Color(0xFF0B57D0);

  // static const Color kGreenA = Colors.greenAccent;
  // static const Color kLightGreen = Colors.lightGreen;
  // static const Color kLightGreenA = Colors.lightGreenAccent;
  // static const Color kLime = Colors.lime;
  // static const Color kLimeA = Colors.limeAccent;
  // // static const Color kGrey = Colors.grey;
  // static const Color kBlueGrey = Colors.blueGrey;

  // static const Color kIndigo = Colors.indigo;
  // static const Color kIndigoA = Colors.indigoAccent;

  // static const Color kYellowA = Colors.yellowAccent;

  // static const Color kAmber = Colors.amber;
  // static const Color kAmberA = Colors.amberAccent;
  // static const Color kCyan = Colors.cyan;
  // static const Color kCyanA = Colors.cyanAccent;
  // static const Color kTeal = Colors.teal;
  // static const Color kTealA = Colors.tealAccent;
  // static const Color kBrown = Colors.brown;
}

class FontSize {
  static const double size6 = 6.0;
  static const double size8 = 8.0;
  static const double size10 = 10.0;
  static const double size12 = 12.0;
  static const double size14 = 14.0;
  static const double size16 = 16.0;
  static const double size18 = 18.0;
  static const double size20 = 20.0;
  static const double size22 = 22.0;
  static const double size24 = 24.0;
  static const double size26 = 26.0;
}

class AppPadding {
  static double _responsivePadding(BuildContext context, double padding) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return padding *
          0.8; // Adjust the factor based on your design requirements
    } else if (screenWidth < 1000) {
      return padding * 1.0;
    } else {
      return padding * 1.2;
    }
  }

  // Usage: EdgeInsets.all(AppPadding.smallPadding(context))
  static double xxxsmallPadding(BuildContext context) =>
      _responsivePadding(context, 2.0);
  static double xxsmallPadding(BuildContext context) =>
      _responsivePadding(context, 4.0);
  static double xsmallPadding(BuildContext context) =>
      _responsivePadding(context, 6.0);
  static double smallPadding(BuildContext context) =>
      _responsivePadding(context, 8.0);

  static double mediumPadding(BuildContext context) =>
      _responsivePadding(context, 10.0);
  static double xmediumPadding(BuildContext context) =>
      _responsivePadding(context, 12.0);
  static double xxmediumPadding(BuildContext context) =>
      _responsivePadding(context, 14.0);
  static double xxxmediumPadding(BuildContext context) =>
      _responsivePadding(context, 16.0);

  static double largePadding(BuildContext context) =>
      _responsivePadding(context, 18.0);
  static double xLargePadding(BuildContext context) =>
      _responsivePadding(context, 20.0);
  static double xxLargePadding(BuildContext context) =>
      _responsivePadding(context, 22.0);
  static double xxxLargePadding(BuildContext context) =>
      _responsivePadding(context, 24.0);
}

class AppBorderRadius {
  static double _responsiveBorderRadius(BuildContext context, double radius) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 400) {
      return radius * 0.8;
    } else if (screenWidth < 600) {
      return radius * 1.0;
    } else if (screenWidth < 800) {
      return radius * 1.1;
    } else if (screenWidth < 1000) {
      return radius * 1.2;
    } else {
      return radius * 1.3;
    }
  }

  static double xSmall(BuildContext context) =>
      _responsiveBorderRadius(context, 4.0);
  static double small(BuildContext context) =>
      _responsiveBorderRadius(context, 6.0);
  static double medium(BuildContext context) =>
      _responsiveBorderRadius(context, 8.0);
  static double large(BuildContext context) =>
      _responsiveBorderRadius(context, 10.0);
  static double xLarge(BuildContext context) =>
      _responsiveBorderRadius(context, 12.0);
  static double xxLarge(BuildContext context) =>
      _responsiveBorderRadius(context, 14.0);
}

class ImageSize {
  static double _multiplier(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 1.0;
    } else if (screenWidth < 800) {
      return 1.1;
    } else if (screenWidth < 1000) {
      return 1.2;
    } else {
      return 1.3;
    }
  }

  // Set 1
  static double xxxSmallImage(BuildContext context) =>
      80.0 * _multiplier(context);
  static double xxSmallImage(BuildContext context) =>
      100.0 * _multiplier(context);
  static double xSmallImage(BuildContext context) =>
      110.0 * _multiplier(context);
  static double smallImage(BuildContext context) =>
      120.0 * _multiplier(context);

  // Set 2
  static double mediumImage(BuildContext context) =>
      140.0 * _multiplier(context);
  static double xMediumImage(BuildContext context) =>
      160.0 * _multiplier(context);
  static double xxMediumImage(BuildContext context) =>
      180.0 * _multiplier(context);
  static double xxxMediumImage(BuildContext context) =>
      200.0 * _multiplier(context);

  // Set 3
  static double largeImage(BuildContext context) =>
      220.0 * _multiplier(context);
  static double xLargeImage(BuildContext context) =>
      240.0 * _multiplier(context);
  static double xxLargeImage(BuildContext context) =>
      260.0 * _multiplier(context);
  static double xxxLargeImage(BuildContext context) =>
      280.0 * _multiplier(context);
  // Set 4
}

class MySizedBox {
  static double _multiplier(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 1.0;
    } else if (screenWidth < 800) {
      return 1.1;
    } else if (screenWidth < 1000) {
      return 1.2;
    } else {
      return 1.3;
    }
  }

  // Set 1
  static SizedBox xxxSmallBox(BuildContext context) => SizedBox(
        width: 10.0 * _multiplier(context),
        height: 10.0 * _multiplier(context),
      );

  static SizedBox xxSmallBox(BuildContext context) => SizedBox(
        width: 15.0 * _multiplier(context),
        height: 15.0 * _multiplier(context),
      );

  static SizedBox xSmallBox(BuildContext context) => SizedBox(
        width: 20.0 * _multiplier(context),
        height: 20.0 * _multiplier(context),
      );

  static SizedBox smallBox(BuildContext context) => SizedBox(
        width: 25.0 * _multiplier(context),
        height: 25.0 * _multiplier(context),
      );

  // Set 2
  static SizedBox mediumBox(BuildContext context) => SizedBox(
        width: 30.0 * _multiplier(context),
        height: 30.0 * _multiplier(context),
      );

  static SizedBox xMediumBox(BuildContext context) => SizedBox(
        width: 50.0 * _multiplier(context),
        height: 50.0 * _multiplier(context),
      );

  static SizedBox xxMediumBox(BuildContext context) => SizedBox(
        width: 100.0 * _multiplier(context),
        height: 100.0 * _multiplier(context),
      );

  static SizedBox xxxMediumBox(BuildContext context) => SizedBox(
        width: 150.0 * _multiplier(context),
        height: 150.0 * _multiplier(context),
      );

  // Set 3
  static SizedBox largeBox(BuildContext context) => SizedBox(
        width: 220.0 * _multiplier(context),
        height: 220.0 * _multiplier(context),
      );

  static SizedBox xLargeBox(BuildContext context) => SizedBox(
        width: 240.0 * _multiplier(context),
        height: 240.0 * _multiplier(context),
      );

  static SizedBox xxLargeBox(BuildContext context) => SizedBox(
        width: 260.0 * _multiplier(context),
        height: 260.0 * _multiplier(context),
      );

  static SizedBox xxxLargeBox(BuildContext context) => SizedBox(
        width: 300.0 * _multiplier(context),
        height: 300.0 * _multiplier(context),
      );

  // Set 4
}

class ScreenSize {
  static MediaQueryData get mediaQueryData =>
      // ignore: deprecated_member_use
      MediaQueryData.fromView(WidgetsBinding.instance.window);

  // Functions to get constant values based on MediaQuery
  static double get width => mediaQueryData.size.width;
  static double get height => mediaQueryData.size.height;
  static double get devicePixelRatio => mediaQueryData.devicePixelRatio;
  static Orientation get orientation => mediaQueryData.orientation;
}