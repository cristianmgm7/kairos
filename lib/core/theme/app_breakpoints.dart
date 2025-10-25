class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1440;

  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}
