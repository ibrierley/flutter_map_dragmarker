import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';

class DragMarkers extends StatefulWidget {
  final List<DragMarker> markers;

  DragMarkers({Key? key, this.markers = const []});

  @override
  State<DragMarkers> createState() => _DragMarkersState();
}

class _DragMarkersState extends State<DragMarkers> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var dragMarkers = <Widget>[];

    FlutterMapState? mapState = FlutterMapState.maybeOf(context);

    for (var marker in widget.markers) {
      if (!_boundsContainsMarker(mapState, marker)) continue;

      dragMarkers.add(DragMarkerWidget(
          mapState: mapState,
          marker: marker));
    }
    return Stack(children: dragMarkers);
  }

  static bool _boundsContainsMarker(FlutterMapState? map, DragMarker marker) {
    var pixelPoint = map!.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);

    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }
}

class DragMarkerWidget extends StatefulWidget {
  const DragMarkerWidget(
      {Key? key,
        this.mapState,
        required this.marker,
        AnchorPos? anchorPos})
  //: anchor = Anchor.forPos(anchorPos, marker.width, marker.height);
      : super(key: key);

  final FlutterMapState? mapState;
  //final Anchor anchor;
  final DragMarker marker;

  @override
  State<DragMarkerWidget> createState() => _DragMarkerWidgetState();
}

class _DragMarkerWidgetState extends State<DragMarkerWidget> {
  CustomPoint pixelPosition = const CustomPoint(0.0, 0.0);
  late LatLng dragPosStart;
  late LatLng markerPointStart;
  late LatLng oldDragPosition;
  bool isDragging = false;
  late LatLng markerPoint;

  static Timer? autoDragTimer;

