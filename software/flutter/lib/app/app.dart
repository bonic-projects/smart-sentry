import 'package:smart_sentry/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:smart_sentry/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:smart_sentry/ui/views/home/home_view.dart';
import 'package:smart_sentry/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:smart_sentry/services/location_service.dart';
import 'package:smart_sentry/ui/views/login/login_view.dart';
import 'package:smart_sentry/ui/views/register/register_view.dart';
import 'package:smart_sentry/services/auth_service.dart';
import 'package:smart_sentry/ui/views/location/location_view.dart';

import 'package:smart_sentry/ui/views/notification/notification_view.dart';
import 'package:smart_sentry/services/firebase_service.dart';

// @stacked-import

@StackedApp(routes: [
  MaterialRoute(page: HomeView),
  MaterialRoute(page: StartupView),
  MaterialRoute(page: LoginView),
  MaterialRoute(page: RegisterView),
  MaterialRoute(page: LocationView),

  MaterialRoute(page: NotificationView),
// @stacked-route
], dependencies: [
  LazySingleton(classType: SnackbarService),
  LazySingleton(classType: BottomSheetService),
  LazySingleton(classType: DialogService),
  LazySingleton(classType: NavigationService),
  LazySingleton(classType: LocationService),
  LazySingleton(classType: UserService),
  LazySingleton(classType: FirebaseService),


// @stacked-service
], bottomsheets: [
  StackedBottomsheet(classType: NoticeSheet),
  // @stacked-bottom-sheet
], dialogs: [
  StackedDialog(classType: InfoAlertDialog),
  // @stacked-dialog
], logger: StackedLogger())
class App {}
