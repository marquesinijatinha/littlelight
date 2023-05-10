import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/inventory/inventory.bloc.dart';
import 'package:little_light/models/item_info/inventory_item_info.dart';
import 'package:little_light/core/blocs/profile/profile.bloc.dart';
import 'package:little_light/shared/blocs/socket_controller/socket_controller.bloc.dart';
import 'package:little_light/shared/utils/helpers/plug_helpers.dart';
import 'package:provider/provider.dart';

class InventoryItemSocketControllerBloc extends SocketControllerBloc<InventoryItemInfo> {
  InventoryBloc _inventoryBloc;
  ProfileBloc _profileBloc;

  @protected
  InventoryItemInfo? item;

  bool _isBusy = false;

  InventoryItemSocketControllerBloc(BuildContext context)
      : _inventoryBloc = context.read<InventoryBloc>(),
        _profileBloc = context.read<ProfileBloc>(),
        super(context);

  @override
  Future<void> init(InventoryItemInfo item) async {
    final hash = item.itemHash;
    this.item = item;
    if (hash == null) return;
    await loadDefinitions(hash);
  }

  @override
  Future<void> update(InventoryItemInfo item) async {
    this.item = item;
    this.refresh();
  }

  @protected
  Future<List<int>?> loadAvailablePlugHashesForSocket(int index) async {
    if (item?.sockets?[index].isVisible == false) {
      return null;
    }
    final socketDef = itemDefinition?.sockets?.socketEntries?[index];
    final plugSources = socketDef?.plugSources;
    final reusablePlugSetHash = socketDef?.reusablePlugSetHash;
    final randomizedPlugSetHash = socketDef?.randomizedPlugSetHash;
    final hashes = <int>[];
    List<List<DestinyItemPlug>> plugSetList = [];
    if (plugSources?.contains(SocketPlugSources.ReusablePlugItems) ?? false) {
      final reusableHashes = item?.reusablePlugs?["$index"]?.map((e) => e.plugItemHash).whereType<int>().toList();
      if (reusableHashes != null) hashes.addAll(reusableHashes);
    }
    if (plugSources?.contains(SocketPlugSources.ProfilePlugSet) ?? false) {
      if (reusablePlugSetHash != null) {
        final plugSet = _profileBloc.getProfilePlugSets(reusablePlugSetHash);
        if (plugSet != null) plugSetList.add(plugSet);
      }
      if (randomizedPlugSetHash != null) {
        final plugSet = _profileBloc.getProfilePlugSets(randomizedPlugSetHash);
        if (plugSet != null) plugSetList.add(plugSet);
      }
    }
    if (plugSources?.contains(SocketPlugSources.CharacterPlugSet) ?? false) {
      final characterId = item?.characterId;
      if (characterId != null) {
        if (reusablePlugSetHash != null) {
          final plugSet = _profileBloc.getCharacterPlugSets(characterId, reusablePlugSetHash);
          if (plugSet != null) plugSetList.add(plugSet);
        }
        if (randomizedPlugSetHash != null) {
          final plugSet = _profileBloc.getCharacterPlugSets(characterId, randomizedPlugSetHash);
          if (plugSet != null) plugSetList.add(plugSet);
        }
      }
    }

    plugSetList.forEach((plugSet) {
      final plugSetHashes = (plugSet)
          .where((element) {
            final canInsert = element.canInsert ?? false;
            final enabled = element.enabled ?? false;
            return canInsert && enabled;
          })
          .map((e) => e.plugItemHash)
          .whereType<int>()
          .toSet();
      hashes.addAll(plugSetHashes);
    });
    if (plugSources?.contains(SocketPlugSources.InventorySourced) ?? false) {
      final typeDefinition = await manifest.getDefinition<DestinySocketTypeDefinition>(socketDef?.socketTypeHash);
      final categories = typeDefinition?.plugWhitelist?.map((p) => p.categoryHash);
      final itemHashes = _profileBloc.allItems.map((e) => e.itemHash).whereType<int>();
      final itemDefinitions = await manifest.getDefinitions<DestinyInventoryItemDefinition>(itemHashes);
      final matchedItems =
          itemDefinitions.values.where((def) => categories?.contains(def.plug?.plugCategoryHash) ?? false);
      hashes.addAll(matchedItems.map((e) => e.hash).whereType<int>());
    }
    final equippedPlugHash = item?.sockets?[index].plugHash;
    if (equippedPlugHash != null) hashes.add(equippedPlugHash);
    return hashes.toSet().toList();
  }

  @override
  bool isEquipped(int socketIndex, int plugHash) {
    return item?.sockets?[socketIndex].plugHash == plugHash;
  }

  @override
  int? equippedPlugHashForSocket(int? socketIndex) {
    if (socketIndex == null) return null;
    return item?.sockets?[socketIndex].plugHash;
  }

  @override
  List<DestinyObjectiveProgress>? getPlugObjectives(int plugHash) {
    return item?.plugObjectives?["$plugHash"];
  }

  @override
  void applyPlug(int socketIndex, int plugHash) async {
    final item = this.item;
    if (item == null) return;
    _isBusy = true;
    notifyListeners();
    await _inventoryBloc.applyPlugs(item, {socketIndex: plugHash});
    _isBusy = false;
    notifyListeners();
  }

  @override
  bool get isBusy => _isBusy;

  @override
  Future<List<int>?> loadRandomPlugHashesForSocket(int selectedIndex) async => null;

  @override
  Future<bool> calculateCanApplySelectedPlug() async {
    final item = this.item;
    if (item == null) return false;
    final socketIndex = selectedSocketIndex;
    final plugHash = selectedPlugHashForSocket(socketIndex);
    final plugDef = await manifest.getDefinition<DestinyInventoryItemDefinition>(plugHash);
    final materialCost = await manifest.getDefinition<DestinyMaterialRequirementSetDefinition>(
      plugDef?.plug?.insertionMaterialRequirementHash,
    );
    final canApply = canApplyPlug(context, item, socketIndex, plugHash, plugDef, materialCost);
    if (!canApply) return false;
    final availableEnergy = availableEnergyCapacity?.equipped ?? 0;
    final usedEnergy = usedEnergyCapacity?.equipped ?? 0;
    final requiredEnergy = plugDef?.plug?.energyCost?.energyCost ?? 0;
    if (usedEnergy + requiredEnergy > availableEnergy) return false;
    return true;
  }
}