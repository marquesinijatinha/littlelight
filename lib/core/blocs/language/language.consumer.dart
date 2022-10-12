import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'language.bloc.dart';

LanguageBloc getInjectedLanguageService() => GetIt.I<LanguageBloc>();

extension LanguageContextConsumer on BuildContext {
  String get currentLanguage => this.watch<LanguageBloc>().currentLanguage;

  String translate(String text, {String? languageCode, Map<String, String> replace = const {}}) =>
      this.watch<LanguageBloc>().translate(text, languageCode: languageCode, replace: replace);
}