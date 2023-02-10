// @dart=2.9

import 'dart:async';
import 'dart:math' as math;

import 'package:bungie_api/enums/destiny_class.dart';
import 'package:bungie_api/enums/tier_type.dart';
import 'package:bungie_api/models/destiny_character_component.dart';
import 'package:bungie_api/models/destiny_inventory_bucket_definition.dart';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/inventory/inventory.bloc.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/core/blocs/profile/profile.consumer.dart';
import 'package:little_light/models/game_data.dart';
import 'package:little_light/models/loadout.dart';
import 'package:little_light/modules/loadouts/blocs/loadout_item_index.dart';
import 'package:little_light/modules/loadouts/blocs/loadouts.bloc.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/inventory/inventory.package.dart';
import 'package:little_light/services/littlelight/littlelight_data.consumer.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/user_settings/user_settings.consumer.dart';
import 'package:little_light/utils/item_sorters/power_level_sorter.dart';
import 'package:little_light/widgets/common/header.wiget.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/option_sheets/free_slots_slider.widget.dart';
import 'package:little_light/widgets/option_sheets/loadout_select_sheet.widget.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

//TODO: deprecate this in favor of new context menu
class CharacterOptionsSheet extends StatefulWidget {
  final DestinyCharacterComponent character;

  const CharacterOptionsSheet({Key key, this.character}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CharacterOptionsSheetState();
  }
}

