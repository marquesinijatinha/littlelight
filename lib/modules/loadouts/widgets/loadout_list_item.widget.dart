import 'package:bungie_api/enums/destiny_class.dart';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:flutter/material.dart';
import 'package:little_light/modules/loadouts/blocs/loadout_item_index.dart';
import 'package:little_light/services/bungie_api/bungie_api.service.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/profile/profile.consumer.dart';
import 'package:little_light/utils/destiny_data.dart';
import 'package:little_light/widgets/common/definition_provider.widget.dart';
import 'package:little_light/widgets/common/item_icon/item_icon.widget.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/queued_network_image.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/flutter/center_icon_workaround.dart';

enum LoadoutListItemAction { Equip, Edit, Delete }

typedef void OnLoadoutListItemAction(LoadoutListItemAction action);

class LoadoutListItemWidget extends StatelessWidget {
  final LoadoutItemIndex loadout;
  final OnLoadoutListItemAction onAction;
  const LoadoutListItemWidget(this.loadout, {Key? key, required this.onAction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.all(8),
        child: Material(
            elevation: 1,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Column(children: [
              Container(
                height: kToolbarHeight,
                child: buildTitleBar(context),
              ),
              buildLoadoutsContainer(context),
              buildButtonBar(context)
            ])));
  }

