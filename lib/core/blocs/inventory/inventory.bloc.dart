import 'dart:async';

import 'package:bungie_api/destiny2.dart';
import 'package:bungie_api/enums/platform_error_codes.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/app_lifecycle/app_lifecycle.bloc.dart';
import 'package:little_light/core/blocs/inventory/exceptions/inventory_exceptions.dart';
import 'package:little_light/core/blocs/inventory/transfer_error_messages.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/core/blocs/notifications/notification_actions.dart';
import 'package:little_light/core/blocs/notifications/notifications.bloc.dart';
import 'package:little_light/core/blocs/profile/destiny_item_info.dart';
import 'package:little_light/core/blocs/profile/profile.bloc.dart';
import 'package:little_light/core/blocs/profile/profile_component_groups.dart';
import 'package:little_light/models/bungie_api.exception.dart';
import 'package:little_light/modules/loadouts/blocs/loadout_item_index.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/shared/models/transfer_destination.dart';
import 'package:provider/provider.dart';

const _refreshDelay = Duration(seconds: 30);
const _maxConcurrentTransfers = 5;

class _PutBackTransfer {
  final DestinyItemInfo item;
  final TransferDestination destination;

  _PutBackTransfer(this.item, this.destination);
}

class _QueuedTransfer {
  bool _started = false;
  bool get started => _started;
  bool _cancelled = false;
  bool get cancelled => _cancelled;
  final DestinyItemInfo item;
  final TransferDestination destination;
  final SingleTransferAction? notification;
  final bool equip;
  final int stackSize;

  _QueuedTransfer({
    required this.item,
    required this.destination,
    required this.notification,
    this.equip = false,
    this.stackSize = 1,
  });

  void start() {
    this._started = true;
  }

  void cancel(BuildContext context) {
    this._cancelled = true;
    if (started) {
      notification?.error(
          "Transfer cancelled in favor of a newer transfer on the same item".translate(context, useReadContext: true));
    } else {
      notification?.dismiss();
    }
  }
}

class _BusySlot {
  final TransferDestination destination;
  final int bucketHash;
  _BusySlot({
    required this.destination,
    required this.bucketHash,
  });
}

class InventoryBloc extends ChangeNotifier with ManifestConsumer {
  final BuildContext _context;
  final NotificationsBloc _notificationsBloc;
  final ProfileBloc _profileBloc;
  final AppLifecycleBloc _lifecycleBloc;

  DateTime? _lastUpdated;
  Timer? _updateTimer;

  bool _isBusy = false;
  bool get isBusy => _isBusy;
  bool shouldUseAutoTransfer = true;

  List<String> instanceIdsToAvoid = [];
  final List<_QueuedTransfer> _transferQueue = [];

  InventoryBloc(BuildContext context)
      : _context = context,
        _notificationsBloc = context.read<NotificationsBloc>(),
        _profileBloc = context.read<ProfileBloc>(),
        _lifecycleBloc = context.read<AppLifecycleBloc>();

