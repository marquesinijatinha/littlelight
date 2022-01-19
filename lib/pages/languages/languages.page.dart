//@dart=2.12
import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:little_light/core/theme/littlelight.theme.dart';
import 'package:little_light/models/language_info.dart';
import 'package:little_light/services/language/language.consumer.dart';
import 'package:little_light/widgets/common/loading_anim.widget.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';

class LanguagesPage extends StatefulWidget {
  @override
  _LanguagesPageState createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> with LanguageConsumer {
  List<LanguageInfo>? languages;
  String? currentLanguage;
  String? selectedLanguage;

  @override
  void initState() {
    super.initState();
    loadLanguages();
  }

  void loadLanguages() async {
    currentLanguage = selectedLanguage = languageService.currentLanguage;
    languages = await languageService.getManifestSizes();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TranslatedTextWidget(
          "Change Language",
          language: selectedLanguage,
          key: Key("title_$selectedLanguage"),
        ),
      ),
      body: languages == null ? LoadingAnimWidget() : buildBody(context),
      bottomNavigationBar: buildBottomBar(context),
    );
  }

  Widget buildBottomBar(BuildContext context) {
    if (currentLanguage == selectedLanguage) {
      return Container(height: 0);
    }
    var bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Theme.of(context).colorScheme.secondary,
      padding: EdgeInsets.all(8).copyWith(bottom: bottomPadding + 8),
      child: ElevatedButton(
          onPressed: () {
            languageService.selectedLanguage = selectedLanguage;
            Phoenix.rebirth(context);
          },
          child: TranslatedTextWidget(
            "Change Language",
            language: selectedLanguage,
            key: Key("button_$selectedLanguage"),
          )),
    );
  }

  Widget buildBody(BuildContext context) {
    final languages = this.languages;
    if(languages == null) return LoadingAnimWidget();
    return SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(children: languages.map((l) => buildLanguageItem(context, l)).toList()));
  }

  Widget buildLanguageItem(BuildContext context, LanguageInfo language) {
    var color = Theme.of(context).colorScheme.secondaryVariant;
    if (language.code == currentLanguage) {
      color = Theme.of(context).colorScheme.secondary;
    }
    if (language.code == selectedLanguage) {
      color = Colors.lightBlue.shade500;
    }
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                selectedLanguage = language.code;
                setState(() {});
              },
              child: Container(
                  padding: EdgeInsets.all(4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [buildLanguageInfo(context, language), buildFileInfo(context, language)]))),
        ));
  }

  Widget buildLanguageInfo(BuildContext context, LanguageInfo language) {
    return Row(children: [
      Container(width: 8, height: 40),
      Container(width: 4),
      Text(
        language.name,
        style: TextStyle(fontWeight: FontWeight.bold),
      )
    ]);
  }

  Widget buildFileInfo(BuildContext context, LanguageInfo language) {
    final sizeInKB = language.sizeInKB;
    final size = sizeInKB != null ? sizeInKB / 1024 : null;

    var canDelete = language.code != currentLanguage && size != null;
    return Row(children: [
      if (size != null)
        Text(
          "${size.toStringAsFixed(2)} MB",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      Container(width: size != null ? 8 : 0),
      !canDelete
          ? Container()
          : Material(
              color: LittleLightTheme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () async {
                    await languageService.deleteLanguage(language.code);
                    loadLanguages();
                  },
                  child: Container(
                      padding: EdgeInsets.all(8),
                      child: TranslatedTextWidget(
                        "Delete",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )))),
      Container(
        width: !canDelete ? 0 : 4,
      )
    ]);
  }
}