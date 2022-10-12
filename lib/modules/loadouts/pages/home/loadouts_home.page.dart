import 'package:flutter/material.dart';
import 'package:little_light/modules/loadouts/pages/home/loadouts_home.bloc.dart';
import 'package:little_light/modules/loadouts/pages/home/loadouts_home.view.dart';
import 'package:provider/provider.dart';

class LoadoutsHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoadoutsHomeBloc(context)),
      ],
      child: LoadoutsHomeView(),
    );
  }
}