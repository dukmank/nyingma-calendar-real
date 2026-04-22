class RouteNames {
  RouteNames._();

  static const String onboarding = '/onboarding';
  static const String shell = '/';
  static const String calendar = '/calendar';
  static const String dayDetail = '/day/:dateKey';
  static const String astrologyDetail = '/astrology/:key';
  static const String auspicious = '/auspicious';
  static const String events = '/events';
  static const String eventDetail = '/events/:id';
  static const String profile = '/profile';
  static const String myPractices = '/my-practices';
  static const String myEvents    = '/my-events';
  static const String createEvent = '/create-event';
  static const String createPractice = '/create-practice';
  static const String search = '/search';

  // News
  static const String news       = '/news';
  static const String newsDetail = '/news/:id';

  // helper để build path có tham số
  static String dayDetailOf(String dateKey) => '/day/$dateKey';
  static String astrologyDetailOf(String key) => '/astrology/$key';
  static String eventDetailOf(String id) => '/events/$id';
  static String newsDetailOf(String id) => '/news/$id';
}
