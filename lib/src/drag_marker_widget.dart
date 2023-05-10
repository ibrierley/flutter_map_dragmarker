import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'drag_marker.dart';

class DragMarkerWidget extends StatefulWidget {
  const DragMarkerWidget({
    required super.key,
    required this.mapState,
    required this.marker,
  });

  final FlutterMapState mapState;
  final DragMarker marker;

  @override
  State<DragMarkerWidget> createState() => DragMarkerWidgetState();
}

class DragMarkerWidgetState extends State<DragMarkerWidget> {
  CustomPoint<double> pixelPosition = const CustomPoint<double>(0.0, 0.0);
  late LatLng dragPosStart;
  late LatLng markerPointStart;
  late LatLng oldDragPosition;
  late LatLng markerPoint;
  bool isDragging = false;
  Timer? autoDragTimer;

  @override
  void initState() {
    markerPoint = widget.marker.point;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final marker = widget.marker;
    _updatePixelPos(markerPoint);

    final feedbackEnabled = isDragging && marker.feedbackBuilder != null;
    final displayMarker = feedbackEnabled
        ? marker.feedbackBuilder!(context)
        : marker.builder(context);

    return GestureDetector(
      // drag detectors
      onVerticalDragStart: marker.useLongPress ? null : _onPanStart,
      onVerticalDragUpdate: marker.useLongPress ? null : _onPanUpdate,
      onVerticalDragEnd: marker.useLongPress ? null : _onPanEnd,
      onHorizontalDragStart: marker.useLongPress ? null : _onPanStart,
      onHorizontalDragUpdate: marker.useLongPress ? null : _onPanUpdate,
      onHorizontalDragEnd: marker.useLongPress ? null : _onPanEnd,
      // long press detectors
      onLongPressStart: marker.useLongPress ? _onLongPanStart : null,
      onLongPressMoveUpdate: marker.useLongPress ? onLongPanUpdate : null,
      onLongPressEnd: marker.useLongPress ? onLongPanEnd : null,
      // user callbacks
      onTap: () => marker.onTap?.call(markerPoint),
      onLongPress: () => marker.onLongPress?.call(markerPoint),
      // child widget
      /* TODO using Stack while the layer widget MarkerWidgets already
          introduces a Stack to the widget tree, try to use decrease the amount
          of Stack widgets in the future. */
      child: Stack(children: [
        Positioned(
          width: marker.width,
          height: marker.height,
          left: pixelPosition.x +
              (isDragging ? marker.feedbackOffset.dx : marker.offset.dx),
          top: pixelPosition.y +
              (isDragging ? marker.feedbackOffset.dy : marker.offset.dy),
          child: marker.rotateMarker
              ? Transform.rotate(
                  angle: -widget.mapState.rotationRad,
                  child: displayMarker,
                )
              : displayMarker,
        )
      ]),
    );
  }

  void _updatePixelPos(point) {
    final marker = widget.marker;
    final map = widget.mapState;

    var positionPoint = map.project(point);
    positionPoint =
        positionPoint.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) -
            map.pixelOrigin;

