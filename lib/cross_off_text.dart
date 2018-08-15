library cross_off_text;

import 'package:flutter/material.dart';

class CrossOffText extends StatefulWidget {
  final String text;
  final EdgeInsets padding;
  final bool initCrossed;
  final bool highlight;

  CrossOffText(
      {Key key,
      @required this.text,
      this.initCrossed = false,
      this.highlight = false,
      this.padding = const EdgeInsets.all(0.0)})
      : super(key: key);

  _CrossOffTextState createState() => new _CrossOffTextState(initCrossed);
}

class _CrossOffTextState extends State<CrossOffText> {
  bool crossed;

  _CrossOffTextState(this.crossed);

  void toggle() {
    setState(() {
      this.crossed = !this.crossed;
    });
  }

  @override
  Widget build(BuildContext context) {
    var color = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    var textStyle = widget.highlight
        ? new TextStyle(color: Theme.of(context).accentColor)
        : new TextStyle(color: color);
    if (this.crossed)
      return new Container(
          foregroundDecoration: new StrikeThroughDecoration(color),
          child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Padding(
                  padding: widget.padding,
                  child: Text(widget.text, style: textStyle)),
              onTap: this.toggle));
    else
      return new GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Padding(
              padding: widget.padding,
              child: Text(widget.text, style: textStyle)),
          onTap: this.toggle);
  }
}

class StrikeThroughDecoration extends Decoration {
  final Color color;
  StrikeThroughDecoration(this.color);
  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new _StrikeThroughPainter(this.color);
  }
}

class _StrikeThroughPainter extends BoxPainter {
  final Color color;
  _StrikeThroughPainter(this.color);
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = new Paint()
      ..strokeWidth = 2.0
      ..color = this.color
      ..style = PaintingStyle.fill;

    final rect = offset & configuration.size;
    canvas.drawLine(
        new Offset(rect.left + rect.width / 4, rect.bottom - rect.height / 3),
        new Offset(rect.right - rect.width / 4, rect.top + rect.height / 3),
        paint);
    canvas.restore();
  }
}
