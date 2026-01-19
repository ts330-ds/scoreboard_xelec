import 'package:flutter/material.dart';



class BasketBallDesktop extends StatelessWidget {
  const BasketBallDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text("BasketBall"),
      ),
      body: SafeArea(
        child: Text("DEsktop")
      ),
    );
  }
}
