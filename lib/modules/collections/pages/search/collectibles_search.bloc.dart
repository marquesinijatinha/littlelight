import 'dart:async';

import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/profile/profile.bloc.dart';
import 'package:little_light/core/blocs/selection/selection.bloc.dart';
import 'package:little_light/core/blocs/user_settings/user_settings.bloc.dart';
import 'package:little_light/models/item_info/definition_item_info.dart';
import 'package:little_light/models/item_info/destiny_item_info.dart';
import 'package:little_light/models/item_info/inventory_item_info.dart';
import 'package:little_light/modules/item_details/pages/definition_item_details/definition_item_details.page_route.dart';
import 'package:little_light/services/manifest/manifest.service.dart';
import 'package:little_light/shared/utils/extensions/string/remove_diacritics.dart';
import 'package:provider/provider.dart';

class CollectiblesSearchBloc extends ChangeNotifier {
  final int rootNodeHash;

  @protected
  final BuildContext context;

  @protected
  final ManifestService manifest;

  @protected
  final UserSettingsBloc userSettings;

  @protected
  final ProfileBloc profile;

  @protected
  final SelectionBloc selection;

  Map<int, DefinitionItemInfo>? _genericItems;
  Map<int, List<InventoryItemInfo>>? _inventoryItems;

  List<int>? _filteredItems;
  List<int>? get filteredItems => _filteredItems;

  Timer? _searchTimer;
  String _textSearch = "";
  set textSearch(String value) {
    _textSearch = value;
    final isTimerActive = _searchTimer?.isActive ?? false;
    if (isTimerActive) {
      return;
    }
    _searchTimer = Timer(Duration(milliseconds: 300), () {
      _updateFiltered();
    });
  }

  CollectiblesSearchBloc(this.context, int this.rootNodeHash)
      : manifest = context.read<ManifestService>(),
        userSettings = context.read<UserSettingsBloc>(),
        profile = context.read<ProfileBloc>(),
        selection = context.read<SelectionBloc>(),
        super() {
    _init();
  }

  void _init() {
    profile.addListener(_updateFromProfile);
    loadDefinitions();
  }

  @override
  void dispose() {
    super.dispose();
    profile.removeListener(_updateFromProfile);
  }

  Future<void> loadDefinitions() async {
    final collectibleHashes = await loadChildrenCollectibleHashes(rootNodeHash);
    final collectibleDefinitions = await manifest.getDefinitions<DestinyCollectibleDefinition>(collectibleHashes);
    final itemHashes = collectibleDefinitions.values.map((c) => c.itemHash);
    final itemDefinitions = await manifest.getDefinitions<DestinyInventoryItemDefinition>(itemHashes);

    final genericItems = Map<int, DefinitionItemInfo>();

    for (final h in collectibleHashes) {
      final itemHash = collectibleDefinitions[h]?.itemHash;
      final def = itemDefinitions[itemHash];
      if (def == null) continue;
      final item = DefinitionItemInfo.fromDefinition(def);
      genericItems[h] = item;
    }
    _genericItems = genericItems;
    _updateFromProfile();
  }

  void _updateFromProfile() {
    final genericItems = _genericItems;
    if (genericItems == null) return;
    final inventoryItems = Map<int, List<InventoryItemInfo>>();
    for (final entry in genericItems.entries) {
      inventoryItems[entry.key] = profile.getItemsByHash(entry.value.itemHash);
    }
    _inventoryItems = inventoryItems;
    _updateFiltered();
  }

  Future<void> _updateFiltered() async {
    final filteredItems = <int>[];
    final genericItems = _genericItems?.values;
    if (genericItems == null) return;
    final hideUnachievable = userSettings.hideUnavailableCollectibles;
    final search = removeDiacritics(_textSearch.toLowerCase().trim());
    for (final item in genericItems) {
      final definition = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.itemHash);
      final collectibleHash = definition?.collectibleHash;
      if (collectibleHash == null) continue;
      if (hideUnachievable) {
        final profileCollectible = profile.getProfileCollectible(definition?.collectibleHash);
        final isInvisible = profileCollectible?.state?.contains(DestinyCollectibleState.Invisible) ?? false;
        if (isInvisible) continue;
      }
      final name = removeDiacritics(definition?.displayProperties?.name?.toLowerCase().trim() ?? "");
      if (search.isEmpty) {
        filteredItems.add(collectibleHash);
        continue;
      }
      if (name.startsWith(search)) {
        filteredItems.add(collectibleHash);
        continue;
      }
      if (search.length > 3 && name.contains(search)) {
        filteredItems.add(collectibleHash);
        continue;
      }
    }
    _filteredItems = filteredItems;
    notifyListeners();
  }

  Future<Set<int>> loadChildrenCollectibleHashes(int nodeHash) async {
    final definition = await manifest.getDefinition<DestinyPresentationNodeDefinition>(nodeHash);
    final collectibleHashes = definition?.children?.collectibles //
            ?.map((e) => e.collectibleHash)
            .whereType<int>()
            .toSet() ??
        <int>{};
    final presentationNodeHashes = definition?.children?.presentationNodes //
            ?.map((e) => e.presentationNodeHash)
            .whereType<int>()
            .toSet() ??
        <int>{};
    if (presentationNodeHashes.isNotEmpty) {
      await manifest.getDefinitions<DestinyPresentationNodeDefinition>(presentationNodeHashes);
      for (final presentationNodeHash in presentationNodeHashes) {
        collectibleHashes.addAll(await loadChildrenCollectibleHashes(presentationNodeHash));
      }
    }
    return collectibleHashes;
  }

  bool isUnlocked(int? collectibleHash) {
    final profileCollectible = profile.getProfileCollectible(collectibleHash);
    final isLocked = profileCollectible?.state?.contains(DestinyCollectibleState.NotAcquired) ?? false;
    if (isLocked) {
      return false;
    }
    final characters = profile.characters;
    if (characters == null) return false;
    for (final c in characters) {
      final characterCollectible = profile.getCharacterCollectible(c.characterId, collectibleHash);
      final isLocked = characterCollectible?.state?.contains(DestinyCollectibleState.NotAcquired) ?? false;
      if (!isLocked) return true;
    }
    return false;
  }

  DefinitionItemInfo? getGenericItem(int? collectibleHash) {
    return _genericItems?[collectibleHash];
  }

  List<InventoryItemInfo>? getInventoryItems(int? collectibleHash) {
    return _inventoryItems?[collectibleHash];
  }

  void onCollectibleTap(DestinyItemInfo item) {
    final hash = item.itemHash;

    if (hash == null) return;

    if (selection.hasSelection || userSettings.tapToSelect) {
      final items = profile.getItemsByHash(hash);
      if (items.isEmpty) return;
      final areAllSelected = items.every((element) => selection.isItemSelected(element));
      if (areAllSelected) {
        selection.unselectItems(items);
      } else {
        selection.selectItems(items);
      }
      return;
    }

    Navigator.of(context).push(DefinitionItemDetailsPageRoute(hash));
  }

  void onCollectibleHold(DestinyItemInfo item) {
    final hash = item.itemHash;
    if (hash == null) return;

    if (userSettings.tapToSelect) {
      Navigator.of(context).push(DefinitionItemDetailsPageRoute(hash));
      return;
    }

    final items = profile.getItemsByHash(hash);
    if (items.isEmpty) return;

    final allSelected = items.every((element) => selection.isItemSelected(element));
    if (allSelected) {
      selection.unselectItems(items);
    } else {
      selection.selectItems(items);
    }
  }
}