  init() async {
    await _firstLoad();
    updateInventory();
    //TODO: enable start auto updater
    // _startAutoUpdater();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  _startAutoUpdater() {
    if (_updateTimer?.isActive ?? false) return;
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_lifecycleBloc.isActive) return;
      if (isBusy) return;
      final lastUpdated = _lastUpdated;
      if (lastUpdated == null) return;
      final elapsedTime = DateTime.now().difference(lastUpdated);
      if (elapsedTime > _refreshDelay) {
        print("last refresh was on $lastUpdated, auto-refreshing");
        updateInventory();
      }
    });
  }

  Future<void> _firstLoad() async {
    if (_lastUpdated != null || isBusy) return;
    _isBusy = true;
    notifyListeners();
    await _profileBloc.loadFromStorage();
    _isBusy = false;
    notifyListeners();
  }

  Future<void> updateInventory() async {
    if (isBusy) return;
    final notification = _notificationsBloc.createNotification(UpdateAction());
    try {
      _isBusy = true;
      notifyListeners();
      await _profileBloc.refresh(ProfileComponentGroups.basicProfile);
      _lastUpdated = DateTime.now();
      await Future.delayed(const Duration(seconds: 1));
      _isBusy = false;
      notifyListeners();
      notification.dismiss();
    } catch (e) {
      notification.dismiss();
      _isBusy = false;
      notifyListeners();
      final errorNotification = _notificationsBloc.createNotification(UpdateErrorAction());
      await Future.delayed(const Duration(seconds: 2));
      errorNotification.dismiss();
    }
  }

  Future<void> transfer(
    DestinyItemInfo item,
    TransferDestination destination, {
    int stackSize = 1,
  }) async {
    await _addTransferToQueue(item, destination, stackSize: stackSize);
    await _startTransferQueue();
  }

  Future<void> equip(
    DestinyItemInfo item,
    TransferDestination destination,
  ) async {
    await _addTransferToQueue(item, destination, equip: true);
    await _startTransferQueue();
  }

  Future<void> _addTransferToQueue(
    DestinyItemInfo item,
    TransferDestination destination, {
    bool equip = false,
    int stackSize = 1,
  }) async {
    final sourceCharacter = _profileBloc.getCharacterById(item.characterId);
    final sourceType = item.characterId != null
        ? TransferDestinationType.character
        : item.item.bucketHash == InventoryBucket.general
            ? TransferDestinationType.vault
            : TransferDestinationType.profile;
    final source = TransferDestination(sourceType, character: sourceCharacter);

    final destinationCharacter = destination.character;
    if (sourceCharacter?.characterId == destinationCharacter?.characterId &&
        sourceCharacter?.characterId != null &&
        item.item.bucketHash != InventoryBucket.lostItems &&
        equip == (item.instanceInfo?.isEquipped ?? false)) {
      print("item is already on destination. Skipping.");
      return;
    }
    final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.item.itemHash);
    if (def?.nonTransferrable == true && sourceCharacter?.characterId != destinationCharacter?.characterId) {
      print("can't transfer nonTransferrable item to a different character");
      return;
    }

    final sameItemTranfers = _transferQueue.where(
      (t) =>
          t.item.item.itemInstanceId == item.item.itemInstanceId && //
          t.item.item.itemHash == item.item.itemHash,
    );
    for (final t in sameItemTranfers) {
      t.cancel(_context);
      if (!t.started) _transferQueue.remove(t);
    }

    final notification = _notificationsBloc.createNotification(SingleTransferAction(
      item: item,
      source: source,
      destination: destination,
    ));
    final transfer = _QueuedTransfer(
      item: item,
      destination: destination,
      notification: notification,
      equip: equip,
      stackSize: stackSize,
    );
    final instanceId = item.item.itemInstanceId;
    if (instanceId != null) {
      instanceIdsToAvoid.add(instanceId);
    }
    _transferQueue.add(transfer);
  }

  Future<void> _startTransferQueue() async {
    final transfersWaiting = _transferQueue.where((t) => !t.started);
    if (transfersWaiting.isEmpty) {
      _isBusy = false;
      instanceIdsToAvoid.clear();
      return;
    }
    _isBusy = true;
    final runningTransfers = _transferQueue.where((t) => t.started);
    if (runningTransfers.length > _maxConcurrentTransfers - 1) return;
    final next = await _findNextTransfer(transfersWaiting, runningTransfers);
    if (next == null) return;
    _transfer(
      next.item,
      next.destination,
      notification: next.notification,
      transfer: next,
      equip: next.equip,
      stackSize: next.stackSize,
    );
    await Future.delayed(const Duration(milliseconds: 100));
    _startTransferQueue();
  }

  Future<_QueuedTransfer?> _findNextTransfer(
      Iterable<_QueuedTransfer> waiting, Iterable<_QueuedTransfer> running) async {
    final next = waiting.firstWhereOrNull((t) => t.item.item.bucketHash != InventoryBucket.lostItems);
    if (next != null) return next;
    final postmasterTransfers = running.where((t) => t.item.item.bucketHash == InventoryBucket.lostItems);
    final busySlots = <_BusySlot>[];
    for (final transfer in postmasterTransfers) {
      final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(transfer.item.item.itemHash);
      final destination = transfer.destination;
      final bucketHash = def?.inventory?.bucketTypeHash;
      if (bucketHash == null) continue;
      busySlots.add(_BusySlot(destination: destination, bucketHash: bucketHash));
    }
    for (final transfer in waiting) {
      final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(transfer.item.item.itemHash);
      final charId = transfer.item.characterId;
      final bucketHash = def?.inventory?.bucketTypeHash;
      if (charId == null) continue;
      if (bucketHash == null) continue;
      if (busySlots.any(
        (b) =>
            b.destination.characterId == charId && //
            b.bucketHash == bucketHash &&
            b.destination.type != TransferDestinationType.profile,
      )) continue;
      return transfer;
    }
    return null;
  }

  Future<void> transferMultiple(List<DestinyItemInfo> items, TransferDestination destination) async {
    for (final item in items) {
      await _addTransferToQueue(item, destination);
    }
    await _startTransferQueue();
  }

  Future<void> _transfer(
    DestinyItemInfo item,
    TransferDestination destination, {
    int stackSize = 1,
    SingleTransferAction? notification,
    _QueuedTransfer? transfer,
    bool equip = false,
  }) async {
    final bool isInstanced = item.item.itemInstanceId != null;
    transfer?.start();
    if (isInstanced) {
      await _transferInstanced(
        item,
        destination,
        notification: notification,
        shouldEquip: equip,
        transfer: transfer,
      );
    } else {
      await _transferUninstanced(
        item,
        destination,
        stackSize: stackSize,
        notification: notification,
        transfer: transfer,
      );
    }
    _transferQueue.remove(transfer);
    _startTransferQueue();
  }

  Future<void> _transferInstanced(
    DestinyItemInfo itemInfo,
    TransferDestination destination, {
    SingleTransferAction? notification,
    _QueuedTransfer? transfer,
    bool shouldEquip = false,
  }) async {
    final itemsToPutBack = <_PutBackTransfer>[];
    final item = itemInfo.item;
    final itemHash = item.itemHash;
    final itemInstanceId = item.itemInstanceId;
    final isOnPostmaster = item.location == ItemLocation.Postmaster || item.bucketHash == InventoryBucket.lostItems;
    if (itemHash == null) throw ("Missing item Hash");
    if (itemInstanceId == null) throw ("Missing item instance ID");
    final sourceCharacterId = itemInfo.characterId;
    final destinationCharacterId = destination.characterId;
    final isOnVault = item.location == ItemLocation.Vault;
    final shouldMoveToVault = sourceCharacterId != destinationCharacterId && !isOnVault;
    final shouldMoveToOtherCharacter = sourceCharacterId != destinationCharacterId && destinationCharacterId != null;
    final isEquipped = itemInfo.instanceInfo?.isEquipped ?? false;
    notification?.createSteps(
      isEquipped: isEquipped,
      isOnPostmaster: isOnPostmaster,
      moveToVault: shouldMoveToVault,
      moveToCharacter: shouldMoveToOtherCharacter,
      equipOnCharacter: shouldEquip,
    );

    if (transfer?.cancelled ?? false) {
      return;
    }

    if (isOnPostmaster) {
      if (sourceCharacterId == null) throw ("Missing item owner when pulling from postmaster");
      for (int tries = 0; true; tries++) {
        try {
          notification?.currentStep = TransferSteps.PullFromPostmaster;
          await _profileBloc.pullFromPostMaster(itemInfo, 1);
          break;
        } on BungieApiException catch (e) {
          if (e.errorCode == PlatformErrorCodes.DestinyNoRoomInDestination && shouldUseAutoTransfer && tries < 3) {
            final item = await _makeRoomOnCharacter(sourceCharacterId, itemHash, originalNotification: notification);
            if (item != null && destination.characterId != sourceCharacterId) {
              final character = _profileBloc.getCharacterById(sourceCharacterId);
              final transferDestination = TransferDestination(
                TransferDestinationType.character,
                character: character,
              );
              itemsToPutBack.add(_PutBackTransfer(item, transferDestination));
            }
            continue;
          }
          notification?.error(_context.getTransferErrorMessage(e));
          return;
        } catch (e) {
          notification?.error(_context.getTransferErrorMessage(null));
          return;
        }
      }
      notifyListeners();
    }

    if (transfer?.cancelled ?? false) {
      return;
    }
    if (isEquipped) {
      try {
        notification?.currentStep = TransferSteps.Unequip;
        final substitute = await _findSubstitute(itemInfo);
        if (substitute == null) throw SubstituteNotFoundException();
        await _profileBloc.equipItem(substitute);
      } on BaseInventoryException catch (e) {
        notification?.error(e.getMessage(_context));
        return;
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }
    }

    if (transfer?.cancelled ?? false) {
      return;
    }
    if (shouldMoveToVault) {
      if (sourceCharacterId == null) throw ("Missing item owner when moving to vault");
      notification?.currentStep = TransferSteps.MoveToVault;
      try {
        await _profileBloc.transferItem(itemInfo, 1, true, sourceCharacterId);
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }
      notifyListeners();
    }
    if (transfer?.cancelled ?? false) {
      return;
    }
    if (shouldMoveToOtherCharacter) {
      if (destinationCharacterId == null) throw ("Missing item owner when moving to character");
      print('moving to character');
      for (int tries = 0; true; tries++) {
        try {
          notification?.currentStep = TransferSteps.MoveToCharacter;
          await _profileBloc.transferItem(itemInfo, 1, false, destinationCharacterId);
          break;
        } on BungieApiException catch (e) {
          if (e.errorCode == PlatformErrorCodes.DestinyNoRoomInDestination && shouldUseAutoTransfer && tries < 3) {
            print("try number $tries to make roon on character");
            await _makeRoomOnCharacter(
              destinationCharacterId,
              itemHash,
              originalNotification: notification,
            );
            continue;
          }
          print("giving up after $tries tries");
          notification?.error(_context.getTransferErrorMessage(e));
          return;
        } catch (e) {
          notification?.error(_context.getTransferErrorMessage(null));
          return;
        }
      }
      notifyListeners();
    }
    if (transfer?.cancelled ?? false) {
      return;
    }
    if (shouldEquip) {
      if (destinationCharacterId == null) throw ("Missing destination character when equipping");
      print('equipping');
      try {
        notification?.currentStep = TransferSteps.EquipOnCharacter;
        await _profileBloc.equipItem(itemInfo);
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }

      notifyListeners();
    }
    notification?.success();
    print('done');
    for (final item in itemsToPutBack) {
      await _addTransferToQueue(item.item, item.destination);
    }
  }

  Future<void> _transferUninstanced(
    DestinyItemInfo itemInfo,
    TransferDestination destination, {
    SingleTransferAction? notification,
    _QueuedTransfer? transfer,
    int stackSize = 1,
  }) async {
    final isOnPostmaster = itemInfo.item.bucketHash == InventoryBucket.lostItems;
    final shouldMoveToVault = destination.type == TransferDestinationType.vault;
    final shouldMoveToCharacter = itemInfo.item.bucketHash == InventoryBucket.general && !shouldMoveToVault;
    final destinationCharacterId = _profileBloc.characters?.firstOrNull?.characterId;

    notification?.createSteps(
      isOnPostmaster: isOnPostmaster,
      moveToVault: shouldMoveToVault,
      moveToCharacter: shouldMoveToCharacter,
    );
    if (transfer?.cancelled ?? false) {
      return;
    }
    if (isOnPostmaster) {
      try {
        print('pulling from postmaster');
        notification?.currentStep = TransferSteps.PullFromPostmaster;
        await _profileBloc.pullFromPostMaster(itemInfo, stackSize);
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }
    }
    if (transfer?.cancelled ?? false) {
      return;
    }
    if (shouldMoveToVault) {
      try {
        print('moving to vault');
        notification?.currentStep = TransferSteps.MoveToVault;
        if (destinationCharacterId == null) throw ("Missing destination character when equipping");
        await _profileBloc.transferItem(itemInfo, stackSize, true, destinationCharacterId);
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }
    }
    if (transfer?.cancelled ?? false) {
      return;
    }
    if (shouldMoveToCharacter) {
      try {
        print('moving to profile');
        notification?.currentStep = TransferSteps.MoveToCharacter;
        if (destinationCharacterId == null) throw ("Missing destination character when equipping");
        await _profileBloc.transferItem(itemInfo, stackSize, false, destinationCharacterId);
      } on BungieApiException catch (e) {
        notification?.error(_context.getTransferErrorMessage(e));
        return;
      } catch (e) {
        notification?.error(_context.getTransferErrorMessage(null));
        return;
      }
    }
    if (transfer?.cancelled ?? false) {
      return;
    }
    notification?.success();
    print('done');
  }

  Future<DestinyItemInfo?> _findSubstitute(DestinyItemInfo itemInfo) async {
    final characterId = itemInfo.characterId;
    if (characterId == null) return null;
    final candidates = _profileBloc.allItems.where((item) =>
        item.item.bucketHash == itemInfo.item.bucketHash && //
        !instanceIdsToAvoid.contains(item.item.itemInstanceId) &&
        item.characterId == characterId &&
        !(item.instanceInfo?.isEquipped ?? false));
    final character = _profileBloc.getCharacter(characterId);
    final itemDef = await manifest.getDefinition<DestinyInventoryItemDefinition>(itemInfo.item.itemHash);
    final itemTierType = itemDef?.inventory?.tierType;

    for (final c in candidates) {
      final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(c.item.itemHash);
      final tierType = def?.inventory?.tierType;
      final classType = def?.classType;
      final acceptableClasses = [character?.classType, DestinyClass.Unknown];
      if (!acceptableClasses.contains(classType)) continue;
      if (tierType != TierType.Exotic || tierType == itemTierType) return c;
    }

    return null;
  }

  Future<DestinyItemInfo?> _makeRoomOnCharacter(
    String characterId,
    int itemHash, {
    List<int>? hashesToAvoid,
    SingleTransferAction? originalNotification,
  }) async {
    final def = await manifest.getDefinition<DestinyInventoryItemDefinition>(itemHash);
    final bucketHash = def?.inventory?.bucketTypeHash;
    if (bucketHash == null) return null;
    final bucketDef = await manifest.getDefinition<DestinyInventoryBucketDefinition>(def?.inventory?.bucketTypeHash);
    final availableSlots = (bucketDef?.itemCount ?? 0) - (bucketDef?.category == BucketCategory.Equippable ? 1 : 0);
    final itemsOnBucket =
        _profileBloc.allItems.where((item) => item.item.bucketHash == bucketHash && item.characterId == characterId);
    if (itemsOnBucket.length < availableSlots) return null;
    final itemToTransfer = itemsOnBucket.lastWhereOrNull((i) {
      final avoidId = instanceIdsToAvoid.contains(i.item.itemInstanceId);
      if (avoidId) return false;
      final avoidHash = hashesToAvoid?.contains(i.item.itemHash) ?? false;
      if (avoidHash) return false;
      return true;
    });
    if (itemToTransfer == null) return null;
    final itemInstanceId = itemToTransfer.item.itemInstanceId;
    if (itemInstanceId != null) {
      instanceIdsToAvoid.add(itemInstanceId);
    }
    final character = _profileBloc.getCharacterById(itemToTransfer.characterId);
    final source = TransferDestination(TransferDestinationType.character, character: character);
    final notification = originalNotification?.createSideEffect(
      item: itemToTransfer,
      source: source,
      destination: TransferDestination.vault(),
    );
    await _transfer(itemToTransfer, TransferDestination.vault(), notification: notification);
    return itemToTransfer;
  }

  Future<void> transferLoadout(LoadoutItemIndex loadout, String? characterId, {int? freeSlots}) async {}

  Future<void> equipLoadout(LoadoutItemIndex loadout, String? characterId, {int? freeSlots}) async {}
}