  Widget buildLoadoutsContainer(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(4),
        child: Column(
          children: [
            buildGenericItems(context),
            buildClassSpecificItems(context, DestinyClass.Titan),
            buildClassSpecificItems(context, DestinyClass.Hunter),
            buildClassSpecificItems(context, DestinyClass.Warlock),
          ],
        ));
  }

  Widget buildTitleBar(BuildContext context) {
    final emblemHash = loadout.loadout.emblemHash;
    if (emblemHash == null) {
      return buildTitle(context);
    }
    return DefinitionProviderWidget<DestinyInventoryItemDefinition>(
      emblemHash,
      (definition) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
                child: QueuedNetworkImage(
              imageUrl: BungieApiService.url(definition.secondarySpecial),
              fit: BoxFit.cover,
              alignment: Alignment(-1, 0),
            )),
            buildTitle(context)
          ],
        );
      },
      placeholder: buildTitle(context),
      key: Key("emblem_${loadout.loadout.emblemHash}"),
    );
  }

  Widget buildTitle(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(16),
        alignment: Alignment.centerLeft,
        child: Text(
          loadout.loadout.name.toUpperCase(),
          style: TextStyle(color: Colors.grey.shade200, fontWeight: FontWeight.bold),
        ));
  }

  Widget buildButtonBar(BuildContext context) {
    return Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        padding: EdgeInsets.all(4).copyWith(top: 0),
        child: Row(children: [
          Expanded(
              child: Container(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: ElevatedButton(
                style: ButtonStyle(visualDensity: VisualDensity.comfortable),
                child: TranslatedTextWidget("Equip",
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    uppercase: true,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => onAction(LoadoutListItemAction.Equip)
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => EquipLoadoutScreen(loadout: loadout.loadout),
                //   ),
                // );
                ),
          )),
          Expanded(
              child: Container(
                  padding: EdgeInsets.all(2),
                  child: ElevatedButton(
                      style: ButtonStyle(visualDensity: VisualDensity.comfortable),
                      child: TranslatedTextWidget("Edit",
                          uppercase: true,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => onAction(LoadoutListItemAction.Edit)

                      // TODO: update to use pageroute
                      // var loadout = await Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) => EditLoadoutPage(loadout: loadout.loadout),
                      //   ),
                      // );
                      // if (loadout != null) {
                      //   loadout.loadout = loadout;
                      //   await buildItemIndex();
                      //   if (widget.onChange != null) {
                      //     widget.onChange();
                      //   }
                      // }
                      ))),
          Expanded(
              child: Container(
                  padding: EdgeInsets.all(2),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.comfortable, primary: Theme.of(context).errorColor),
                    child: TranslatedTextWidget("Delete",
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        uppercase: true,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => onAction(LoadoutListItemAction.Delete),
                  )))
        ]));
  }

  // Future<void> deletePressed(BuildContext context) async {

  //   final confirm = await Navigator.of(context).push(ConfirmDeleteLoadoutDialogRoute(context, loadout.loadout));
  //   if (confirm ?? false) {
  //     loadoutService.deleteLoadout(loadout.loadout);
  //   }
  //   if (widget.onAction != null) {
  //     widget.onAction();
  //   }
  // }

  Widget buildGenericItems(BuildContext context) {
    final genericHashes = [
      InventoryBucket.kineticWeapons,
      InventoryBucket.energyWeapons,
      InventoryBucket.powerWeapons,
      InventoryBucket.ghost,
      InventoryBucket.vehicle,
      InventoryBucket.ships,
    ];

    final hasItem = genericHashes.any((e) => loadout.slots[e]?.genericEquipped != null);
    if (!hasItem) return Container();

    return Row(
      children: <Widget>[
        buildClassIcon(DestinyClass.Unknown),
      ]
          .followedBy(genericHashes.map((e) => buildItem(loadout.slots[e]?.genericEquipped)))
          .map((e) => Flexible(
                  child: Container(
                padding: EdgeInsets.all(4),
                child: AspectRatio(aspectRatio: 1, child: e),
              )))
          .toList(),
    );
  }

  Widget buildClassSpecificItems(BuildContext context, DestinyClass destinyClass) {
    final genericHashes = [
      InventoryBucket.subclass,
      InventoryBucket.helmet,
      InventoryBucket.gauntlets,
      InventoryBucket.chestArmor,
      InventoryBucket.legArmor,
      InventoryBucket.classArmor,
    ];

    final hasItem = genericHashes.any((e) => loadout.slots[e]?.classSpecificEquipped[destinyClass] != null);
    if (!hasItem) return Container();

    return Row(
      children: <Widget>[
        buildClassIcon(destinyClass),
      ]
          .followedBy(genericHashes.map((e) => buildItem(loadout.slots[e]?.classSpecificEquipped[destinyClass])))
          .map((e) => Flexible(
                  child: Container(
                padding: EdgeInsets.all(4),
                child: AspectRatio(aspectRatio: 1, child: e),
              )))
          .toList(),
    );
  }

  Widget buildClassIcon(DestinyClass destinyClass) => CenterIconWorkaround(destinyClass.icon, size: 16);

  Widget buildItem(DestinyItemComponent? item) {
    if (item == null) {
      return ManifestImageWidget<DestinyInventoryItemDefinition>(1835369552, key: Key("item_icon_empty"));
    }
    final profile = getInjectedProfileService();
    final instance = profile.getInstanceInfo(item.itemInstanceId);
    return DefinitionProviderWidget<DestinyInventoryItemDefinition>(
        item.itemHash!,
        (def) => ItemIconWidget.builder(
            item: item, definition: def, instanceInfo: instance, key: Key("item_icon_${item.itemInstanceId}")));
  }

  List<Widget> buildItemRow(
      BuildContext context, IconData icon, List<int> buckets, Map<int, DestinyItemComponent?> items) {
    List<Widget> itemWidgets = [];
    itemWidgets.add(Icon(icon));
    itemWidgets.addAll(buckets.map((bucketHash) => itemIcon(items[bucketHash])));
    return itemWidgets
        .map((child) => FractionallySizedBox(
              widthFactor: 1 / (buckets.length + 1),
              child: Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  padding: EdgeInsets.all(4),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: child,
                  )),
            ))
        .toList();
  }

  Widget itemIcon(DestinyItemComponent? item) {
    if (item == null) {
      return ManifestImageWidget<DestinyInventoryItemDefinition>(1835369552, key: Key("item_icon_empty"));
    }
    final profile = getInjectedProfileService();
    final instance = profile.getInstanceInfo(item.itemInstanceId);
    return DefinitionProviderWidget<DestinyInventoryItemDefinition>(
        item.itemHash!,
        (def) => ItemIconWidget.builder(
            item: item, definition: def, instanceInfo: instance, key: Key("item_icon_${item.itemInstanceId}")));
  }
}