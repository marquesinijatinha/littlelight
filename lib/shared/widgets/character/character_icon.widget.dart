import 'package:bungie_api/destiny2.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/profile/destiny_character_info.dart';
import 'package:little_light/services/manifest/manifest.consumer.dart';
import 'package:little_light/shared/utils/extensions/character_data.dart';
import 'package:little_light/shared/widgets/character/base_character_icon.widget.dart';
import 'package:little_light/widgets/common/manifest_image.widget.dart';

class CharacterIconWidget extends BaseCharacterIconWidget {
  final DestinyCharacterInfo character;
  const CharacterIconWidget(
    this.character, {
    double borderWidth = characterIconDefaultBorderWidth,
    double fontSize = characterIconDefaultFontSize,
    bool hideName = false,
  }) : super(
          borderWidth: borderWidth,
          fontSize: fontSize,
          hideName: hideName,
        );
  @override
  Widget buildIcon(BuildContext context) => ManifestImageWidget<DestinyInventoryItemDefinition>(
        character.character.emblemHash,
      );

  @override
  String? getName(BuildContext context) {
    final classDef = context.definition<DestinyClassDefinition>(character.character.classHash);
    final name = character.getGenderedClassName(classDef);
    return name;
  }
}