class CharacterOptionsSheetState extends State<CharacterOptionsSheet>
    with UserSettingsConsumer, LittleLightDataConsumer, ProfileConsumer, InventoryConsumer, ManifestConsumer {
  InventoryBloc inventoryBloc(BuildContext context) => context.read<InventoryBloc>();
  Map<int, DestinyItemComponent> maxLightLoadout;
  Map<int, DestinyItemComponent> underAverageSlots;
  double maxLight;
  bool beyondSoftCap = false;
  bool beyondPowerfulCap = false;
  double currentLight;
  double achievableLight;
  List<DestinyItemComponent> itemsInPostmaster;

  final TextStyle headerStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

  final TextStyle buttonStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 12);

  bool loadoutWeapons = true;
  bool loadoutArmor = true;

  GameData gameData;

  @override
  void initState() {
    super.initState();
    getItemsInPostmaster();
    getMaxLightLoadout();
  }

  void getItemsInPostmaster() {
    var all = profile.getCharacterInventory(widget.character.characterId);
    var inPostmaster = all.where((i) => i.bucketHash == InventoryBucket.lostItems).toList();
    itemsInPostmaster = inPostmaster;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(4).copyWith(top: 0),
                child:
                    Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
                  buildEquipBlock(),
                  buildLoadoutBlock(),
                  buildCreateLoadoutBlock(),
                  Container(
                    height: 8,
                  ),
                  buildPullFromPostmaster(),
                  buildPowerfulInfoBlock(),
                ]))));
  }

  Widget buildPowerfulInfoBlock() {
    if (gameData == null) return Container();
    var current = maxLight?.floor() ?? 0;

    if (current >= gameData.pinnacleCap) return Container();

    var achievable = achievableLight?.floor() ?? 0;
    var goForPinnacle = current >= achievable && beyondSoftCap;

    var title = Text("Go for powerful reward?".translate(context).toUpperCase(), style: headerStyle);
    if (beyondPowerfulCap) {
      title = Text("Go for pinnacle reward?".translate(context).toUpperCase(), style: headerStyle);
    }

    return Column(children: [
      buildBlockHeader(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: title),
        goForPinnacle
            ? TranslatedTextWidget(
                "Yes",
                uppercase: true,
              )
            : TranslatedTextWidget(
                "No",
                uppercase: true,
              )
      ])),
      DefaultTextStyle(
          style: buttonStyle,
          textAlign: TextAlign.center,
          child: Row(
            children: <Widget>[
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Theme.of(context).colorScheme.secondary,
                      child: Column(
                        children: <Widget>[
                          TranslatedTextWidget(
                            "Current average",
                            maxLines: 1,
                            uppercase: true,
                          ),
                          Text(maxLight?.toStringAsFixed(1))
                        ],
                      ))),
              Container(
                width: 4,
              ),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Theme.of(context).colorScheme.secondary,
                      child: Column(
                        children: <Widget>[
                          TranslatedTextWidget(
                            "Achievable average",
                            maxLines: 1,
                            uppercase: true,
                          ),
                          Text(achievableLight?.toStringAsFixed(1))
                        ],
                      )))
            ],
          )),
      (underAverageSlots?.length ?? 0) <= 0
          ? Container()
          : buildBlockHeader(Text("Under average slots".translate(context).toUpperCase(), style: headerStyle)),
      (underAverageSlots?.length ?? 0) <= 0
          ? Container()
          : DefaultTextStyle(
              style: buttonStyle,
              textAlign: TextAlign.center,
              child: Row(
                  children: underAverageSlots
                      .map((k, v) {
                        var instance = profile.getInstanceInfo(v.itemInstanceId);
                        return MapEntry(
                            k,
                            Expanded(
                                child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Theme.of(context).colorScheme.secondary,
                                    child: Column(
                                      children: <Widget>[
                                        ManifestText<DestinyInventoryBucketDefinition>(
                                          k,
                                          uppercase: true,
                                        ),
                                        Text("${instance?.primaryStat?.value}")
                                      ],
                                    ))));
                      })
                      .values
                      .expand((element) => [
                            element,
                            Container(
                              width: 4,
                            )
                          ])
                      .take(underAverageSlots.length * 2 - 1)
                      .toList()),
            )
    ]);
  }

  Widget buildEquipBlock() {
    return Column(children: [
      buildBlockHeader(Text("Equip".translate(context).toUpperCase(), style: headerStyle)),
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            child: buildActionButton(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TranslatedTextWidget(
                "Max Power",
                style: buttonStyle,
                uppercase: true,
                textAlign: TextAlign.center,
              ),
              Container(height: 2),
              maxLight == null
                  ? Shimmer.fromColors(
                      period: const Duration(milliseconds: 600),
                      baseColor: Colors.transparent,
                      highlightColor: Theme.of(context).colorScheme.onSurface,
                      child: Container(width: 50, height: 14, color: Theme.of(context).colorScheme.onSurface))
                  : Text(
                      calculatedMaxLight?.toStringAsFixed(1) ?? "",
                      style: buttonStyle.copyWith(color: Colors.amber.shade300),
                    )
            ],
          ),
          onTap: () async {
            Navigator.of(context).pop();
            LoadoutItemIndex loadout = await LoadoutItemIndex.buildfromLoadout(Loadout());
            var equipment = profile.getCharacterEquipment(widget.character.characterId);
            for (var bucket in maxLightLoadout.keys) {
              var item = maxLightLoadout[bucket];
              var power = profile.getInstanceInfo(item.itemInstanceId)?.primaryStat?.value ?? 0;
              var equipped = equipment.firstWhere((i) => i.bucketHash == bucket, orElse: () => null);
              var equippedPower = profile.getInstanceInfo(equipped?.itemInstanceId)?.primaryStat?.value ?? 0;
              if (power > equippedPower) {
                loadout.addEquippedItem(item);
              }
            }
            inventory.transferLoadout(loadout, widget.character.characterId, true);
          },
        )),
        Container(width: 4),
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "Random Weapons",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            Navigator.pop(context);
            randomizeWeapons();
          },
        )),
        Container(width: 4),
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "Random Armor",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            Navigator.pop(context);
            randomizeArmor();
          },
        )),
      ]))
    ]);
  }

  Widget buildLoadoutBlock() {
    final loadouts = context.watch<LoadoutsBloc>().loadouts;
    if ((loadouts?.length ?? 0) == 0) {
      return Container();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      buildBlockHeader(
        TranslatedTextWidget(
          "Loadouts",
          uppercase: true,
          style: headerStyle,
        ),
      ),
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "Transfer",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            Navigator.of(context).pop();
            int freeSlots = userSettings.defaultFreeSlots;
            showModalBottomSheet(
                context: context,
                builder: (context) => LoadoutSelectSheet(
                    header: FreeSlotsSliderWidget(
                      initialValue: freeSlots,
                      onChanged: (free) {
                        freeSlots = free;
                      },
                    ),
                    character: widget.character,
                    loadouts: loadouts,
                    onSelect: (loadout) =>
                        inventory.transferLoadout(loadout, widget.character.characterId, false, freeSlots)));
          },
        )),
        Container(width: 4),
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "Equip",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            Navigator.of(context).pop();
            int freeSlots = 0;
            showModalBottomSheet(
                context: context,
                builder: (context) => LoadoutSelectSheet(
                    header: FreeSlotsSliderWidget(
                      onChanged: (free) {
                        freeSlots = free;
                      },
                    ),
                    character: widget.character,
                    loadouts: loadouts,
                    onSelect: (loadout) =>
                        inventory.transferLoadout(loadout, widget.character.characterId, true, freeSlots)));
          },
        )),
      ]))
    ]);
  }

  Widget buildCreateLoadoutBlock() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      buildBlockHeader(
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Create Loadout".translate(context).toUpperCase(), style: headerStyle),
          Row(children: [
            Text("Weapons".translate(context).toUpperCase(), style: headerStyle),
            Container(width: 2),
            Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: loadoutWeapons,
                onChanged: (value) {
                  setState(() {
                    loadoutWeapons = value;
                  });
                }),
            Container(width: 6),
            Text("Armor".translate(context).toUpperCase(), style: headerStyle),
            Container(width: 2),
            Switch(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: loadoutArmor,
                onChanged: (value) {
                  setState(() {
                    loadoutArmor = value;
                  });
                }),
          ])
        ]),
      ),
      IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "All",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            // TODO: update to use pageroute
            // var itemIndex = await createLoadout(true);
            // Navigator.of(context).pushReplacement(MaterialPageRoute(
            //     builder: (context) => EditLoadoutPage(
            //           loadout: itemIndex.loadout,
            //           forceCreate: true,
            //         )));
          },
        )),
        Container(width: 4),
        Expanded(
            child: buildActionButton(
          TranslatedTextWidget(
            "Equipped",
            style: buttonStyle,
            uppercase: true,
            textAlign: TextAlign.center,
          ),
          onTap: () async {
            var itemIndex = await createLoadout();
            // TODO: update to use pageroute
            // Navigator.of(context).pushReplacement(MaterialPageRoute(
            //     builder: (context) => EditLoadoutPage(
            //           loadout: itemIndex.loadout,
            //           forceCreate: true,
            //         )));
          },
        )),
      ]))
    ]);
  }

  Widget buildPullFromPostmaster() {
    if ((itemsInPostmaster?.length ?? 0) <= 0) return Container();
    return buildActionButton(
      TranslatedTextWidget(
        "Pull everything from postmaster",
        style: buttonStyle,
        uppercase: true,
        textAlign: TextAlign.center,
      ),
      onTap: () {
        Navigator.of(context).pop();
        // inventoryBloc(context).transferMultiple(
        //   itemsInPostmaster,
        //   widget.character.characterId,
        // );
      },
    );
  }

  Widget buildBlockHeader(Widget content) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: HeaderWidget(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(4),
          child: content,
        ));
  }

  Widget buildActionButton(Widget content, {Function onTap}) {
    return Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
            child: Material(
          color: Theme.of(context).colorScheme.secondary,
        )),
        Container(padding: const EdgeInsets.all(8), child: content),
        Positioned.fill(
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                )))
      ],
    );
  }

  Future<LoadoutItemIndex> createLoadout([includeUnequipped = false]) async {
    var itemIndex = await LoadoutItemIndex.buildfromLoadout(Loadout());
    itemIndex.emblemHash = widget.character.emblemHash;
    // TODO: rework
    // var slots = LoadoutItemIndex.classBucketHashes + LoadoutItemIndex.genericBucketHashes;
    // var equipment = profile.getCharacterEquipment(widget.character.characterId);
    // var equipped = equipment.where((i) => slots.contains(i.bucketHash));
    // for (var item in equipped) {
    //   var def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.itemHash);
    //   if ((def.itemType == DestinyItemType.Weapon || def.itemType == DestinyItemType.Subclass) && loadoutWeapons) {
    //     itemIndex.addEquippedItem(item, def);
    //   }
    //   if (def.itemType == DestinyItemType.Armor && loadoutArmor) {
    //     itemIndex.addEquippedItem(item, def);
    //   }
    // }
    // if (!includeUnequipped) return itemIndex;
    // var inventory = profile.getCharacterInventory(widget.character.characterId);
    // var unequipped = inventory.where((i) => slots.contains(i.bucketHash));
    // for (var item in unequipped) {
    //   var def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.itemHash);
    //   if (def.itemType == DestinyItemType.Weapon && loadoutWeapons) {
    //     itemIndex.addUnequippedItem(item, def);
    //   }
    //   if (def.itemType == DestinyItemType.Armor && loadoutArmor) {
    //     itemIndex.addUnequippedItem(item, def);
    //   }
    // }
    return itemIndex;
  }

  randomizeWeapons() async {
    randomizeLoadout([InventoryBucket.kineticWeapons, InventoryBucket.energyWeapons, InventoryBucket.powerWeapons]);
  }

  randomizeArmor() async {
    randomizeLoadout([
      InventoryBucket.helmet,
      InventoryBucket.gauntlets,
      InventoryBucket.chestArmor,
      InventoryBucket.legArmor,
      InventoryBucket.classArmor,
    ]);
  }

  randomizeLoadout(List<int> requiredSlots) async {
    LoadoutItemIndex randomLoadout = await LoadoutItemIndex.buildfromLoadout(Loadout());
    var allItems = profile.getAllItems().where((i) => i.item.itemInstanceId != null).toList();
    Map<int, String> slots = {};
    int exoticSlot;
    for (int i = 0; i < 1000; i++) {
      var random = math.Random();
      var index = random.nextInt(allItems.length);
      var item = allItems[index];
      var itemDef = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.item.itemHash);
      var itemBucket = itemDef.inventory.bucketTypeHash;
      var tierType = itemDef.inventory.tierType;
      var classType = itemDef.classType;
      if (requiredSlots.contains(itemBucket) &&
          [DestinyClass.Unknown, widget.character.classType].contains(classType)) {
        if (tierType == TierType.Exotic && exoticSlot == null) {
          slots[itemBucket] = item.item.itemInstanceId;
          exoticSlot = itemBucket;
        }
        if (tierType != TierType.Exotic && exoticSlot != itemBucket) {
          slots[itemBucket] = item.item.itemInstanceId;
        }
      }
    }

    for (var j in slots.values) {
      var item = allItems.firstWhere((i) => i.item.itemInstanceId == j);
      var itemDef = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.item.itemHash);
      randomLoadout.addEquippedItem(item.item);
    }

    inventory.transferLoadout(randomLoadout, widget.character.characterId, true);
  }

  getMaxLightLoadout() async {
    gameData = await littleLightData.getGameData();
    var allItems = profile.getAllItems();
    var instancedItems = allItems.where((i) => i.item.itemInstanceId != null).toList();
    var sorter = PowerLevelSorter(-1);
    instancedItems.sort((itemA, itemB) => sorter.sort(itemA, itemB));
    var weaponSlots = [InventoryBucket.kineticWeapons, InventoryBucket.energyWeapons, InventoryBucket.powerWeapons];
    var armorSlots = [
      InventoryBucket.helmet,
      InventoryBucket.gauntlets,
      InventoryBucket.chestArmor,
      InventoryBucket.legArmor,
      InventoryBucket.classArmor
    ];
    var validSlots = weaponSlots + armorSlots;
    var equipment = profile.getCharacterEquipment(widget.character.characterId);
    var availableSlots = equipment.where((i) => validSlots.contains(i.bucketHash)).map((i) => i.bucketHash);
    Map<int, DestinyItemComponent> maxLightLoadout = {};
    Map<int, DestinyItemComponent> maxLightExotics = {};
    for (var item in instancedItems) {
      var def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.item.itemHash);
      if (maxLightLoadout.containsKey(def?.inventory?.bucketTypeHash) ||
          !availableSlots.contains(def?.inventory?.bucketTypeHash) ||
          ![widget.character.classType, DestinyClass.Unknown].contains(def?.classType)) {
        continue;
      }
      if (def?.inventory?.tierType == TierType.Exotic && !maxLightExotics.containsKey(def?.inventory?.bucketTypeHash)) {
        maxLightExotics[def?.inventory?.bucketTypeHash] = item.item;
        continue;
      }

      maxLightLoadout[def?.inventory?.bucketTypeHash] = item.item;

      if (maxLightLoadout.values.length >= availableSlots.length) {
        break;
      }
    }
    Map<int, DestinyItemComponent> weapons = {};
    Map<int, DestinyItemComponent> armor = {};

    for (var s in weaponSlots) {
      if (maxLightLoadout.containsKey(s)) weapons[s] = maxLightLoadout[s];
    }
    for (var s in armorSlots) {
      if (maxLightLoadout.containsKey(s)) armor[s] = maxLightLoadout[s];
    }

    List<Map<int, DestinyItemComponent>> weaponAlternatives = [weapons];
    List<Map<int, DestinyItemComponent>> armorAlternatives = [armor];

    maxLightExotics.forEach((bucket, item) {
      if (weaponSlots.contains(bucket)) {
        var exoticLoadout = Map<int, DestinyItemComponent>.from(weapons);
        exoticLoadout[bucket] = item;
        weaponAlternatives.add(exoticLoadout);
      }
      if (armorSlots.contains(bucket)) {
        var exoticLoadout = Map<int, DestinyItemComponent>.from(armor);
        exoticLoadout[bucket] = item;
        armorAlternatives.add(exoticLoadout);
      }
    });

    weaponAlternatives.sort((a, b) {
      var lightA = _getAvgLight(a.values);
      var lightB = _getAvgLight(b.values);
      return lightB.compareTo(lightA);
    });

    armorAlternatives.sort((a, b) {
      var lightA = _getAvgLight(a.values);
      var lightB = _getAvgLight(b.values);
      return lightB.compareTo(lightA);
    });

    weaponAlternatives.first.forEach((bucket, item) {
      maxLightLoadout[bucket] = item;
    });
    armorAlternatives.first.forEach((bucket, item) {
      maxLightLoadout[bucket] = item;
    });

    maxLight = _getAvgLight(maxLightLoadout.values);
    this.maxLightLoadout = maxLightLoadout;
    var idealLightTotal = 0;
    underAverageSlots = {};
    beyondSoftCap = true;
    beyondPowerfulCap = true;
    for (var item in maxLightLoadout.values) {
      var instanceInfo = profile.getInstanceInfo(item.itemInstanceId);
      var power = instanceInfo?.primaryStat?.value ?? 0;
      var def = await manifest.getDefinition<DestinyInventoryItemDefinition>(item.itemHash);
      if (power < maxLight?.floor()) {
        underAverageSlots[def.inventory.bucketTypeHash] = item;
      }
      if (power < gameData.softCap) {
        beyondSoftCap = false;
      }
      if (power < gameData.powerfulCap) {
        beyondPowerfulCap = false;
      }
      idealLightTotal += math.max(instanceInfo?.primaryStat?.value ?? 0, maxLight?.floor());
    }
    achievableLight = (idealLightTotal / maxLightLoadout.length);
    setState(() {});
  }

  double get calculatedMaxLight {
    if (maxLight == null) return null;
    return maxLight + artifactLevel;
  }

  int get artifactLevel {
    var item = profile
        .getCharacterEquipment(widget.character.characterId)
        .firstWhere((item) => item.bucketHash == InventoryBucket.artifact, orElse: () => null);
    if (item == null) return 0;
    var instanceInfo = profile.getInstanceInfo(item?.itemInstanceId);
    return instanceInfo?.primaryStat?.value ?? 0;
  }

  double _getAvgLight(Iterable<DestinyItemComponent> items) {
    var total =
        items.fold(0, (light, item) => light + profile.getInstanceInfo(item.itemInstanceId)?.primaryStat?.value ?? 0);
    return total / items.length;
  }
}
