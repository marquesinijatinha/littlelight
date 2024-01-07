import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/profile/destiny_character_info.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/modules/loadouts/pages/home/destiny_loadouts.bloc.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/shared/utils/extensions/character_data.dart';
import 'package:little_light/shared/widgets/character/character_icon.widget.dart';
import 'package:little_light/shared/widgets/inventory_item/inventory_item_icon.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';
import 'package:little_light/widgets/common/queued_network_image.widget.dart';

class DestinyLoadoutListItemWidget extends StatelessWidget {
  final DestinyLoadoutInfo loadout;
  final DestinyCharacterInfo character;
  const DestinyLoadoutListItemWidget(
    this.loadout, {
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final colorDef = context.definition<DestinyLoadoutColorDefinition>(loadout.loadout.colorHash);
    return Container(
      child: Stack(children: [
        Positioned.fill(child: QueuedNetworkImage.fromBungie(colorDef?.colorImagePath, fit: BoxFit.cover)),
        Container(
          padding: EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildLoadoutTitle(context),
              buildItems(context),
            ],
          ),
        ),
      ]),
    );
  }

  Widget buildHeader(BuildContext context) {
    return IntrinsicHeight(
        child: Row(
      children: [
        buildLoadoutIcon(context),
        Container(
          width: 4,
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildLoadoutTitle(context),
              buildItems(context),
            ],
          ),
        )
      ],
    ));
  }

  Widget buildLoadoutIcon(BuildContext context) {
    final iconDef = context.definition<DestinyLoadoutIconDefinition>(loadout.loadout.iconHash);
    final colorDef = context.definition<DestinyLoadoutColorDefinition>(loadout.loadout.colorHash);
    return Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(width: 2, color: context.theme.onSurfaceLayers.layer1)),
        child: Stack(children: [
          Positioned.fill(child: QueuedNetworkImage.fromBungie(colorDef?.colorImagePath)),
          QueuedNetworkImage.fromBungie(iconDef?.iconImagePath)
        ]));
  }

  Widget buildLoadoutTitle(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: [
            context.theme.surfaceLayers.layer0.withOpacity(.7),
            context.theme.surfaceLayers.layer0.withOpacity(0)
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ManifestText<DestinyLoadoutNameDefinition>(
        loadout.loadout.nameHash,
        textExtractor: (def) => def.name?.toUpperCase(),
        style: context.textTheme.itemNameHighDensity,
      ),
    );
  }

  Widget buildCharacterIcon(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      child: CharacterIconWidget(
        character,
        hideClassIcon: true,
        borderWidth: 1,
      ),
    );
  }

  Widget buildCharacterInfo(BuildContext context) {
    final classDef = context.definition<DestinyClassDefinition>(character.character.classHash);
    final raceDef = context.definition<DestinyRaceDefinition>(character.character.raceHash);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: [
            context.theme.surfaceLayers.layer0.withOpacity(.7),
            context.theme.surfaceLayers.layer0.withOpacity(0)
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            character.getGenderedClassName(classDef),
            style: context.textTheme.itemNameMediumDensity,
          ),
          Text(
            character.getGenderedRaceName(raceDef),
            style: context.textTheme.itemNameMediumDensity,
          ),
        ],
      ),
    );
  }

  Widget buildItems(BuildContext context) {
    final items = loadout.items;
    if (items.isEmpty) return Container();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: buildLoadoutIcon(context)),
            Expanded(child: buildItem(context, InventoryBucket.subclass)),
            Expanded(child: buildItem(context, InventoryBucket.kineticWeapons)),
            Expanded(child: buildItem(context, InventoryBucket.energyWeapons)),
            Expanded(child: buildItem(context, InventoryBucket.powerWeapons)),
          ],
        ),
        Row(
          children: [
            Expanded(child: buildItem(context, InventoryBucket.helmet)),
            Expanded(child: buildItem(context, InventoryBucket.gauntlets)),
            Expanded(child: buildItem(context, InventoryBucket.chestArmor)),
            Expanded(child: buildItem(context, InventoryBucket.legArmor)),
            Expanded(child: buildItem(context, InventoryBucket.classArmor)),
          ],
        )
      ],
    );
  }

  Widget buildItem(BuildContext context, int bucketHash) {
    final item = loadout.items[bucketHash];
    if (item == null) return Container();
    return Container(padding: EdgeInsets.all(4), child: InventoryItemIcon(item));
  }
}