  @override
  void initState() {
    markerPoint = widget.marker.point;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant DragMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.marker.preservePosition && !isDragging) {
      markerPoint = widget.marker.point;
    }
  }

  @override
  Widget build(BuildContext context) {
    DragMarker marker = widget.marker;
    updatePixelPos(markerPoint);

    bool feedBackEnabled = isDragging && marker.feedbackBuilder != null;
    Widget displayMarker = feedBackEnabled
        ? marker.feedbackBuilder!(context)
        : marker.builder!(context);

    return GestureDetector(
      onPanStart: marker.useLongPress ? null : onPanStart,
      onPanUpdate: marker.useLongPress ? null : onPanUpdate,
      onPanEnd: marker.useLongPress ? null : onPanEnd,
      onLongPressStart: marker.useLongPress ? onLongPanStart : null,
      onLongPressMoveUpdate: marker.useLongPress ? onLongPanUpdate : null,
      onLongPressEnd: marker.useLongPress ? onLongPanEnd : null,
      onTap: () {
        if (marker.onTap != null) {
          marker.onTap!(markerPoint);
        }
      },
      onLongPress: () {
        if (marker.onLongPress != null) {
          marker.onLongPress!(markerPoint);
        }
      },
      child: Stack(children: [
        Positioned(
            width: marker.width,
            height: marker.height,
            left: pixelPosition.x +
                ((isDragging) ? marker.feedbackOffset.dx : marker.offset.dx),
            top: pixelPosition.y +
                ((isDragging) ? marker.feedbackOffset.dy : marker.offset.dy),
            child: widget.marker.rotateMarker
                ? Transform.rotate(
                angle: -widget.mapState!.rotationRad, child: displayMarker)
                : displayMarker)
      ]),
    );
  }

  void updatePixelPos(point) {
    DragMarker marker = widget.marker;
    FlutterMapState? mapState = widget.mapState;

    CustomPoint pos;
    if (mapState != null) {
      pos = mapState.project(point);
      pos =
          pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
              mapState.pixelOrigin;

      pixelPosition = CustomPoint(
          (pos.x - (marker.width - widget.marker.anchor.left)).toDouble(),
          (pos.y - (marker.height - widget.marker.anchor.top)).toDouble());
    }
  }

  void _start(Offset localPosition) {
    isDragging = true;
    dragPosStart = _offsetToCrs(localPosition);
    markerPointStart =
        LatLng(markerPoint.latitude, markerPoint.longitude);
  }

  void onPanStart(DragStartDetails details) {
    _start(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onDragStart != null) marker.onDragStart!(details, markerPoint);
  }

  void onLongPanStart(LongPressStartDetails details) {
    _start(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onLongDragStart != null) {
      marker.onLongDragStart!(details, markerPoint);
    }
  }

  void _pan(Offset localPosition) {
    bool isDragging = true;
    DragMarker marker = widget.marker;
    FlutterMapState? mapState = widget.mapState;

    var dragPos = _offsetToCrs(localPosition);

    var deltaLat = dragPos.latitude - dragPosStart.latitude;
    var deltaLon = dragPos.longitude - dragPosStart.longitude;

    var pixelB = mapState?.getPixelBounds(mapState.zoom);    //getLastPixelBounds();
    var pixelPoint = mapState?.project(markerPoint);

    /// If we're near an edge, move the map to compensate.

    if (marker.updateMapNearEdge) {
      /// How much we'll move the map by to compensate

      var autoOffsetX = 0.0;
      var autoOffsetY = 0.0;
      if (pixelB != null && pixelPoint != null) {
        if (pixelPoint.x + marker.width * marker.nearEdgeRatio >=
            pixelB.topRight.x) autoOffsetX = marker.nearEdgeSpeed;
        if (pixelPoint.x - marker.width * marker.nearEdgeRatio <=
            pixelB.bottomLeft.x) autoOffsetX = -marker.nearEdgeSpeed;
        if (pixelPoint.y - marker.height * marker.nearEdgeRatio <=
            pixelB.topRight.y) autoOffsetY = -marker.nearEdgeSpeed;
        if (pixelPoint.y + marker.height * marker.nearEdgeRatio >=
            pixelB.bottomLeft.y) autoOffsetY = marker.nearEdgeSpeed;
      }

      /// Sometimes when dragging the onDragEnd doesn't fire, so just stops dead.
      /// Here we allow a bit of time to keep dragging whilst user may move
      /// around a bit to keep it going.

      var lastTick = 0;
      if (autoDragTimer != null) lastTick = autoDragTimer!.tick;

      if ((autoOffsetY != 0.0) || (autoOffsetX != 0.0)) {
        adjustMapToMarker(widget, autoOffsetX, autoOffsetY);

        if ((autoDragTimer == null || autoDragTimer?.isActive == false) &&
            (isDragging == true)) {
          autoDragTimer =
              Timer.periodic(const Duration(milliseconds: 10), (Timer t) {
                var tick = autoDragTimer?.tick;
                bool tickCheck = false;
                if (tick != null) {
                  if (tick > lastTick + 15) {
                    tickCheck = true;
                  }
                }
                if (isDragging == false || tickCheck) {
                  autoDragTimer?.cancel();
                } else {
                  /// Note, we may have adjusted a few lines up in same drag,
                  /// so could test for whether we've just done that
                  /// this, but in reality it seems to work ok as is.

                  adjustMapToMarker(widget, autoOffsetX, autoOffsetY);
                }
              });
        }
      }
    }

    setState(() {
      markerPoint = LatLng(markerPointStart.latitude + deltaLat,
          markerPointStart.longitude + deltaLon);
      widget.marker.point = markerPoint;
      updatePixelPos(markerPoint);
    });
  }

  void onPanUpdate(DragUpdateDetails details) {
    _pan(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onDragUpdate != null) {
      marker.onDragUpdate!(details, markerPoint);
    }
  }

  void onLongPanUpdate(LongPressMoveUpdateDetails details) {
    _pan(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onLongDragUpdate != null) {
      marker.onLongDragUpdate!(details, markerPoint);
    }
  }

  /// If dragging near edge of the screen, adjust the map so we keep dragging
  void adjustMapToMarker(DragMarkerWidget widget, autoOffsetX, autoOffsetY) {
    DragMarker marker = widget.marker;
    FlutterMapState? mapState = widget.mapState;

    var oldMapPos = mapState?.project(mapState.center);
    LatLng? newMapLatLng;
    CustomPoint<num>? oldMarkerPoint;
    if (oldMapPos != null) {
      newMapLatLng = mapState?.unproject(
          CustomPoint(oldMapPos.x + autoOffsetX, oldMapPos.y + autoOffsetY));
      oldMarkerPoint = mapState?.project(markerPoint);
    }
    if (mapState != null && newMapLatLng != null && oldMarkerPoint != null) {
      markerPoint = mapState.unproject(CustomPoint(
          oldMarkerPoint.x + autoOffsetX, oldMarkerPoint.y + autoOffsetY));

      mapState.move(newMapLatLng, mapState.zoom, source: MapEventSource.onDrag);
    }
  }

  void _end() {
    isDragging = false;
    if (autoDragTimer != null) autoDragTimer?.cancel();
  }

  void onPanEnd(details) {
    _end();
    if (widget.marker.onDragEnd != null) {
      widget.marker.onDragEnd!(details, markerPoint);
    }
    setState(() {}); // Needed if using a feedback widget
  }

  void onLongPanEnd(details) {
    _end();
    if (widget.marker.onLongDragEnd != null) {
      widget.marker.onLongDragEnd!(details, markerPoint);
    }
    setState(() {}); // Needed if using a feedback widget
  }

  static CustomPoint _offsetToPoint(Offset offset) {
    return CustomPoint(offset.dx, offset.dy);
  }

  LatLng _offsetToCrs(Offset offset) {
    // Get the widget's offset
    var renderObject = context.findRenderObject() as RenderBox;
    var width = renderObject.size.width;
    var height = renderObject.size.height;
    var mapState = widget.mapState;

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
    CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    if (mapState != null) {
      var mapCenter = mapState.project(mapState.center);
      var point = mapCenter - localPointCenterDistance;
      return mapState.unproject(point);
    }
    return LatLng(0, 0);
  }
}

