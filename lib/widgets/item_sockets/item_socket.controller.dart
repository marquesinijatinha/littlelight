// @dart=2.9

import 'package:bungie_api/enums/destiny_energy_type.dart';
import 'package:bungie_api/enums/socket_plug_sources.dart';
import 'package:bungie_api/exceptions.dart';
import 'package:bungie_api/models/destiny_energy_capacity_entry.dart';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_item_plug_base.dart';
import 'package:bungie_api/models/destiny_item_socket_category_definition.dart';
import 'package:bungie_api/models/destiny_item_socket_state.dart';
import 'package:bungie_api/models/destiny_plug_set_definition.dart';
import 'package:flutter/widgets.dart';
import 'package:little_light/models/bungie_api.exception.dart';
import 'package:little_light/models/character_sort_parameter.dart';
import 'package:little_light/services/analytics/analytics.consumer.dart';
import 'package:little_light/services/bungie_api/bungie_api.consumer.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/notification/notification.package.dart';
import 'package:little_light/services/profile/profile.consumer.dart';
import 'package:little_light/utils/destiny_data.dart';

class ItemSocketController extends ChangeNotifier
    with BungieApiConsumer, ProfileConsumer, ManifestConsumer, NotificationConsumer, AnalyticsConsumer {
  final DestinyItemComponent item;
  final DestinyInventoryItemDefinition definition;
  List<DestinyItemSocketState> socketStates;
  List<bool> _socketBusy;
  Map<String, List<DestinyItemPlugBase>> reusablePlugs;
  List<int> _selectedSockets;
  List<int> _randomizedSelectedSockets;
  Map<int, DestinyInventoryItemDefinition> _plugDefinitions;
  Map<int, DestinyPlugSetDefinition> _plugSetDefinitions;

  Map<int, DestinyInventoryItemDefinition> get plugDefinitions => _plugDefinitions;
  int _selectedSocket;
  int _selectedSocketIndex;
  int _armorTierIndex;

  DestinyEnergyCapacityEntry get armorEnergyCapacity {
    if (_armorTierIndex == null) return null;
    if (_plugDefinitions == null) return null;
    var plugHash = socketEquippedPlugHash(_armorTierIndex);
    var def = _plugDefinitions[plugHash];
    return def?.plug?.energyCapacity;
  }

  DestinyEnergyType get armorEnergyType {
    return armorEnergyCapacity?.energyType;
  }

  int get usedEnergy {
    var energy = 0;
    for (var i = 0; i < socketCount; i++) {
      var plugHash = socketSelectedPlugHash(i);
      var def = plugDefinitions[plugHash];
      energy += def?.plug?.energyCost?.energyCost ?? 0;
    }
    return energy;
  }

  int get usedEnergyWithoutFailedSocket {
    var energy = 0;
    for (var i = 0; i < socketCount; i++) {
      var plugHash = socketSelectedPlugHash(i);
      var def = plugDefinitions[plugHash];
      if (selectedSocketIndex != i || selectedPlugHash == plugHash) {
        energy += def?.plug?.energyCost?.energyCost ?? 0;
      }
    }
    return energy;
  }

  int get requiredEnergy {
    var socketSelectedHash = socketSelectedPlugHash(_selectedSocketIndex);
    var used = usedEnergy;
    if (socketSelectedHash == selectedPlugHash) return used;
    var def = plugDefinitions[selectedPlugHash];
    var currentDef = plugDefinitions[socketSelectedHash];
    var selectedEnergy = def?.plug?.energyCost?.energyCost ?? 0;
    var currentEnergy = currentDef?.plug?.energyCost?.energyCost ?? 0;
    var energy = used - currentEnergy + selectedEnergy;
    return energy;
  }

  int get socketCount => definition?.sockets?.socketEntries?.length ?? 0;

  List<int> get selectedSockets => _selectedSockets;
  List<int> get randomizedSelectedSockets => _randomizedSelectedSockets;

  ItemSocketController({this.item, this.definition, this.socketStates, this.reusablePlugs}) {
    _initDefaults();
    _loadPlugDefinitions();
  }

  _initDefaults() {
    var entries = definition?.sockets?.socketEntries;
    socketStates = socketStates ?? profile.getItemSockets(item?.itemInstanceId);
    reusablePlugs = reusablePlugs ?? profile.getItemReusablePlugs(item?.itemInstanceId);
    _selectedSockets = List<int>.filled(entries?.length ?? 0, null);
    _randomizedSelectedSockets = List<int>.filled(entries?.length ?? 0, null);
    _socketBusy = List<bool>.generate(socketStates?.length ?? 0, (index) => false);
  }

  Future<void> _loadPlugDefinitions() async {
    Set<int> plugHashes = Set();
    if (reusablePlugs != null) {
      plugHashes = socketStates
          .expand((socket) {
            Set<int> hashes = Set();
            hashes.add(socket.plugHash);
            return hashes;
          })
          .where((i) => (i ?? 0) != 0)
          .toSet();
      reusablePlugs?.forEach((hash, reusable) {
        plugHashes.addAll(reusable.map((r) => r.plugItemHash));
      });
    }
    Set<int> plugSetHashes = definition?.sockets?.socketEntries
        ?.expand((s) => [s.reusablePlugSetHash, s.randomizedPlugSetHash])
        ?.where((h) => ((h ?? 0) != 0))
        ?.toSet();
    if (plugSetHashes == null) return;
    _plugSetDefinitions = await manifest.getDefinitions<DestinyPlugSetDefinition>(plugSetHashes);

    List<int> socketTypeHashes = [];
    var definitionPlugHashes = definition?.sockets?.socketEntries
        ?.expand((socket) {
          socketTypeHashes.add(socket.socketTypeHash);
          List<int> hashes = [];
          hashes.add(socket.singleInitialItemHash);
          hashes.addAll(socket.reusablePlugItems?.map((p) => p.plugItemHash) ?? []);
          DestinyPlugSetDefinition reusablePlugSet = _plugSetDefinitions[socket.reusablePlugSetHash];
          DestinyPlugSetDefinition randomizedPlugSet = _plugSetDefinitions[socket.randomizedPlugSetHash];
          hashes.addAll(reusablePlugSet?.reusablePlugItems?.map((i) => i?.plugItemHash) ?? []);
          hashes.addAll(randomizedPlugSet?.reusablePlugItems?.map((i) => i?.plugItemHash) ?? []);
          return hashes;
        })
        ?.where((i) => (i ?? 0) != 0)
        ?.toSet();

    plugHashes.addAll(definitionPlugHashes);
    _plugDefinitions = await manifest.getDefinitions<DestinyInventoryItemDefinition>(plugHashes);

    DestinyItemSocketCategoryDefinition armorTierCategory = definition?.sockets?.socketCategories
        ?.firstWhere((s) => DestinyData.socketCategoryTierHashes?.contains(s.socketCategoryHash), orElse: () => null);
    _armorTierIndex = armorTierCategory?.socketIndexes?.first;
    notifyListeners();
  }

  int get selectedSocketIndex => _selectedSocketIndex;
  int get selectedPlugHash => _selectedSocket;

  void selectSocket(int socketIndex, int plugHash) {
    if (plugHash == this._selectedSocket && socketIndex == _selectedSocketIndex) {
      this._selectedSocket = null;
      this._selectedSocketIndex = null;
    } else {
      this._selectedSocketIndex = socketIndex;
      this._selectedSocket = plugHash;
      var can = canEquip(socketIndex, plugHash);
      if (can) {
        this._selectedSockets[socketIndex] = plugHash;
        var plugHashes = socketPlugHashes(socketIndex);
        if (!(plugHashes?.contains(plugHash) ?? false)) {
          this._randomizedSelectedSockets[socketIndex] = plugHash;
        }
      }
    }
    this.notifyListeners();
  }

  void applySocket(int socketIndex, int plugHash) async {
    String characterID = profile.getItemOwner(item.itemInstanceId) ??
        profile.getCharacters(CharacterSortParameter(type: CharacterSortParameterType.LastPlayed)).last.characterId;
    notifications.push(NotificationEvent(NotificationType.requestApplyPlug, item: this.item, plugHash: plugHash));
    _socketBusy[socketIndex] = true;
    this.notifyListeners();
    try {
      await bungieAPI.applySocket(this.item.itemInstanceId, plugHash, socketIndex, characterID);
      socketStates[socketIndex].plugHash = plugHash;
    } on BungieApiException catch (e, stackTrace) {
      if ([
        PlatformErrorCodes.DestinyCharacterNotInTower,
        PlatformErrorCodes.DestinyCannotPerformActionAtThisLocation,
      ].contains(e.errorCode)) {
        notifications.push(ErrorNotificationEvent(ErrorNotificationType.onCombatZoneApplyModError, item: this.item));
        await Future.delayed(Duration(seconds: 3));
      } else {
        analytics.registerNonFatal(e, stackTrace, additionalInfo: {
          "itemHash": "${this.item?.itemHash}",
          "errorCode": "${e.errorCode}",
          "plugHash": "$plugHash",
          "socketIndex": "$socketIndex"
        });
        rethrow;
      }
    } catch (e, stackTrace) {
      notifications.push(ErrorNotificationEvent(ErrorNotificationType.genericApplyModError, item: this.item));
      await Future.delayed(Duration(seconds: 3));
      analytics.registerNonFatal(e, stackTrace);
    }
    _socketBusy[socketIndex] = false;

    this.notifyListeners();
    notifications.push(NotificationEvent(NotificationType.itemStateUpdate, item: this.item));
  }

  bool isSocketBusy(int socketIndex) {
    if (socketIndex >= _socketBusy.length) return false;
    return _socketBusy[socketIndex] ?? false;
  }

  bool canApplySocket(int socketIndex, int plugHash) {
    return _plugDefinitions[plugHash].allowActions;
  }

  Set<int> socketPlugHashes(int socketIndex) {
    var entry = definition?.sockets?.socketEntries?.elementAt(socketIndex);

    if (socketStates != null) {
      var state = socketStates?.elementAt(socketIndex);
      if (state?.isVisible == false) return null;
      if (state?.plugHash == null) return null;
      Set<int> hashes = Set();
      var isPlugSet = (entry.plugSources.contains(SocketPlugSources.CharacterPlugSet)) ||
          (entry.plugSources.contains(SocketPlugSources.ProfilePlugSet));
      if (isPlugSet) {
        var plugSet = profile.getPlugSets(entry.reusablePlugSetHash);
        hashes.addAll(plugSet.where((p) => p.canInsert).map((p) => p.plugItemHash).where((p) {
          if (_armorTierIndex == null) return true;
          var def = _plugDefinitions[p];
          var energyType = def?.plug?.energyCost?.energyType ?? DestinyEnergyType.Any;
          return (energyType == armorEnergyType || energyType == DestinyEnergyType.Any);
        }).toSet());
      }

      if (reusablePlugs?.containsKey("$socketIndex") ?? false) {
        hashes.addAll(reusablePlugs["$socketIndex"]?.map((r) => r.plugItemHash));
      }
      hashes.add(state.plugHash);
      return hashes.where((h) => h != null).toSet();
    }

    if (!(entry?.defaultVisible ?? false)) {
      return null;
    }

    if (_plugSetDefinitions?.containsKey(entry?.reusablePlugSetHash) ?? false) {
      return _plugSetDefinitions[entry?.reusablePlugSetHash].reusablePlugItems.map((p) => p.plugItemHash).where((p) {
        if (_armorTierIndex == null) return true;
        var def = _plugDefinitions[p];
        var energyType = def?.plug?.energyCost?.energyType ?? DestinyEnergyType.Any;
        return (energyType == armorEnergyType || energyType == DestinyEnergyType.Any);
      }).toSet();
    }

    if ((entry?.reusablePlugItems?.length ?? 0) > 0) {
      return entry?.reusablePlugItems?.map((p) => p.plugItemHash)?.where((h) => h != 0 && h != null)?.toSet();
    }

    if ((entry?.singleInitialItemHash ?? 0) != 0) {
      return [entry?.singleInitialItemHash].toSet();
    }

    return Set();
  }

  Set<int> randomizedPlugHashes(int socketIndex) {
    var entry = definition?.sockets?.socketEntries?.elementAt(socketIndex);
    if ((entry?.randomizedPlugSetHash ?? 0) == 0) return Set();
    if (!(_plugSetDefinitions?.containsKey(entry?.randomizedPlugSetHash) ?? false)) return Set();
    return _plugSetDefinitions[entry?.randomizedPlugSetHash].reusablePlugItems.map((p) => p.plugItemHash).toSet();
  }

  Set<int> otherPlugHashes(int socketIndex) {
    var entry = definition?.sockets?.socketEntries?.elementAt(socketIndex);
    if ((entry?.randomizedPlugSetHash ?? 0) == 0) return Set();
    if (!(_plugSetDefinitions?.containsKey(entry?.randomizedPlugSetHash) ?? false)) return Set();
    return _plugSetDefinitions[entry?.randomizedPlugSetHash].reusablePlugItems.map((p) => p.plugItemHash).toSet();
  }

  List<int> bungieRollPlugHashes(int socketIndex) {
    var entry = definition?.sockets?.socketEntries?.elementAt(socketIndex);

    if ((entry?.reusablePlugItems?.length ?? 0) > 0) {
      return entry?.reusablePlugItems?.map((p) => p.plugItemHash)?.toList();
    }
    if ((entry?.singleInitialItemHash ?? 0) != 0) {
      return [entry.singleInitialItemHash];
    }
    return [];
  }

  int socketEquippedPlugHash(int socketIndex) {
    if (socketStates != null) {
      var state = socketStates?.elementAt(socketIndex);
      return state.plugHash;
    }
    var entry = definition?.sockets?.socketEntries?.elementAt(socketIndex);
    if ((entry?.singleInitialItemHash ?? 0) != 0) {
      return entry?.singleInitialItemHash;
    }
    var socketPlugs = socketPlugHashes(socketIndex);
    if ((socketPlugs?.length ?? 0) > 0) {
      return socketPlugs.first;
    }
    var random = randomizedPlugHashes(socketIndex);
    if ((random?.length ?? 0) > 0) {
      return random.first;
    }
    return null;
  }

  int socketSelectedPlugHash(int socketIndex) {
    if (socketIndex == null) return null;
    var selected = selectedSockets?.elementAt(socketIndex);
    if (selected != null) return selected;
    return socketEquippedPlugHash(socketIndex);
  }

  int socketRandomizedSelectedPlugHash(int socketIndex) {
    var selected = randomizedSelectedSockets?.elementAt(socketIndex);
    if (selected != null) return selected;
    return 2328497849;
  }

  bool canEquip(int socketIndex, int plugHash) {
    var def = plugDefinitions[plugHash];
    var cost = def?.plug?.energyCost?.energyCost;
    if ((cost ?? 0) == 0) return true;
    var selectedDef = plugDefinitions[socketSelectedPlugHash(socketIndex)];
    var selectedCost = selectedDef?.plug?.energyCost?.energyCost ?? 0;
    var energy = usedEnergy - selectedCost + cost;
    return energy <= (armorEnergyCapacity?.capacityValue ?? 0);
  }
}
