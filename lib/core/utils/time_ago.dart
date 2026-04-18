import 'package:timeago/timeago.dart' as timeago;

class TimeAgoFormatter {
  static String format(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'en_short');
  }
}
