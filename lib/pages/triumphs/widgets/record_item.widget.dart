// @dart=2.9

import 'dart:math';

import 'package:bungie_api/enums/destiny_record_state.dart';
import 'package:bungie_api/models/destiny_lore_definition.dart';
import 'package:bungie_api/models/destiny_objective_definition.dart';
import 'package:bungie_api/models/destiny_objective_progress.dart';
import 'package:bungie_api/models/destiny_record_component.dart';
import 'package:bungie_api/models/destiny_record_definition.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:little_light/models/tracked_objective.dart';
import 'package:little_light/pages/triumphs/record_detail.screen.dart';
import 'package:little_light/services/auth/auth.consumer.dart';
import 'package:little_light/services/bungie_api/bungie_api.service.dart';
import 'package:little_light/services/littlelight/objectives.service.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/services/profile/profile.consumer.dart';
import 'package:little_light/widgets/common/queued_network_image.widget.dart';
import 'package:little_light/widgets/common/small_objective.widget.dart';

class RecordItemWidget extends StatefulWidget {
  final int hash;
  RecordItemWidget({Key key, this.hash}) : super(key: key);

  @override
  RecordItemWidgetState createState() {
    return RecordItemWidgetState();
  }
}

const _recordIconSize = 56.0;

class RecordItemWidgetState extends State<RecordItemWidget>
    with AutomaticKeepAliveClientMixin, AuthConsumer, ProfileConsumer, ManifestConsumer {
  DestinyRecordDefinition _definition;
  Map<int, DestinyObjectiveDefinition> objectiveDefinitions;
  DestinyLoreDefinition loreDefinition;
  bool isTracking = false;

  DestinyRecordDefinition get definition {
    return manifest.getDefinitionFromCache<DestinyRecordDefinition>(widget.hash) ?? _definition;
  }

  @override
  void initState() {
    super.initState();
    loadDefinitions();

    updateTrackStatus();
  }

  updateTrackStatus() async {
    var objectives = await ObjectivesService().getTrackedObjectives();
    var tracked = objectives.firstWhere((o) => o.hash == widget.hash && o.type == TrackedObjectiveType.Triumph,
        orElse: () => null);
    isTracking = tracked != null;
    if (!mounted) return;
    setState(() {});
  }

  loadDefinitions() async {
    if (this.definition == null) {
      _definition = await manifest.getDefinition<DestinyRecordDefinition>(widget.hash);
      if (!mounted) return;
      setState(() {});
    }
    if (definition?.objectiveHashes != null) {
      objectiveDefinitions = await manifest.getDefinitions<DestinyObjectiveDefinition>(definition.objectiveHashes);
      if (mounted) setState(() {});
    }

    if (definition?.loreHash != null) {
      loreDefinition = await manifest.getDefinition<DestinyLoreDefinition>(definition.loreHash);
      if (mounted) setState(() {});
    }
  }

  DestinyRecordComponent get record {
    if (definition == null) return null;
    return profile.getRecord(definition.hash, definition.scope);
  }

  DestinyRecordState get recordState {
    return record?.state ?? DestinyRecordState.ObjectiveNotCompleted;
  }

  bool get completed {
    return recordState.contains(DestinyRecordState.RecordRedeemed) ||
        !recordState.contains(DestinyRecordState.ObjectiveNotCompleted) ||
        (record?.intervalObjectives?.every((element) => element.complete) ?? false);
  }

  Color get foregroundColor {
    return completed ? Colors.amber.shade100 : Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if(definition == null) return Container();
    final hasLore = definition?.loreHash != null;
    return LayoutBuilder(
        builder: (context, constraints) => Container(
            decoration: BoxDecoration(
              border: Border.all(color: foregroundColor, width: 1),
            ),
            child: Stack(children: [
              Column(children: [
                Expanded(
                    flex: constraints.hasBoundedHeight ? 1 : 0,
                    child: Container(
                        padding: EdgeInsets.all(8).copyWith(left: _recordIconSize + 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            buildTitle(context),
                            Container(
                              height: 1,
                              color: foregroundColor,
                              margin: EdgeInsets.all(4),
                            ),
                            Expanded(
                              flex: constraints.hasBoundedHeight ? 1 : 0,
                              child: hasLore ? buildLore(context) : buildDescription(context),
                            )
                          ],
                        ))),
                if (!hasLore) buildObjectives(context),
                buildCompletionBars(context)
              ]),
              buildIcon(context),
              Positioned.fill(
                  child: MaterialButton(
                child: Container(),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordDetailScreen(definition),
                    ),
                  );
                },
              ))
            ])));
  }

  Widget buildCompletionBars(BuildContext context) {
    var objectives = definition?.intervalInfo?.intervalObjectives;
    if ((objectives?.length ?? 0) <= 1) {
      return Container();
    }

    List<Widget> bars = objectives?.map((e) => buildCompletionBar(context, objectives.indexOf(e)))?.toList();

    bars = bars.fold<List<Widget>>(
        [],
        (a, e) => a
            .followedBy([
              e,
              Container(
                width: 2,
              )
            ].toList())
            .toList());
    bars.removeLast();

    return Container(
        margin: EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: bars.toList(),
        ));
  }

  Widget buildCompletionBar(BuildContext context, int index) {
    if (record?.intervalObjectives == null) return Container();
    DestinyObjectiveProgress objective = record?.intervalObjectives[index];
    bool complete = record?.intervalObjectives[index]?.complete ?? false;
    int progressStart = index == 0 ? 0 : record?.intervalObjectives?.elementAt(index - 1)?.completionValue ?? 0;
    double progress = (objective.progress - progressStart) / (objective.completionValue - progressStart);
    progress = progress ?? 1;
    Color fillColor = complete ? foregroundColor : Colors.grey.shade400;
    var completionText = "${objective.progress}/${objective.completionValue}";
    if (objective.progress >= objective.completionValue && index < record.intervalObjectives.length - 1) {
      completionText = "${objective.completionValue}";
    }
    if (objective.progress < progressStart) {
      completionText = "${objective.completionValue}";
    }
    return Expanded(
        child: Column(children: [
      Container(
          padding: EdgeInsets.only(bottom: 2),
          alignment: Alignment.centerRight,
          child: Text(completionText, style: TextStyle(fontSize: 12, color: fillColor))),
      Container(
          constraints: BoxConstraints.expand(height: 10),
          alignment: Alignment.centerLeft,
          decoration:
              BoxDecoration(color: Colors.grey.shade300.withOpacity(.3), border: Border.all(color: foregroundColor)),
          child: progress <= 0
              ? Container()
              : FractionallySizedBox(
                  heightFactor: 1,
                  widthFactor: min(progress, 1),
                  child: Container(
                    color: fillColor,
                  )))
    ]));
  }

  Widget buildIcon(BuildContext context) {
    return Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        margin: EdgeInsets.all(8),
        child: definition == null
            ? Container()
            : QueuedNetworkImage(imageUrl: BungieApiService.url(definition?.displayProperties?.icon)));
  }

  buildTitle(BuildContext context) {
    if (definition == null) return Container();
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
          child: Container(
              padding: EdgeInsets.all(4),
              child: Text(
                definition.displayProperties.name,
                softWrap: true,
                style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold),
              ))),
      buildTrackingIcon(context),
      Container(
          padding: EdgeInsets.only(left: 4, right: 4),
          child: Text(
            "${definition?.completionInfo?.scoreValue ?? ""}",
            style: TextStyle(fontWeight: FontWeight.w300, color: foregroundColor, fontSize: 14),
          )),
    ]);
  }

  Widget buildTrackingIcon(BuildContext context) {
    if (!isTracking) return Container();
    return Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(color: Colors.green.shade800, borderRadius: BorderRadius.circular(20)),
        child: Icon(
          FontAwesomeIcons.crosshairs,
          size: 12,
          color: Colors.lightGreenAccent.shade100,
        ));
  }

  buildDescription(BuildContext context) {
    if (definition == null) return Container();
    if ((definition?.displayProperties?.description?.length ?? 0) == 0) return Container();

    return Container(
        padding: EdgeInsets.all(4),
        child: Text(
          definition.displayProperties.description,
          overflow: TextOverflow.fade,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w300, fontSize: 13),
        ));
  }

  buildLore(BuildContext context) {
    if (loreDefinition == null) return Container();
    return Container(
        padding: EdgeInsets.all(4),
        child: Text(
          loreDefinition.displayProperties.description,
          softWrap: true,
          overflow: TextOverflow.fade,
          style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w300, fontSize: 13),
        ));
  }

  DestinyObjectiveProgress getRecordObjective(hash) {
    if (record == null) return null;
    return record.objectives.firstWhere((o) => o.objectiveHash == hash, orElse: () => null);
  }

  Widget buildObjectives(BuildContext context) {
    if ((record.objectives?.length ?? 0) == 0) return Container();
    return Container(
      padding: EdgeInsets.all(4).copyWith(top: 0),
      child: Row(
        children: record.objectives
            .map((objective) =>
                Expanded(child: Container(margin: EdgeInsets.all(2), child: buildObjective(context, objective))))
            .toList(),
      ),
    );
  }

  Widget buildObjective(BuildContext context, DestinyObjectiveProgress objective) {
    if (objectiveDefinitions == null) return Container();
    var definition = objectiveDefinitions[objective.objectiveHash];
    return SmallObjectiveWidget(
      definition: definition,
      objective: objective,
      forceComplete: this.completed,
      placeholder: this.definition.displayProperties.name,
      color: completed ? foregroundColor : null,
      parentCompleted: completed,
    );
  }

  @override
  bool get wantKeepAlive => true;
}