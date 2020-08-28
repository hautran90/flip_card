library flip_card;

import 'dart:math';
import 'package:flutter/material.dart';

enum FlipDirection {
  VERTICAL,
  HORIZONTAL,
}

class AnimationCard extends StatelessWidget {
  AnimationCard({this.child, this.animation, this.direction});

  final Widget child;
  final Animation<double> animation;
  final FlipDirection direction;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        var transform = Matrix4.identity();
        transform.setEntry(3, 2, 0.001);
        if (direction == FlipDirection.VERTICAL) {
          transform.rotateX(animation.value);
        } else {
          transform.rotateY(animation.value);
        }
        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: child,
    );
  }
}

typedef void BoolCallback(bool isFront);

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Color colorBackgroundFront;
  final Widget widgetIconFront;
  final Widget widgetIconBack;
  final Widget titleWidgetFront;
  final Color colorHeaderTitle;
  final Widget titleWidgetBack;
  final Color colorBackgroundBack;

  /// The amount of milliseconds a turn animation will take.
  final int speed;
  final FlipDirection direction;
  final VoidCallback onFlip;
  final BoolCallback onFlipDone;

  /// When enabled, the card will flip automatically when touched. This behavior
  /// can be disabled if this is not desired. To manually flip a card from your
  /// code, you could do this:
  ///```dart
  /// GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();
  ///
  /// @override
  /// Widget build(BuildContext context) {
  ///   return FlipCard(
  ///     key: cardKey,
  ///     flipOnTouch: false,
  ///     front: Container(
  ///       child: RaisedButton(
  ///         onPressed: () => cardKey.currentState.toggleCard(),
  ///         child: Text('Toggle'),
  ///       ),
  ///     ),
  ///     back: Container(
  ///       child: Text('Back'),
  ///     ),
  ///   );
  /// }
  ///```
  final bool flipOnTouch;

  const FlipCard(
      {Key key,
      @required this.front,
      @required this.back,
      this.colorBackgroundFront,
      this.colorBackgroundBack,
      this.titleWidgetFront,
      this.widgetIconBack,
      this.widgetIconFront,
      this.colorHeaderTitle,
      this.titleWidgetBack,
      this.speed = 500,
      this.onFlip,
      this.onFlipDone,
      this.direction = FlipDirection.HORIZONTAL,
      this.flipOnTouch = true})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlipCardState();
  }
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> _frontRotation;
  Animation<double> _backRotation;

  bool isFront = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: Duration(milliseconds: widget.speed), vsync: this);
    _frontRotation = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(begin: 0.0, end: pi / 2)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
      ],
    ).animate(controller);
    _backRotation = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(begin: -pi / 2, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50.0,
        ),
      ],
    ).animate(controller);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (widget.onFlipDone != null) widget.onFlipDone(isFront);
      }
    });
  }

  void toggleCard() {
    if (widget.onFlip != null) {
      widget.onFlip();
    }
    if (isFront) {
      controller.forward();
    } else {
      controller.reverse();
    }

    setState(() {
      isFront = !isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        _buildContent(front: true),
        _buildContent(front: false),
      ],
    );

//    if (widget.flipOnTouch) {
//      return GestureDetector(
//        behavior: HitTestBehavior.translucent,
//        onTap: toggleCard,
//        child: child,
//      );
//    }

    // if we need to flip the card on taps, wrap the content
    return child;
  }

  Widget _buildContent({@required bool front, Function onTap}) {
    // pointer events that would reach the backside of the card should be
    // ignored
    return IgnorePointer(
      // absorb the front card when the background is active (!isFront),
      // absorb the background when the front is active
      ignoring: front ? !isFront : isFront,
      child: AnimationCard(
        animation: front ? _frontRotation : _backRotation,
        child: front
            ? Container(
                decoration: BoxDecoration(
                  color: widget.colorBackgroundFront == null
                      ? Color(0xFF006666)
                      : widget.colorBackgroundFront,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      color: widget.colorHeaderTitle,
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            widget.titleWidgetFront,
                            GestureDetector(
                              onTap: () {
                                if (widget.flipOnTouch) {
                                  toggleCard();
                                }
                              },
                              child: Align(
                                  alignment: Alignment.topRight,
                                  child: widget.widgetIconFront),
                            ),
                          ],
                        ),
                      ),
                    ),
                    widget.front
                  ],
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: widget.colorBackgroundBack == null
                      ? Color(0xFF006666)
                      : widget.colorBackgroundBack,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      color: widget.colorHeaderTitle,
                      child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            widget.titleWidgetBack,
                            GestureDetector(
                              onTap: () {
                                if (widget.flipOnTouch) {
                                  toggleCard();
                                }
                              },
                              child: Align(
                                  alignment: Alignment.topRight,
                                  child: widget.widgetIconBack),
                            ),
                          ],
                        ),
                      ),
                    ),
                    widget.back
                  ],
                ),
              ),
        direction: widget.direction,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
