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
  final Color bodyBackground;
  final Color textColor;
  final Widget settingsIcon;
  final List<Widget>? actions; // optional extra actions (e.g. notification icon)

  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.onSettingsPressed,
    this.appBarBackground = Colors.blue,
    this.textColor = Colors.white,
    this.bodyBackground = Colors.white,
    this.settingsIcon = const Icon(Icons.settings),
    this.actions,
  });

  /// Settings icon + extra actions ko merge karta hai
  List<Widget>? _buildActions(BuildContext context) {
    final list = <Widget>[
      if (actions != null) ...actions!,
      if (onSettingsPressed != null)
        IconButton(
          icon: settingsIcon,
          onPressed: onSettingsPressed,
          color: context.colors.surface,
        ),
    ];
    return list.isEmpty ? null : list;
  }

  @override
  Widget build(BuildContext context) {
    // 🌐 Web
    if (kIsWeb) {
      return Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: bodyBackground,
        appBar: AppBar(
          titleSpacing: 10,
          elevation: 0,
          backgroundColor: appBarBackground,
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall!.copyWith(color: textColor),
          ),
          actions: _buildActions(context),
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: body),
      );
    }

    // 🍎 iOS
    if (Platform.isIOS) {
      final iosActions = _buildActions(context);
      return CupertinoPageScaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: bodyBackground,
        navigationBar: CupertinoNavigationBar(
          middle: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall!.copyWith(
              color: context.colors.primary,
            ),
          ),
          trailing: iosActions != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: iosActions,
                )
              : null,
        ),
        child: SafeArea(child: body),
      );
    }

    // 🤖 Android
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: bodyBackground,
      appBar: AppBar(
        titleSpacing: 10,
        elevation: 0,
        backgroundColor: appBarBackground,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.titleSmall!.copyWith(color: textColor),
        ),
        actions: _buildActions(context),
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: body),
    );
  }
}
