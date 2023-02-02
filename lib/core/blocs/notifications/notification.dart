import 'package:flutter/material.dart';

abstract class NotificationAction extends ChangeNotifier {
  String get id;
  bool _finished = false;
  bool get isFinished => _finished;
  void finish() {
    this._finished = true;
    notifyListeners();
    dispose();
  }
}

class UpdateAction extends NotificationAction {
  UpdateAction();
  String get id => "update-action";
}

class ErrorAction extends NotificationAction {
  ErrorAction();
  String get id => "error-action";
}

class UpdateErrorAction extends ErrorAction {
  UpdateErrorAction();
  String get id => "update-error-action";
}

class SingleTransferAction extends NotificationAction {
  final String? itemInstanceId;
  final int? itemHash;
  SingleTransferAction({
    this.itemHash,
    this.itemInstanceId,
  });
  String get id => "transfer-action-$itemHash-$itemInstanceId";
}
