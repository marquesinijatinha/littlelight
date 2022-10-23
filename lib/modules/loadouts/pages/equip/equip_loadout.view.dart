import 'dart:math';

import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/modules/loadouts/blocs/loadout_item_index.dart';
import 'package:little_light/modules/loadouts/widgets/loadout_destinations.widget.dart';
import 'package:little_light/services/bungie_api/bungie_api.service.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/profile/profile.consumer.dart';
import 'package:little_light/utils/destiny_data.dart';
import 'package:little_light/widgets/common/definition_provider.widget.dart';
import 'package:little_light/widgets/common/header.wiget.dart';
import 'package:little_light/widgets/common/item_icon/item_icon.widget.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/queued_network_image.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/flutter/center_icon_workaround.dart';

class EquipLoadoutView extends StatelessWidget {
  // Color get emblemColor {
  //   if (emblemDefinition == null) return Theme.of(context).colorScheme.background;
  //   Color color = Color.fromRGBO(emblemDefinition.backgroundColor.red, emblemDefinition.backgroundColor.green,
  //       emblemDefinition.backgroundColor.blue, 1.0);
  //   return Color.lerp(color, Theme.of(context).colorScheme.background, .5);
  // }

  @override
  Widget build(BuildContext context) {
    final screenPadding = MediaQuery.of(context).padding;
    return Scaffold(
        // backgroundColor: emblemColor,
        // appBar: AppBar(title: Text(widget.loadout.name), flexibleSpace: buildAppBarBackground(context)),
        // bottomNavigationBar: LoadoutDestinationsWidget(widget.loadout),
        body: Container(
            alignment: Alignment.center,
            child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                child: ListView(
                    padding: EdgeInsets.all(8)
                        .copyWith(top: 0, left: max(screenPadding.left, 8), right: max(screenPadding.right, 8)),
                    children: <Widget>[
                      HeaderWidget(child: TranslatedTextWidget("Items to Equip", uppercase: true)),
                      Container(padding: EdgeInsets.all(8), child: buildEquippedItems(context)),
                      // (_loadout?.unequippedItemCount ?? 0) == 0
                      //     ? Container()
                      //     : HeaderWidget(
                      //         child: TranslatedTextWidget("Items to Transfer", uppercase: true),
                      //       ),
                      // (_loadout?.unequippedItemCount ?? 0) == 0
                      //     ? Container()
                      //     : Container(padding: EdgeInsets.all(8), child: buildUnequippedItems(context)),
                    ]))));
  }

  buildAppBarBackground(BuildContext context) {
    // if (widget.loadout.emblemHash == null) {
    //   return Container();
    // }
    // return DefinitionProviderWidget<DestinyInventoryItemDefinition>(
    //     widget.loadout.emblemHash,
    //     (def) => Container(
    //         constraints: BoxConstraints.expand(),
    //         child: QueuedNetworkImage(
    //             imageUrl: BungieApiService.url(def.secondarySpecial),
    //             fit: BoxFit.cover,
    //             alignment: Alignment(-.8, 0))));
    return Container();
  }

  Widget buildEquippedItems(BuildContext context) {
    // if (_loadout == null)
    //   return Container(
    //     child: AspectRatio(
    //       aspectRatio: 1,
    //     ),
    //   );
    List<Widget> icons = [];
    icons.add(CenterIconWorkaround(DestinyClass.Unknown.icon));
    for (final hash in LoadoutItemIndex.genericBucketHashes) {}

    // icons.addAll(
    //     buildItemRow(context, DestinyClass.Unknown.icon, LoadoutItemIndex.genericBucketHashes, _itemIndex.generic));

    // DestinyClass.values.forEach((classType) {
    //   Map<int, DestinyItemComponent> items =
    //       _itemIndex.classSpecific.map((bucketHash, items) => MapEntry(bucketHash, items[classType]));
    //   if (items.values.any((i) => i != null)) {
    //     icons.addAll(
    //         buildItemRow(context, DestinyData.getClassIcon(classType), LoadoutItemIndex.classBucketHashes, items));
    //   }
    // });

    return Wrap(
      children: icons,
    );
  }

  Widget buildUnequippedItems(BuildContext context) {
    return Container();
    // TODO: rework
    // if (_itemIndex == null)
    //   return Container(
    //     child: AspectRatio(
    //       aspectRatio: 1,
    //     ),
    //   );
    // if (_itemIndex.unequipped == null) return Container();
    // List<DestinyItemComponent> items = [];
    // List<int> bucketHashes = LoadoutItemIndex.genericBucketHashes + LoadoutItemIndex.classBucketHashes;
    // bucketHashes.forEach((bucketHash) {
    //   if (_itemIndex.unequipped[bucketHash] != null) {
    //     items += _itemIndex.unequipped[bucketHash];
    //   }
    // });
    // return Wrap(
    //   children: items
    //       .map((item) => FractionallySizedBox(
    //           widthFactor: 1 / 7,
    //           child: Container(padding: EdgeInsets.all(4), child: AspectRatio(aspectRatio: 1, child: itemIcon(item)))))
    //       .toList(),
    // );
  }

  List<Widget> buildItemRow(
      BuildContext context, IconData icon, List<int> buckets, Map<int, DestinyItemComponent> items) {
    List<Widget> itemWidgets = [];
    itemWidgets.add(CenterIconWorkaround(icon));
    // itemWidgets.addAll(buckets.map((bucketHash) => itemIcon(items[bucketHash])));
    return itemWidgets
        .map((child) => FractionallySizedBox(
              widthFactor: 1 / (buckets.length + 1),
              child: Container(
                  padding: EdgeInsets.all(4),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: child,
                  )),
            ))
        .toList();
  }

  Widget itemIcon(DestinyItemComponent item) {
    if (item == null) {
      return ManifestImageWidget<DestinyInventoryItemDefinition>(1835369552, key: Key("item_icon_empty"));
    }
    return Container();
    // var instance = profile.getInstanceInfo(item?.itemInstanceId);
    // return DefinitionProviderWidget<DestinyInventoryItemDefinition>(
    //     item.itemHash,
    //     (def) => ItemIconWidget.builder(
    //         item: item, definition: def, instanceInfo: instance, key: Key("item_icon_${item.itemInstanceId}")));
  }
}