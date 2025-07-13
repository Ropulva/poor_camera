import 'package:flutter/material.dart';

class PoorIconButton extends StatelessWidget {
  const PoorIconButton({super.key, this.onPressed, required this.icon, this.width = 30});
  final void Function()? onPressed;
  final Widget icon;
  final double width ;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
        style: IconButton.styleFrom(
            backgroundColor: Color(0xFF2d2e2e ) , //222623
        ),
        padding: EdgeInsets.symmetric(horizontal: 10,vertical: 10),
        color: Colors.white,
        iconSize: width,
        icon: icon,
        onPressed: onPressed
    );
  }
}
