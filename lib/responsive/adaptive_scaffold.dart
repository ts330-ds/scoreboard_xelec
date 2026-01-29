import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xelex_esp/utility/theme_extension.dart';

class AdaptiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final VoidCallback? onSettingsPressed;
  final Color appBarBackground;
  final Color textColor;

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.onSettingsPressed,
    this.appBarBackground = Colors.blue,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // 🌐 Web
    if (kIsWeb) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: AppBar(
          titleSpacing: 10,
          elevation: 0,
          backgroundColor: appBarBackground,
          title: Text(
            title,
            style: context.text.titleSmall!
                .copyWith(color: textColor),
          ),
          actions: onSettingsPressed != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: onSettingsPressed,
                    color: context.colors.surface,
                  ),
                ]
              : null,
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: body),
      );
    }

    // 🍎 iOS
    if (Platform.isIOS) {
      return CupertinoPageScaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            title,
            style: context.text.titleSmall!
                .copyWith(color: context.colors.surface),
          ),
          trailing: onSettingsPressed != null
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onSettingsPressed,
                  child: Icon(
                    CupertinoIcons.settings,
                    color: context.colors.surface,
                  ),
                )
              : null,
        ),
        child: SafeArea(child: body),
      );
    }

    // 🤖 Android
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          title,
          style: context.text.titleSmall!
              .copyWith(color: context.colors.surface),
        ),
        actions: onSettingsPressed != null
            ? [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: onSettingsPressed,
                  color: context.colors.surface,
                ),
              ]
            : null,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
    );
  }
}
