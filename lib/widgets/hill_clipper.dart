import 'package:flutter/material.dart';

class HillClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Fixed: Changed from getPath to getClip
    Path path = Path();

    // Start at top-left, go down to just before the curve starts
    path.lineTo(0, size.height - 50);

    // Create the smooth hill curve
    // The control point is at the bottom center to "pull" the line down
    var controlPoint = Offset(size.width / 2, size.height);
    var endPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        controlPoint.dx, controlPoint.dy, endPoint.dx, endPoint.dy);

    // Close the shape by going to the top-right corner
    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
