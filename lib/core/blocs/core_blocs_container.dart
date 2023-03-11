import 'package:little_light/modules/loadouts/blocs/loadouts.bloc.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/user_settings/user_settings.consumer.dart';
import 'package:provider/provider.dart';

import '../../shared/blocs/context_menu_options/context_menu_options.bloc.dart';
import 'app_lifecycle/app_lifecycle.bloc.dart';
import 'inventory/inventory.bloc.dart';
import 'language/language.bloc.dart';
import 'language/language.consumer.dart';
import 'notifications/notifications.bloc.dart';
import 'offline_mode/offline_mode.bloc.dart';
import 'profile/profile.bloc.dart';
import 'profile/profile.consumer.dart';
import 'selection/selection.bloc.dart';
import 'user_settings/user_settings.bloc.dart';

class CoreBlocsContainer extends MultiProvider {
  CoreBlocsContainer()
      : super(
          providers: [
            ChangeNotifierProvider<UserSettingsBloc>(create: (context) => getInjectedUserSettings()),
            ChangeNotifierProvider(create: (context) => AppLifecycleBloc()),
            ChangeNotifierProvider(create: (context) => OfflineModeBloc()),
            Provider(create: (context) => getInjectedManifestService().initContext(context)),
            ChangeNotifierProvider<LanguageBloc>(create: (context) => getInjectedLanguageService()),
            ChangeNotifierProvider<ProfileBloc>(create: (context) => getInjectedProfileService()),
            ChangeNotifierProvider<NotificationsBloc>(create: (context) => NotificationsBloc()),
            ChangeNotifierProvider<InventoryBloc>(create: (context) => InventoryBloc(context)),
            ChangeNotifierProvider<LoadoutsBloc>(create: (context) => LoadoutsBloc()),
            ChangeNotifierProvider<SelectionBloc>(create: (context) => SelectionBloc(context)),
            ChangeNotifierProvider<ContextMenuOptionsBloc>(create: (context) => ContextMenuOptionsBloc(context)),
          ],
        );
}
