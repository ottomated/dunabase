library dual_panel;

import 'package:flutter/material.dart';
import 'dart:math';

class DualPanel extends StatefulWidget {
  final Widget left;
  final Widget right;
  final bool isLeft;

  DualPanel({
    Key key,
    @required this.left,
    @required this.right,
    this.isLeft = true,
  }) : super(key: key);

  _DualPanelState createState() => new _DualPanelState(this.isLeft);
}

class _DualPanelState extends State<DualPanel> with TickerProviderStateMixin {
  bool _isLeft;
  AnimationController _controller;
  CurvedAnimation _animation;
  ScrollController _scrollController = new ScrollController();

  _DualPanelState(this._isLeft);

  void toggle() {
    setState(() {
      if (_isLeft)
        _controller.forward(from: 0.0);
      else
        _controller.reverse(from: 1.0);
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
      ..addStatusListener((status) {
        if (status == AnimationStatus.forward) {
          setState(() {
            this._isLeft = !this._isLeft;
            this._scrollController.animateTo(
                this._scrollController.position.maxScrollExtent,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 600));
          });
        } else if (status == AnimationStatus.reverse) {
          setState(() {
            this._isLeft = !this._isLeft;
            this._scrollController.animateTo(0.0,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 600));
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return new NotificationListener<ScrollNotification>( onNotification: (_) => true,child:SingleChildScrollView(
          controller: _scrollController,
          physics: NeverScrollableScrollPhysics(),
          scrollDirection: Axis.horizontal,
          child: 
            new Container(
                width: constraints.maxWidth * 9.0 / 5.0,
                child: new Row(children: [
                  new Expanded(child: widget.left, flex: 4),
                  new Expanded(
                    flex: 1,
                    child: new AnimatedBuilder(
                      child: IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            this.toggle();
                          }),
                      animation: _animation,
                      builder: (BuildContext context, Widget _widget) {
                        double angle = _animation.value * pi;
                        return new Transform.rotate(
                          angle: angle,
                          child: _widget,
                        );
                      },
                    ),
                  ),
                  new Expanded(child: widget.right, flex: 4),
                ]))
          ));
    });
  }
}