    pixelPosition = CustomPoint<double>(
      (positionPoint.x - (marker.width - widget.marker.anchor.left)).toDouble(),
      (positionPoint.y - (marker.height - widget.marker.anchor.top)).toDouble(),
    );
  }

  void _start(Offset localPosition) {
    isDragging = true;
    dragPosStart = _offsetToCrs(localPosition);
    markerPointStart = LatLng(markerPoint.latitude, markerPoint.longitude);
  }

  void _onPanStart(DragStartDetails details) {
    _start(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onDragStart != null) marker.onDragStart!(details, markerPoint);
  }

  void _onLongPanStart(LongPressStartDetails details) {
    _start(details.localPosition);
    DragMarker marker = widget.marker;
    if (marker.onLongDragStart != null) {
      marker.onLongDragStart!(details, markerPoint);
    }
  }

  void _pan(Offset localPosition) {
    final marker = widget.marker;
    final mapState = widget.mapState;

    final dragPos = _offsetToCrs(localPosition);

    final deltaLat = dragPos.latitude - dragPosStart.latitude;
    final deltaLon = dragPos.longitude - dragPosStart.longitude;

    final pixelB = mapState.getPixelBounds(mapState.zoom);
    final pixelPoint = mapState.project(markerPoint);

    // If we're near an edge, move the map to compensate.
    if (marker.updateMapNearEdge) {
      // How much we'll move the map by to compensate
      var autoOffsetX = 0.0;
      var autoOffsetY = 0.0;
      if (pixelPoint.x + marker.width * marker.nearEdgeRatio >=
          pixelB.topRight.x) {
        autoOffsetX = marker.nearEdgeSpeed;
      } else if (pixelPoint.x - marker.width * marker.nearEdgeRatio <=
          pixelB.bottomLeft.x) {
        autoOffsetX = -marker.nearEdgeSpeed;
      }
      if (pixelPoint.y - marker.height * marker.nearEdgeRatio <=
          pixelB.topRight.y) {
        autoOffsetY = -marker.nearEdgeSpeed;
      } else if (pixelPoint.y + marker.height * marker.nearEdgeRatio >=
          pixelB.bottomLeft.y) {
        autoOffsetY = marker.nearEdgeSpeed;
      }

      // Sometimes when dragging the onDragEnd doesn't fire, so just stops dead.
      // Here we allow a bit of time to keep dragging whilst user may move
      // around a bit to keep it going.
      var lastTick = 0;
      if (autoDragTimer != null) lastTick = autoDragTimer!.tick;

      if ((autoOffsetY != 0.0) || (autoOffsetX != 0.0)) {
        adjustMapToMarker(widget, autoOffsetX, autoOffsetY);

        if ((autoDragTimer == null || autoDragTimer?.isActive == false) &&
            isDragging) {
          autoDragTimer =
              Timer.periodic(const Duration(milliseconds: 10), (Timer t) {
            final tickCheck =
                autoDragTimer != null && autoDragTimer!.tick > lastTick + 15;
            if (!isDragging || tickCheck) {
              // cancel timer
              autoDragTimer?.cancel();
              autoDragTimer = null;
              return;
            }
            if (!mounted) return;
            // Note, we may have adjusted a few lines up in same drag,
            // so could test for whether we've just done that
            // this, but in reality it seems to work ok as is.
            adjustMapToMarker(widget, autoOffsetX, autoOffsetY);
          });
        }
      }
    }

    setState(() {
      markerPoint = LatLng(markerPointStart.latitude + deltaLat,
          markerPointStart.longitude + deltaLon);
      _updatePixelPos(markerPoint);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
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
    FlutterMapState? mapState = widget.mapState;

    final oldMapPos = mapState.project(mapState.center);
    final oldMarkerPoint = mapState.project(markerPoint);
    final newMapLatLng = mapState.unproject(CustomPoint(
      oldMapPos.x + autoOffsetX,
      oldMapPos.y + autoOffsetY,
    ));

    markerPoint = mapState.unproject(CustomPoint(
      oldMarkerPoint.x + autoOffsetX,
      oldMarkerPoint.y + autoOffsetY,
    ));

    mapState.move(newMapLatLng, mapState.zoom, source: MapEventSource.onDrag);
  }

  void _end() {
    isDragging = false;
    if (autoDragTimer != null) autoDragTimer?.cancel();
  }

  void _onPanEnd(details) {
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

  LatLng _offsetToCrs(Offset offset) {
    // Get the widget's offset
    final renderObject = context.findRenderObject() as RenderBox;
    final width = renderObject.size.width;
    final height = renderObject.size.height;
    final mapState = widget.mapState;

    // convert the point to global coordinates
    final localPoint = CustomPoint<double>(offset.dx, offset.dy);
    final localPointCenterDistance = CustomPoint<double>(
        (width / 2) - localPoint.x, (height / 2) - localPoint.y);
    final mapCenter = mapState.project(mapState.center);
    final point = mapCenter - localPointCenterDistance;
    return mapState.unproject(point);
  }
}
