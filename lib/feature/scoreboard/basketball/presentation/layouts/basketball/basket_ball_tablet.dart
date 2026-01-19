import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

import '../../widget/basketscoreboardPreviewUi.dart';
import '../../widget/controlPanalUi.dart';


class BasketBallTablet extends StatelessWidget {
  const BasketBallTablet({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BasketBall"),
      ),
      body: SafeArea(
        child: Center(
          child: Card(
            elevation: 6,
            color: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 720, // tablet card width
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: const [
                    BasketScoreboardPreviewUI(),
                    Expanded(
                      flex: 6,
                      child: BasketBallControlPanelUI(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
