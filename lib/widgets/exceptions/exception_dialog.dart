// @dart=2.9

import 'package:bungie_api/helpers/oauth.dart';
import 'package:flutter/material.dart';
import 'package:little_light/core/blocs/language/language.consumer.dart';
import 'package:little_light/widgets/common/translated_text.widget.dart';

typedef OnDismiss = void Function(String labelClicked);

class ExceptionDialog extends AlertDialog {
  final dynamic exception;
  final BuildContext context;
  final OnDismiss onDismiss;
  const ExceptionDialog(this.context, this.exception, {this.onDismiss});

  @override
  Widget get title {
    if (exception is OAuthException) {
      return Text("Authentication Error".translate(context));
    }
    return Text("Error".translate(context));
  }

  @override
  Widget get content {
    if (exception is OAuthException) {
      OAuthException ex = exception as OAuthException;
      return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
        TranslatedTextWidget(ex.error),
        TranslatedTextWidget(ex.errorDescription),
      ]);
    }
    return Text("UnknownError".translate(context));
  }

  @override
  List<Widget> get actions {
    List<String> labels = ['OK'];
    if (exception is OAuthException) {
      labels.add("Login");
    }
    return labels
        .map((label) => ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onDismiss != null) {
                  onDismiss(label);
                }
              },
              child: TranslatedTextWidget(
                label,
                uppercase: true,
                style: TextStyle(color: Colors.indigo.shade300),
              ),
            ))
        .toList();
  }
}
