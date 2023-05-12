import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

import 'drag_marker.dart';

class DragMarkerWidget extends StatefulWidget {
  const DragMarkerWidget({
    super.key,
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
  late LatLng _dragPosStart;
  late LatLng _markerPointStart;
  bool _isDragging = false;

  Timer? _mapScrollTimer;
  double _scrollMapX = 0;
  double _scrollMapY = 0;

  LatLng get markerPoint => widget.marker.point;

  @override
  Widget build(BuildContext context) {
    final marker = widget.marker;
    _updatePixelPos(markerPoint);

    final displayMarker = marker.builder(context, marker.point, _isDragging);

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
      /* using Stack while the layer widget MarkerWidgets already
          introduces a Stack to the widget tree, try to use decrease the amount
          of Stack widgets in the future. */
      child: Stack(children: [
        Positioned(
          width: marker.width,
          height: marker.height,
          left: pixelPosition.x +
              (_isDragging && marker.dragOffset != null
                  ? marker.dragOffset!.dx
                  : marker.offset.dx),
          top: pixelPosition.y +
              (_isDragging && marker.dragOffset != null
                  ? marker.dragOffset!.dy
                  : marker.offset.dy),
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
    _isDragging = true;
    _dragPosStart = _offsetToCrs(localPosition);
    _markerPointStart = LatLng(markerPoint.latitude, markerPoint.longitude);
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

    final deltaLat = dragPos.latitude - _dragPosStart.latitude;
    final deltaLon = dragPos.longitude - _dragPosStart.longitude;

    // If we're near an edge, move the map to compensate.
    if (marker.scrollMapNearEdge) {
      final pixelB = mapState.getPixelBounds(mapState.zoom);
      final pixelPoint = mapState.project(markerPoint);
      // How much we'll move the map by to compensate
      var scrollMapX = 0.0;
      if (pixelPoint.x + marker.width * marker.scrollNearEdgeRatio >=
          pixelB.topRight.x) {
        scrollMapX = marker.scrollNearEdgeSpeed;
      } else if (pixelPoint.x - marker.width * marker.scrollNearEdgeRatio <=
          pixelB.bottomLeft.x) {
        scrollMapX = -marker.scrollNearEdgeSpeed;
      }
      var scrollMapY = 0.0;
      if (pixelPoint.y - marker.height * marker.scrollNearEdgeRatio <=
          pixelB.topRight.y) {
        scrollMapY = -marker.scrollNearEdgeSpeed;
      } else if (pixelPoint.y + marker.height * marker.scrollNearEdgeRatio >=
          pixelB.bottomLeft.y) {
        scrollMapY = marker.scrollNearEdgeSpeed;
      }

      _scrollMapX = scrollMapX;
      _scrollMapY = scrollMapY;
      if (_scrollMapX == 0.0 && _scrollMapY == 0.0) {
        _mapScrollTimer?.cancel();
        _mapScrollTimer = null;
      } else {
        _mapScrollTimer ??= Timer.periodic(
          const Duration(milliseconds: 10),
          _mapScrollTimerCallback,
        );
      }
    }

    setState(() {
      widget.marker.point = LatLng(_markerPointStart.latitude + deltaLat,
          _markerPointStart.longitude + deltaLon);
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
  void _mapScrollTimerCallback(Timer _) {
    if (!_isDragging) {
      _mapScrollTimer?.cancel();
      _mapScrollTimer = null;
      return;
    }

    final mapState = widget.mapState;
    final oldMapPos = mapState.project(mapState.center);
    final oldMarkerPoint = mapState.project(markerPoint);
    final newMapLatLng = mapState.unproject(CustomPoint(
      oldMapPos.x + _scrollMapX,
      oldMapPos.y + _scrollMapY,
    ));

    widget.marker.point = mapState.unproject(CustomPoint(
      oldMarkerPoint.x + _scrollMapX,
      oldMarkerPoint.y + _scrollMapY,
    ));

    mapState.move(newMapLatLng, mapState.zoom, source: MapEventSource.onDrag);
  }

  void _onPanEnd(details) {
    _isDragging = false;
    if (widget.marker.onDragEnd != null) {
      widget.marker.onDragEnd!(details, markerPoint);
    }
    setState(() {}); // Needed if using a feedback widget
  }

  void onLongPanEnd(details) {
    _isDragging = false;
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
