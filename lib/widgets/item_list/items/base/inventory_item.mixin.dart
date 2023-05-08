// @dart=2.9

import 'package:bungie_api/enums/destiny_item_type.dart';
import 'package:bungie_api/enums/item_state.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:little_light/core/blocs/profile/profile.consumer.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/models/parsed_wishlist.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/services/littlelight/wishlists.consumer.dart';
import 'package:little_light/services/littlelight/wishlists.service.dart';
import 'package:little_light/shared/widgets/wishlists/wishlist_badges.widget.dart';
import 'package:little_light/widgets/common/base/base_destiny_stateless_item.widget.dart';
import 'package:little_light/widgets/common/item_name_bar/item_name_bar.widget.dart';
import 'package:little_light/widgets/common/primary_stat.widget.dart';

mixin InventoryItemMixin implements BaseDestinyStatelessItemWidget, ProfileConsumer {
  WishlistsService get wishlistsService => getInjectedWishlistsService();

  final String uniqueId = "";
  final Widget trailing = null;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        background(context),
        positionedNameBar(context),
        categoryName(context),
        primaryStatWidget(context),
        positionedIcon(context),
        perksWidget(context),
        modsWidget(context),
      ].where((w) => w != null).toList(),
    );
  }

  Widget positionedIcon(BuildContext context) {
    return Positioned(top: padding, left: padding, width: iconSize, height: iconSize, child: itemIconHero(context));
  }

  Widget itemIconHero(BuildContext context) {
    return Hero(
      tag: "item_icon_${tag}_$uniqueId",
      child: itemIcon(context),
    );
  }

  itemIcon(BuildContext context) {
    // return ItemIconWidget(
    //   null,
    //   definition,
    //   instanceInfo,
    //   iconBorderWidth: iconBorderWidth,
    // );
  }

  Widget primaryStatWidget(BuildContext context) {
    if ([DestinyItemType.Engram, DestinyItemType.Subclass].contains(definition.itemType)) {
      return Container();
    }
    if (item?.bucketHash == InventoryBucket.engrams) {
      return Container();
    }
    return Positioned(
        top: titleFontSize + padding * 2 + 4,
        right: 4,
        child: Container(
          child: PrimaryStatWidget(item: item, definition: definition, instanceInfo: instanceInfo),
        ));
  }

  Widget perksWidget(BuildContext context) {
    return Container();
  }

  Widget modsWidget(BuildContext context) {
    return Container();
  }

  Widget categoryName(BuildContext context) {
    return Positioned(
        left: padding * 2 + iconSize,
        top: padding * 2.5 + titleFontSize,
        child: Text(
          definition?.itemTypeDisplayName ?? "",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        ));
  }

  Widget positionedNameBar(BuildContext context) {
    return Positioned(left: 0, right: 0, child: itemHeroNamebar(context));
  }

  Widget buildStatTotal(BuildContext context) {
    var stats = profile.getPrecalculatedStats(item?.itemInstanceId);
    if (stats == null) {
      return Container();
    }
    int total = stats.values.fold(0, (t, s) => t + s.value);
    Color textColor = Colors.grey.shade500;
    if (total >= 60) {
      textColor = Colors.grey.shade300;
    }
    if (total >= 65) {
      textColor = Colors.amber.shade100;
    }
    return Positioned(
        right: iconBorderWidth,
        top: iconBorderWidth,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: padding / 4).copyWith(right: padding / 4),
          decoration: const BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Text(
                "T$total",
                style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w500, color: textColor),
              )
            ],
          ),
        ));
  }

  Widget itemHeroNamebar(BuildContext context) {
    return Hero(tag: "item_namebar_${tag}_$uniqueId", child: nameBar(context));
  }

  Widget nameBar(BuildContext context) {
    return ItemNameBarWidget(item, definition, instanceInfo,
        trailing: namebarTrailingWidget(context),
        padding: EdgeInsets.only(left: iconSize + padding * 2, top: padding, bottom: padding, right: 2));
  }

  background(BuildContext context) {
    return Positioned(
        top: 0,
        left: 0,
        bottom: 0,
        right: 0,
        child: Container(
            color: Theme.of(context).cardTheme.color,
            padding: EdgeInsets.only(top: titleFontSize + padding * 2, left: iconSize),
            child: wishlistBackground(context)));
  }

  Widget wishlistBackground(BuildContext context) {
    final reusable = profile.getItemReusablePlugs(item?.itemInstanceId);
    final tags = wishlistsService.getWishlistBuildTags(itemHash: item?.itemHash, reusablePlugs: reusable);
    if (tags == null) return Container();
    if (tags.contains(WishlistTag.PVE) && tags.contains(WishlistTag.PVP)) {
      return Image.asset(
        "assets/imgs/allaround-bg.png",
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomCenter,
      );
    }
    if (tags.contains(WishlistTag.PVE)) {
      return Image.asset(
        "assets/imgs/pve-bg.png",
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomLeft,
      );
    }
    if (tags.contains(WishlistTag.PVP)) {
      return Image.asset(
        "assets/imgs/pvp-bg.png",
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomRight,
      );
    }

    if (tags.contains(WishlistTag.Bungie)) {
      return Image.asset(
        "assets/imgs/curated-bg.png",
        fit: BoxFit.fitHeight,
        alignment: Alignment.bottomCenter,
      );
    }
    return Container();
  }

  Widget namebarTrailingWidget(BuildContext context) {
    List<Widget> items = [];
    final reusable = profile.getItemReusablePlugs(item?.itemInstanceId);
    final wishlistTags = wishlistsService.getWishlistBuildTags(itemHash: item?.itemHash, reusablePlugs: reusable);

    var locked = item?.state?.contains(ItemState.Locked) ?? false;
    if (locked) {
      items.add(Container(child: Icon(FontAwesomeIcons.lock, size: titleFontSize * .9)));
    }

    if (wishlistTags != null) {
      items.add(WishlistBadgesWidget(wishlistTags, size: tagIconSize));
    }
    if (trailing != null) {
      items.add(trailing);
    }
    if ((items?.length ?? 0) == 0) return Container();
    items = items
        .expand((i) => [
              i,
              Container(
                width: padding / 2,
              )
            ])
        .toList();
    items.removeLast();
    return Row(
      children: items,
    );
  }

  double get iconSize {
    return 80;
  }

  double get iconBorderWidth {
    return 2;
  }

  double get padding {
    return 8;
  }

  LittleLightThemeData getTheme(BuildContext context) {
    return LittleLightTheme.of(context);
  }

  Color defaultTextColor(BuildContext context) {
    return getTheme(context).onSurfaceLayers.layer0;
  }

  double get titleFontSize {
    return 14;
  }

  double get tagIconSize {
    return 22;
  }
}
