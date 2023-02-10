import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/shared/widgets/character/profile_icon.widget.dart';
import 'package:little_light/shared/widgets/character/vault_icon.widget.dart';

const _iconSize = 24.0;

typedef OnTransferPressed = void Function(int profileCount, int vaultCount);

class StackTransferWidget extends StatefulWidget {
  final int initialProfileCounts;
  final int initialVaultCounts;
  final OnTransferPressed onTransferPressed;
  const StackTransferWidget({
    Key? key,
    required this.initialProfileCounts,
    required this.initialVaultCounts,
    required this.onTransferPressed,
  }) : super(key: key);

  @override
  State<StackTransferWidget> createState() => _StackTransferWidgetState();
}

class _StackTransferWidgetState extends State<StackTransferWidget> {
  double sliderValue = 0;
  int profileCount = 0;
  int vaultCount = 0;
  int total = 0;

  @override
  void initState() {
    super.initState();
    profileCount = widget.initialProfileCounts;
    vaultCount = widget.initialVaultCounts;
    total = widget.initialProfileCounts + widget.initialVaultCounts;
    sliderValue = vaultCount / total;
  }

  void updateValues(double value) {
    sliderValue = value;
    vaultCount = (value * total).ceil();
    profileCount = total - vaultCount;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildSlider(context),
          buildCounts(context),
          buildTransferButton(context),
        ],
      ),
    );
  }

  Widget buildSlider(BuildContext context) => Row(
        children: [
          const SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: ProfileIconWidget(borderWidth: .5),
          ),
          Expanded(
              child: Container(
            child: Slider(
              value: sliderValue,
              onChanged: updateValues,
              divisions: total,
            ),
          )),
          const SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: VaultIconWidget(borderWidth: 0.5),
          ),
        ],
      );

  Widget buildCounts(BuildContext context) => Row(
        children: [
          Container(
            child: Text("$profileCount"),
          ),
          Expanded(child: Container()),
          Container(
            child: Text("$vaultCount"),
          ),
        ],
      );
  Widget buildTransferButton(BuildContext context) => Container(
        padding: const EdgeInsets.only(top: 16),
        child: ElevatedButton(
          child: Text("Transfer".translate(context)),
          onPressed: () {
            widget.onTransferPressed(profileCount, vaultCount);
          },
        ),
      );
}
