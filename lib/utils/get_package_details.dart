import 'package:baatu/methods/print_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppPackageDetails {
  static String? appName;
  static String? packageName;
  static String? version;
  static String? buildNumber;

  static Future<void> getPackageDetails() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appName = packageInfo.appName;
      packageName = packageInfo.packageName;
      version = packageInfo.version;
      buildNumber = packageInfo.buildNumber;

      printmsg({
        "appName": appName,
        "packageName": packageName,
        "version": version,
        "buildNumber": buildNumber
      });
    } on Exception catch (error) {
      printmsg({"error": error});
    }
  }
}
