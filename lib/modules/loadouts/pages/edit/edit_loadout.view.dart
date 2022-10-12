import 'dart:math';

import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/modules/loadouts/pages/edit/edit_loadout.bloc.dart';
import 'package:little_light/modules/loadouts/pages/select_background/select_loadout_background.page_route.dart';
import 'package:little_light/modules/loadouts/widgets/loadout_slot.widget.dart';
import 'package:little_light/services/bungie_api/bungie_api.service.dart';
import 'package:little_light/services/littlelight/loadouts.consumer.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/utils/color_utils.dart';
import 'package:little_light/widgets/common/loading_anim.widget.dart';
import 'package:little_light/widgets/common/queued_network_image.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:little_light/widgets/multisection_scrollview/multisection_scrollview.dart';
import 'package:little_light/widgets/multisection_scrollview/sliver_section.dart';
import 'package:provider/provider.dart';

class EditLoadoutView extends StatefulWidget {
  final bool forceCreate;
  EditLoadoutView({Key? key, this.forceCreate = false}) : super(key: key);

  @override
  EditLoadoutViewState createState() => EditLoadoutViewState();
}

class EditLoadoutViewState extends State<EditLoadoutView> with LoadoutsConsumer, ManifestConsumer {
  TextEditingController _nameFieldController = TextEditingController();
  EditLoadoutBloc get _provider => context.read<EditLoadoutBloc>();
  EditLoadoutBloc get _state => context.watch<EditLoadoutBloc>();

  @override
  initState() {
    super.initState();
    _nameFieldController.text = _provider.loadoutName;
    _nameFieldController.addListener(() {
      _provider.loadoutName = _nameFieldController.text;
    });
  }

  @override
  dispose() {
    super.dispose();
    _nameFieldController.dispose();
  }

  Color get backgroundColor {
    final emblemDefinition = _provider.emblemDefinition;
    final bgColor = emblemDefinition?.backgroundColor;
    final background = Theme.of(context).colorScheme.background;
    if (bgColor == null) return background;
    return Color.lerp(bgColor.toMaterialColor(), background, .5) ?? background;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: buildBody(context),
      bottomNavigationBar: buildFooter(context),
    );
  }

  AppBar buildAppBar(BuildContext context) => AppBar(
        title: _state.creating ? TranslatedTextWidget("Create Loadout") : TranslatedTextWidget("Edit Loadout"),
        flexibleSpace: buildAppBarBackground(context),
      );

  Widget buildAppBarBackground(BuildContext context) {
    final emblemDefinition = _state.emblemDefinition;
    if (emblemDefinition == null) return Container();
    if (emblemDefinition.secondarySpecial?.isEmpty ?? true) return Container();
    return Container(
        constraints: BoxConstraints.expand(),
        child: QueuedNetworkImage(
            imageUrl: BungieApiService.url(emblemDefinition.secondarySpecial),
            fit: BoxFit.cover,
            alignment: Alignment(-.8, 0)));
  }

  Widget buildBody(BuildContext context) {
    final screenPadding = MediaQuery.of(context).padding;
    return MultiSectionScrollView(
      [
        SliverSection(
          itemCount: 1,
          itemBuilder: (context, _) => buildNameTextField(context),
        ),
        SliverSection(
          itemCount: 1,
          itemBuilder: (context, _) => buildSelectBackgroundButton(context),
        ),
        if (!_state.loaded) SliverSection(itemBuilder: (c, _) => LoadingAnimWidget()),
        if (_state.loaded)
          SliverSection(
            itemBuilder: (context, index) => buildSlot(context, index),
            itemCount: _state.bucketHashes.length,
          )
      ],
      padding: EdgeInsets.all(8).copyWith(top: 0, left: max(screenPadding.left, 8), right: max(screenPadding.right, 8)),
    );
  }

  Widget buildNameTextField(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        child: TextField(
          autocorrect: false,
          controller: _nameFieldController,
          decoration: InputDecoration(labelText: context.translate("Loadout Name")),
        ));
  }

  Widget buildSelectBackgroundButton(BuildContext context) {
    return Container(
        padding: EdgeInsets.all(8),
        child: ElevatedButton(
          child: TranslatedTextWidget("Select Loadout Background"),
          onPressed: () async {
            _provider.emblemHash = await Navigator.of(context).push<int?>(SelectLoadoutBackgroundPageRoute());
          },
        ));
  }

  Widget buildSlot(BuildContext context, int index) {
    final hash = _state.bucketHashes[index];
    final definition = _state.getBucketDefinition(hash);
    final slot = _state.getLoadoutIndexSlot(hash);
    if (definition == null || slot == null) {
      return Container();
    }

    return LoadoutSlotWidget(
      bucketDefinition: definition,
      key: Key("loadout_slot_$hash"),
      slot: slot,
      onAdd: (classType, equipped) {
        _provider.selectItemToAdd(classType, hash, equipped);
      },
      onOptions: (item, equipped) {
        _provider.openItemOptions(item, equipped);
      },
    );
  }

  Widget buildFooter(BuildContext context) {
    double paddingBottom = MediaQuery.of(context).padding.bottom;
    if (!_state.changed) return Container(height: paddingBottom);
    return Material(
        elevation: 1,
        color: Theme.of(context).appBarTheme.backgroundColor,
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: buildAppBarBackground(context)),
            Container(
              constraints: BoxConstraints(minWidth: double.infinity),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4).copyWith(bottom: 4 + paddingBottom),
              child: ElevatedButton(
                  child: TranslatedTextWidget("Save Loadout"),
                  onPressed: () {
                    _provider.save();
                    Navigator.of(context).pop();
                  }),
            )
          ],
        ));
  }
}