// HandTileWidget.dart
import 'package:flutter/material.dart';
import '../utils/tiles.dart';

class HandTileWidget extends StatefulWidget {
  final String cls;
  final String path;
  final bool isSelected;
  final bool isWinning;
  final bool isInSet;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const HandTileWidget({
    super.key,
    required this.cls,
    required this.path,
    this.isSelected = false,
    this.isWinning = false,
    this.isInSet = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<HandTileWidget> createState() => _HandTileWidgetState();
}

class _HandTileWidgetState extends State<HandTileWidget> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 4 * 9 - 32) / 10;
    double cardHeight = cardWidth * 1.5;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: EdgeInsets.only(
          bottom: widget.isSelected ? 8 : 0,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: widget.isWinning
                ? Colors.greenAccent
                : widget.isInSet
                    ? Colors.red
                    : widget.isSelected
                        ? Colors.yellowAccent
                        : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: widget.path.isNotEmpty
            ? Image.asset(widget.path, width: cardWidth, height: cardHeight)
            : Container(width: cardWidth, height: cardHeight, color: Colors.grey),
      ),
    );
  }
}