class DragMarker {
  LatLng point;
  final WidgetBuilder? builder;
  final WidgetBuilder? feedbackBuilder;
  final double width;
  final double height;
  final Offset offset;
  final Offset feedbackOffset;
  final bool useLongPress;
  final Function(DragStartDetails, LatLng)? onDragStart;
  final Function(DragUpdateDetails, LatLng)? onDragUpdate;
  final Function(DragEndDetails, LatLng)? onDragEnd;
  final Function(LongPressStartDetails, LatLng)? onLongDragStart;
  final Function(LongPressMoveUpdateDetails, LatLng)? onLongDragUpdate;
  final Function(LongPressEndDetails, LatLng)? onLongDragEnd;
  final Function(LatLng)? onTap;
  final Function(LatLng)? onLongPress;
  final bool updateMapNearEdge;
  final double nearEdgeRatio;
  final double nearEdgeSpeed;
  final bool rotateMarker;
  final bool preservePosition;
  late Anchor anchor;

  DragMarker({
    required this.point,
    this.builder,
    this.feedbackBuilder,
    this.width = 30.0,
    this.height = 30.0,
    this.offset = const Offset(0.0, 0.0),
    this.feedbackOffset = const Offset(0.0, 0.0),
    this.useLongPress = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onLongDragStart,
    this.onLongDragUpdate,
    this.onLongDragEnd,
    this.onTap,
    this.onLongPress,
    this.updateMapNearEdge = false, // experimental
    this.nearEdgeRatio = 1.5,
    this.nearEdgeSpeed = 1.0,
    this.rotateMarker = true,
    this.preservePosition = true,
    AnchorPos? anchorPos,
  }) {
    anchor = Anchor.forPos(anchorPos, width, height);
  }
}