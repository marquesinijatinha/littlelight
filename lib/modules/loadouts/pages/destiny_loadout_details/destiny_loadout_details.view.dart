import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/models/destiny_loadout.dart';
import 'package:little_light/modules/loadouts/pages/destiny_loadout_details/destiny_loadout_details.bloc.dart';
import 'package:little_light/modules/loadouts/widgets/destiny_loadout_item.widget.dart';
import 'package:little_light/modules/loadouts/widgets/loadouts_character_header.dart';
import 'package:little_light/services/bungie_api/enums/inventory_bucket_hash.enum.dart';
import 'package:little_light/shared/utils/helpers/media_query_helper.dart';
import 'package:little_light/shared/widgets/scrollable_grid_view/paginated_plug_grid_view.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/manifest_text.widget.dart';

const _notFoundIconHash = 29505215;

class DestinyLoadoutDetailsView extends StatelessWidget {
  final DestinyLoadoutDetailsBloc bloc;
  final DestinyLoadoutDetailsBloc state;
  const DestinyLoadoutDetailsView({
    super.key,
    required this.bloc,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final viewPadding = context.mediaQuery.viewPadding;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: context.theme.surfaceLayers.layer1,
            padding: EdgeInsets.only(top: viewPadding.top + kToolbarHeight),
            child: Column(children: [
              Expanded(
                  child: SingleChildScrollView(
                child: buildBody(context),
              )),
              buildFooter(context)
            ]),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: buildAppBar(context),
          ),
        ],
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    final viewPadding = context.mediaQuery.viewPadding;
    final barBackgroundHeight = viewPadding.top + kToolbarHeight;
    return Container(
        height: barBackgroundHeight,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              height: barBackgroundHeight,
              child: Container(
                height: barBackgroundHeight,
                child: ManifestImageWidget<DestinyLoadoutColorDefinition>(
                  state.selectedColorHash,
                  urlExtractor: (def) => def.colorImagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
                top: viewPadding.top,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: kToolbarHeight,
                      height: kToolbarHeight,
                      alignment: Alignment.center,
                      child: BackButton(),
                    ),
                    Container(
                      height: kToolbarHeight,
                      alignment: Alignment.center,
                      child: ManifestText<DestinyLoadoutNameDefinition>(
                        state.selectedNameHash,
                        textExtractor: (def) => def.name?.toUpperCase(),
                        style: context.textTheme.itemNameHighDensity.copyWith(fontSize: 16),
                      ),
                    ),
                    Expanded(child: Container()),
                    Container(
                      width: kToolbarHeight,
                      height: kToolbarHeight,
                      child: ManifestImageWidget<DestinyLoadoutIconDefinition>(
                        state.selectedIconHash,
                        urlExtractor: (def) => def.iconImagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                    Container(
                      width: 16,
                    ),
                  ],
                )),
          ],
        ));
  }

  Widget buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildCharacter(context),
        buildManageColor(context),
        buildManageIcon(context),
        buildManageName(context),
        buildItems(context),
      ],
    );
  }

  Widget buildCharacter(BuildContext context) {
    final character = state.character;
    if (character == null) return Container();
    return Container(
      padding: EdgeInsets.all(4),
      height: 72,
      child: LoadoutCharacterHeaderWidget(character),
    );
  }

  Widget buildManageColor(BuildContext context) {
    final colorHashes = state.availableColorHashes;
    if (colorHashes == null) return Container();
    final selected = state.selectedColorHash;
    final selectedIndex = selected != null ? colorHashes.indexOf(selected) : 0;
    return Container(
        padding: EdgeInsets.all(4),
        child: PaginatedScrollableGridView.withExpectedItemSize(
          colorHashes,
          itemBuilder: (hash) => buildSelectableButton(
            context,
            selected: hash == selected,
            onTap: () => bloc.selectedColorHash = hash,
            child: ManifestImageWidget<DestinyLoadoutColorDefinition>(
              hash,
              urlExtractor: (def) => def.colorImagePath,
            ),
          ),
          gridSpacing: 4,
          maxRows: 1,
          expectedCrossAxisSize: 48,
          initialFocus: selectedIndex,
        ));
  }

  Widget buildManageIcon(BuildContext context) {
    final iconHashes = state.availableIconHashes;
    if (iconHashes == null) return Container();
    final selected = state.selectedIconHash;
    final selectedIndex = selected != null ? iconHashes.indexOf(selected) : 0;
    return Container(
        padding: EdgeInsets.all(4),
        child: PaginatedScrollableGridView.withExpectedItemSize(
          iconHashes,
          itemBuilder: (hash) => buildSelectableButton(
            context,
            selected: hash == selected,
            onTap: () => bloc.selectedIconHash = hash,
            child: ManifestImageWidget<DestinyLoadoutIconDefinition>(
              hash,
              urlExtractor: (def) => def.iconImagePath,
            ),
          ),
          gridSpacing: 4,
          maxRows: 1,
          expectedCrossAxisSize: 48,
          initialFocus: selectedIndex,
        ));
  }

  Widget buildManageName(BuildContext context) {
    final nameHashes = state.availableNameHashes;
    if (nameHashes == null) return Container();
    final selected = state.selectedNameHash;
    final selectedIndex = selected != null ? nameHashes.indexOf(selected) : 0;
    return Container(
        padding: EdgeInsets.all(4),
        child: PaginatedScrollableGridView.withExpectedItemSize(
          nameHashes,
          itemBuilder: (hash) => buildSelectableTextButton(
            context,
            selected: hash == selected,
            onTap: () => bloc.selectedNameHash = hash,
            child: Container(
              padding: EdgeInsets.all(4),
              child: ManifestText<DestinyLoadoutNameDefinition>(
                hash,
                textExtractor: (def) => def.name,
                style: context.textTheme.itemNameHighDensity,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          gridSpacing: 4,
          maxRows: 3,
          expectedCrossAxisSize: 120,
          itemMainAxisExtent: 32,
          initialFocus: selectedIndex,
        ));
  }

  Widget buildSelectableButton(
    BuildContext context, {
    required Widget child,
    bool selected = false,
    VoidCallback? onTap,
  }) =>
      Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 1.5,
                color: selected ? context.theme.onSurfaceLayers : context.theme.onSurfaceLayers.layer3,
              ),
            ),
            child: child,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap),
          ),
        ],
      );

  Widget buildSelectableTextButton(
    BuildContext context, {
    required Widget child,
    bool selected = false,
    VoidCallback? onTap,
  }) =>
      Stack(
        fit: StackFit.expand,
        children: [
          Container(
            margin: EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.theme.primaryLayers : context.theme.surfaceLayers.layer3,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                width: 2,
                color: selected ? context.theme.onSurfaceLayers : Colors.transparent,
              ),
            ),
            child: child,
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(onTap: onTap),
          ),
        ],
      );

  Widget buildItems(BuildContext context) {
    final items = state.loadout?.items;
    if (items == null || items.isEmpty) return Container();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildLoadoutItem(context, items[InventoryBucket.subclass]),
        buildLoadoutItem(context, items[InventoryBucket.kineticWeapons]),
        buildLoadoutItem(context, items[InventoryBucket.energyWeapons]),
        buildLoadoutItem(context, items[InventoryBucket.powerWeapons]),
        buildLoadoutItem(context, items[InventoryBucket.helmet]),
        buildLoadoutItem(context, items[InventoryBucket.gauntlets]),
        buildLoadoutItem(context, items[InventoryBucket.chestArmor]),
        buildLoadoutItem(context, items[InventoryBucket.legArmor]),
        buildLoadoutItem(context, items[InventoryBucket.classArmor]),
      ],
    );
  }

  Widget buildLoadoutItem(BuildContext context, DestinyLoadoutItemInfo? item) {
    if (item == null) return buildItemNotFound(context);
    return DestinyLoadoutItemWidget(item);
  }

  Widget buildItemNotFound(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: context.theme.onSurfaceLayers.layer3, width: 2)),
              child: ManifestImageWidget<DestinyInventoryItemDefinition>(
                _notFoundIconHash,
                color: context.theme.errorLayers.layer3,
              ),
            ),
            Container(
              width: 16,
            ),
            Text("Item not found".translate(context)),
          ],
        ));
  }

  Widget buildFooter(BuildContext context) {
    final viewPadding = context.mediaQuery.viewPadding;
    return Stack(
      children: [
        Positioned.fill(
            child: ManifestImageWidget<DestinyLoadoutColorDefinition>(
          state.selectedColorHash,
          urlExtractor: (def) => def.colorImagePath,
          fit: BoxFit.cover,
        )),
        Container(
          padding: EdgeInsets.all(8) + EdgeInsets.only(bottom: viewPadding.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ElevatedButton(
              onPressed: () => bloc.importToLittleLight(),
              child: Text(
                "Import to Little Light".translate(context),
              ),
            ),
            ElevatedButton(
              onPressed: () => bloc.equipLoadout(),
              child: Text(
                "Equip Loadout".translate(context),
              ),
            ),
            ElevatedButton(
              onPressed: () => bloc.deleteLoadout(),
              style: ElevatedButton.styleFrom(backgroundColor: context.theme.errorLayers),
              child: Text(
                "Delete".translate(context),
              ),
            )
          ]),
        ),
      ],
    );
  }
}
