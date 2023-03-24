import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/user_settings/user_settings.bloc.dart';
import 'package:little_light/models/item_sort_parameter.dart';
import 'package:little_light/models/wishlist_index.dart';
import 'package:little_light/modules/settings/pages/add_wishlist/add_wishlist.page_route.dart';
import 'package:little_light/services/littlelight/wishlists.consumer.dart';
import 'package:little_light/utils/platform_capabilities.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

class SettingsBloc extends ChangeNotifier with WishlistsConsumer {
  final BuildContext context;

  List<ItemSortParameter>? itemOrdering;
  List<ItemSortParameter>? pursuitOrdering;
  Set<String?>? priorityTags;
  List<WishlistFile>? wishlists;
  final UserSettingsBloc _userSetttingsBloc;

  SettingsBloc(BuildContext this.context) : this._userSetttingsBloc = context.read<UserSettingsBloc>() {
    _init();
  }

  _init() async {
    itemOrdering = _userSetttingsBloc.itemOrdering;
    pursuitOrdering = _userSetttingsBloc.pursuitOrdering;
    priorityTags = _userSetttingsBloc.priorityTags;
    wishlists = await wishlistsService.getWishlists();
    notifyListeners();
  }

  bool get tapToSelect => _userSetttingsBloc.tapToSelect;
  set tapToSelect(bool value) {
    _userSetttingsBloc.tapToSelect = value;
    notifyListeners();
  }

  bool get canKeepAwake => PlatformCapabilities.keepScreenOnAvailable;

  bool get keepAwake => _userSetttingsBloc.keepAwake;
  set keepAwake(bool value) {
    _userSetttingsBloc.keepAwake = value;
    notifyListeners();
    Wakelock.toggle(enable: value);
  }

  bool get autoOpenKeyboard => _userSetttingsBloc.autoOpenKeyboard;
  set autoOpenKeyboard(bool value) {
    _userSetttingsBloc.autoOpenKeyboard = value;
    notifyListeners();
  }

  bool get enabledAutoTransfers => _userSetttingsBloc.enableAutoTransfers;

  set enabledAutoTransfers(bool value) {
    _userSetttingsBloc.enableAutoTransfers = value;
    notifyListeners();
  }

  int get defaultFreeSlots => _userSetttingsBloc.defaultFreeSlots;
  set defaultFreeSlots(int value) {
    _userSetttingsBloc.defaultFreeSlots = value;
    notifyListeners();
  }

  void addWishlist() async {
    await Navigator.push(context, AddWishlistPageRoute());
    wishlists = await wishlistsService.getWishlists();
    notifyListeners();
  }

  void removeWishlist(WishlistFile w) async {
    await wishlistsService.removeWishlist(w);
    wishlists = await wishlistsService.getWishlists();
    notifyListeners();
  }
}