import 'package:bungie_api/destiny2.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/profile/destiny_character_info.dart';
import 'package:little_light/core/blocs/profile/destiny_item_info.dart';
import 'package:little_light/core/blocs/profile/profile.bloc.dart';
import 'package:little_light/core/blocs/profile/sorters.dart';
import 'package:little_light/core/blocs/selection/selection.bloc.dart';
import 'package:little_light/core/blocs/user_settings/user_settings.bloc.dart';
import 'package:little_light/models/game_data.dart';
import 'package:little_light/modules/search/pages/quick_transfer/quick_transfer.page_route.dart';
import 'package:little_light/pages/item_details/item_details.page_route.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/littlelight/littlelight_data.consumer.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/user_settings/little_light_persistent_page.dart';
import 'package:little_light/shared/utils/sorters/items/multi_sorter.dart';
import 'package:provider/provider.dart';

class _CharacterProgressState {
  List<DestinyItemInfo> pursuits = [];
  List<DestinyMilestone> raidMilestones = [];
  List<DestinyMilestone> milestones = [];
  List<DestinyProgression> primaryRanks = [];
  List<DestinyProgression> secondaryRanks = [];
}

class _ProgressState {
  Map<String, _CharacterProgressState> charactersProgress = {};

  void addPursuit(DestinyItemInfo item) {
    final characterId = item.characterId;
    if (characterId == null) return;
    final characterProgress = this.charactersProgress[characterId] ??= _CharacterProgressState();
    characterProgress.pursuits.add(item);
  }
}

class ProgressBloc extends ChangeNotifier with ManifestConsumer, LittleLightDataConsumer {
  final BuildContext _context;
  final ProfileBloc _profileBloc;
  final SelectionBloc _selectionBloc;
  final UserSettingsBloc _userSettingsBloc;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  PageStorageBucket get pageStorageBucket => _pageStorageBucket;
  GameData? _gameData;

  _ProgressState _equipmentState = _ProgressState();

  ProgressBloc(this._context)
      : _profileBloc = _context.read<ProfileBloc>(),
        _selectionBloc = _context.read<SelectionBloc>(),
        _userSettingsBloc = _context.read<UserSettingsBloc>() {
    _init();
  }
  _init() {
    _userSettingsBloc.startingPage = LittleLightPersistentPage.Progress;
    _profileBloc.addListener(_update);
    _userSettingsBloc.addListener(_update);
    _update();
    _loadGameData();
  }

  void _loadGameData() async {
    _gameData = await littleLightData.getGameData();
    notifyListeners();
  }

  @override
  void dispose() {
    _profileBloc.removeListener(_update);
    super.dispose();
  }

  void _update() async {
    final equipmentState = _ProgressState();
    final parameters = _userSettingsBloc.itemOrdering;
    List<DestinyItemInfo> items = _profileBloc.allItems;
    final characters = _profileBloc.characters;

    if (parameters != null && characters != null) {
      final hashes = items.map((e) => e.itemHash).whereType<int>();
      final definitions = await manifest.getDefinitions<DestinyInventoryItemDefinition>(hashes);
      final sorters = getSortersFromStorage(parameters, _context, definitions, characters);
      items = await MultiSorter(sorters).sort(_profileBloc.allItems);
    }

    Set<int> categories = {};
    final pursuits = items.where((i) => i.bucketHash == InventoryBucket.pursuits);

    for (final item in pursuits) {
      final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.itemHash);
      final categoryHashes = def?.itemCategoryHashes;
      if (categoryHashes != null) categories.addAll(categoryHashes);
      equipmentState.addPursuit(item);
    }

    final categoryDefs = await manifest.getDefinitions<DestinyItemCategoryDefinition>(categories);

    _equipmentState = equipmentState;
    notifyListeners();
  }

  List<DestinyCharacterInfo>? get characters => _profileBloc.characters;

  List<DestinyItemInfo>? getUnequippedItems(DestinyCharacterInfo character, int bucketHash) {
    final characterId = character.characterId;
    if (characterId == null) return null;
    return _equipmentState.charactersProgress[characterId]?.pursuits;
  }

  List<DestinyItemComponent>? get relevantCurrencies {
    final allCurrencies = _profileBloc.currencies;
    if (allCurrencies == null) return null;
    final relevant = _gameData?.relevantCurrencies;
    if (relevant == null) return null;
    return relevant
        .map((r) => allCurrencies.firstWhereOrNull((c) => c.itemHash == r))
        .whereType<DestinyItemComponent>()
        .toList();
  }

  void onItemTap(DestinyItemInfo item) {
    final hash = item.itemHash;
    final instanceId = item.instanceId;
    final stackIndex = item.stackIndex;

    if (hash == null) return;

    if (_selectionBloc.hasSelection || _userSettingsBloc.tapToSelect) {
      return _selectionBloc.toggleSelected(
        hash,
        instanceId: instanceId,
        stackIndex: stackIndex,
      );
    }

    Navigator.of(_context).push(ItemDetailsPageRoute.itemInfo(item: item));
  }

  void onItemHold(DestinyItemInfo item) {
    final hash = item.itemHash;
    final instanceId = item.instanceId;
    final stackIndex = item.stackIndex;
    if (hash == null) return;
    if (_userSettingsBloc.tapToSelect) {
      Navigator.of(_context).push(ItemDetailsPageRoute.itemInfo(item: item));
      return;
    }
    return _selectionBloc.toggleSelected(
      hash,
      instanceId: instanceId,
      stackIndex: stackIndex,
    );
  }

  void openSearch(int bucketHash, String characterId) {
    Navigator.of(_context).push(QuickTransferPageRoute(bucketHash: bucketHash, characterId: characterId));
  }
}