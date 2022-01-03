import 'dart:async';
import 'package:bungie_api/models/destiny_inventory_item_definition.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/services/notification/notification.service.dart';
import 'package:little_light/services/profile/profile.consumer.dart';
import 'package:little_light/utils/shimmer_helper.dart';
import 'package:little_light/widgets/common/definition_provider.widget.dart';
import 'package:little_light/widgets/common/item_icon/item_icon.widget.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';
import 'package:shimmer/shimmer.dart';

class InventoryNotificationWidget extends StatefulWidget {
  final service = NotificationService();
  final double barHeight;
  final EdgeInsets notificationMargin;

  InventoryNotificationWidget(
      {Key key,
      this.barHeight = kBottomNavigationBarHeight,
      this.notificationMargin})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return InventoryNotificationWidgetState();
  }
}

class InventoryNotificationWidgetState
    extends State<InventoryNotificationWidget> with ProfileConsumer {
  NotificationEvent _latestEvent;
  bool get _busy =>
      _latestEvent != null &&
      _latestEvent?.type != NotificationType.receivedUpdate;
  bool get _isError => [
        NotificationType.transferError,
        NotificationType.equipError,
        NotificationType.updateError
      ].contains(_latestEvent?.type);
  StreamSubscription<NotificationEvent> subscription;

  @override
  void initState() {
    super.initState();

    subscription = widget.service.listen((event) {
      handleNotification(event);
    });

    if (widget.service.latestNotification != null) {
      handleNotification(widget.service.latestNotification);
    }
  }

  void handleNotification(NotificationEvent event) async {
    if (event.type == NotificationType.localUpdate) return;
    _latestEvent = event;
    setState(() {});
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: bottomPadding + kToolbarHeight + widget.barHeight,
        child: _busy ? busyWidget(context) : Container());
  }

  Widget busyWidget(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Stack(fit: StackFit.expand, children: [
      Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding + widget.barHeight,
          child: shimmerBar(context)),
      Positioned(
          right: 8,
          bottom: bottomPadding + widget.barHeight + 10,
          child: buildBusyContent(context)),
      bottomPadding > 1
          ? Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomPadding,
              child: bottomPaddingShimmer(context))
          : Container()
    ]);
  }

  Widget buildMessage(BuildContext context) {
    switch (_latestEvent.type) {
      case NotificationType.requestedUpdate:
        return TranslatedTextWidget("Updating",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.requestedTransfer:
        return TranslatedTextWidget("Transferring",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.requestedVaulting:
        return TranslatedTextWidget("Moving Away",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.requestedEquip:
        return TranslatedTextWidget("Equipping",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.updateError:
        return TranslatedTextWidget("Update failed",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.transferError:
        return TranslatedTextWidget("Transfer failed",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      case NotificationType.equipError:
        return TranslatedTextWidget("Equip failed",
            uppercase: true, style: TextStyle(fontWeight: FontWeight.bold));
        break;

      default:
        return Container();
    }
  }

  Widget buildIcons(BuildContext context) {
    switch (_latestEvent.type) {
      case NotificationType.requestedTransfer:
      case NotificationType.requestedVaulting:
        var instanceInfo =
            profile.getInstanceInfo(_latestEvent.item.itemInstanceId);
        return Container(
          margin: EdgeInsets.only(left: 8),
          width: 24,
          height: 24,
          key: Key("item_${_latestEvent.item.itemHash}"),
          child: DefinitionProviderWidget<DestinyInventoryItemDefinition>(
              _latestEvent.item.itemHash,
              (def) => ItemIconWidget(
                    _latestEvent.item,
                    def,
                    instanceInfo,
                    iconBorderWidth: 0,
                  )),
        );
        break;

      case NotificationType.updateError:
        return Container(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.signal_wifi_off,
              size: 16,
            ));
        break;

      case NotificationType.transferError:
        return Container(
          padding: EdgeInsets.only(left: 4),
          width: 24,
          height: 24,
          key: Key("item_${_latestEvent.item.itemHash}"),
          child: ManifestImageWidget<DestinyInventoryItemDefinition>(
              _latestEvent.item.itemHash),
        );
        break;

      default:
        return Container();
    }
  }

  Widget buildBusyContent(BuildContext context) {
    return Container(
        margin: widget.notificationMargin,
        decoration: BoxDecoration(
            color: _isError
                ? Theme.of(context).errorColor
                : LittleLightTheme.of(context).surfaceLayers.layer2,
            borderRadius: BorderRadius.all(Radius.circular(16))),
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: _isError
                  ? buildMessage(context)
                  : ShimmerHelper.getDefaultShimmer(context, child:buildMessage(context))),
          buildIcons(context)
        ]));
  }

  Widget shimmerBar(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.secondary,
        highlightColor: Colors.grey.shade100,
        child: Container(height: 2, color: Theme.of(context).colorScheme.onSurface));
  }

  Widget bottomPaddingShimmer(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.transparent,
        highlightColor: Colors.grey.shade300,
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.transparent, Theme.of(context).colorScheme.onSurface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
        ));
  }
}
