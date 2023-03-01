// @dart=2.9

import 'package:bungie_api/enums/damage_type.dart';
import 'package:bungie_api/enums/destiny_item_type.dart';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:bungie_api/models/destiny_item_component.dart';
import 'package:bungie_api/models/destiny_item_instance_component.dart';
import 'package:bungie_api/models/destiny_power_cap_definition.dart';
import 'package:bungie_api/models/destiny_stat_definition.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/utils/destiny_data.dart';
import 'package:little_light/widgets/common/definition_provider.widget.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';

class PrimaryStatWidget extends StatelessWidget {
  final double fontSize;
  final double padding;
  final bool suppressLabel;
  final bool suppressDamageTypeIcon;
  final bool suppressAmmoTypeIcon;
  final bool suppressClassTypeIcon;
  final bool suppressPowerCap;
  final bool inlinePowerCap;

  final DestinyItemInstanceComponent instanceInfo;
  final DestinyItemComponent item;
  final DestinyInventoryItemDefinition definition;

  const PrimaryStatWidget(
      {Key key,
      this.item,
      this.definition,
      this.instanceInfo,
      this.suppressLabel = false,
      this.suppressDamageTypeIcon = false,
      this.suppressAmmoTypeIcon = false,
      this.suppressClassTypeIcon = false,
      this.suppressPowerCap = false,
      this.inlinePowerCap = false,
      this.fontSize = 22,
      this.padding = 8,
      String characterId})
      : super(key: key);

  int get statValue {
    return instanceInfo?.primaryStat?.value;
  }

  DamageType get damageType {
    var value = instanceInfo?.damageType;
    if (value != null) {
      return value;
    }
    return definition?.defaultDamageType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: mainLineWidgets(context)));
  }

  List<Widget> mainLineWidgets(BuildContext context) {
    List<Widget> widgets = [];
    if (definition?.itemType == DestinyItemType.Weapon &&
        !suppressAmmoTypeIcon) {
      widgets.add(ammoTypeIcon(context));
    }
    if (definition?.itemType == DestinyItemType.Weapon &&
        !suppressDamageTypeIcon) {
      widgets.add(damageTypeIcon(context));
    }
    if (definition?.itemType == DestinyItemType.Armor &&
        !suppressClassTypeIcon) {
      widgets.add(classTypeIcon(context));
    }
    widgets.add(
        valueAndCapField(context, damageType?.getColorLayer(context)?.layer2));
    if (inlinePowerCap) {
      widgets.add(inlinePowerCapField(context));
    }

    return widgets;
  }

  Widget inlinePowerCapField(BuildContext context) {
    var versionNumber =
        item?.versionNumber ?? definition?.quality?.currentVersion;
    if (versionNumber == null ||
        definition?.quality?.versions == null ||
        suppressPowerCap) {
      return Container();
    }
    var version = definition.quality.versions[versionNumber];
    return DefinitionProviderWidget<DestinyPowerCapDefinition>(
      version.powerCapHash,
      (def) {
        if (def.powerCap > 9000) return Container();
        return Container(
            height: fontSize * .8,
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 2),
            child: powerCapField(context, def.powerCap));
      },
    );
  }

  Widget powerCapField(BuildContext context, int value) {
    return Text("$value",
        style: TextStyle(
            fontSize: fontSize * .65,
            height: .9,
            color: LittleLightTheme.of(context).achievementLayers));
  }

  Widget valueAndCapField(BuildContext context, Color color) {
    if (statValue == null) return Container();

    if (definition?.quality?.currentVersion == null ||
        definition?.quality?.versions == null ||
        suppressPowerCap ||
        inlinePowerCap) {
      return valueField(context, color, fontSize);
    }
    var version =
        definition.quality.versions[definition.quality.currentVersion];
    return DefinitionProviderWidget<DestinyPowerCapDefinition>(
        version.powerCapHash, (def) {
      if (def.powerCap > 9000) {
        return valueField(context, color, fontSize);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          valueField(context, color, fontSize * .9),
          powerCapField(context, def.powerCap)
        ],
      );
    });
  }

  Widget valueField(BuildContext context, Color color, double fontSize) {
    if (statValue == null) return Container();
    return Text(
      "$statValue",
      style: TextStyle(
          color: color, fontWeight: FontWeight.w700, fontSize: fontSize),
    );
  }

  Widget primaryStatNameField(BuildContext context, Color color) {
    return ManifestText<DestinyStatDefinition>(
        instanceInfo.primaryStat.statHash,
        uppercase: true,
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w300,
            fontSize: fontSize * .7));
  }

  Widget classTypeIcon(BuildContext context) {
    return Row(children: [
      Icon(
        definition.classType.icon,
        color: damageType?.getColorLayer(context)?.layer2,
        size: fontSize,
      ),
      ammoTypeDivider(context)
    ]);
  }

  Widget damageTypeIcon(BuildContext context) {
    return Icon(
      DestinyData.getDamageTypeIcon(damageType),
      color: damageType?.getColorLayer(context)?.layer2,
      size: fontSize,
    );
  }

  Widget ammoTypeIcon(BuildContext context) {
    return Row(children: [
      SizedBox(
          width: fontSize * 1.5,
          child: Icon(
            DestinyData.getAmmoTypeIcon(definition.equippingBlock.ammoType),
            color: DestinyData.getAmmoTypeColor(
                definition.equippingBlock.ammoType),
            size: fontSize,
          )),
      ammoTypeDivider(context),
    ]);
  }

  Widget ammoTypeDivider(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(left: padding / 2, right: padding / 4),
        color: Theme.of(context).colorScheme.onSurface,
        width: 1,
        height: fontSize);
  }
}
