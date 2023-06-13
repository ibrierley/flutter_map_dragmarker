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
  var pixelPosition = const CustomPoint<double>(0, 0);
  late LatLng _dragPosStart;
  late LatLng _markerPointStart;
  bool _isDragging = false;

  /// this marker scrolls the map if [marker.scrollMapNearEdge] is set to true
  /// and gets dragged near to an edge. It needs to be static because only one
  static Timer? _mapScrollTimer;

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
      onLongPressMoveUpdate: marker.useLongPress ? _onLongPanUpdate : null,
      onLongPressEnd: marker.useLongPress ? _onLongPanEnd : null,
      // user callbacks
      onTap: () => marker.onTap?.call(markerPoint),
      onLongPress: () => marker.onLongPress?.call(markerPoint),
      // child widget
      /* using Stack while the layer widget MarkerWidgets already
          introduces a Stack to the widget tree, try to use decrease the amount
          of Stack widgets in the future. */
      child: Stack(children: [
        Positioned(
          width: marker.size.width,
          height: marker.size.height,
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
        (positionPoint * map.getZoomScale(map.zoom, map.zoom)) -
            map.pixelOrigin;

    pixelPosition = CustomPoint<double>(
      (positionPoint.x - (marker.size.width - marker.anchor.left)).toDouble(),
      (positionPoint.y - (marker.size.height - marker.anchor.top)).toDouble(),
    );
  }

  void _start(Offset localPosition) {
    _isDragging = true;
    _dragPosStart = _offsetToCrs(localPosition);
    _markerPointStart = LatLng(markerPoint.latitude, markerPoint.longitude);
  }

  void _onPanStart(DragStartDetails details) {
    _start(details.localPosition);
    widget.marker.onDragStart?.call(details, markerPoint);
  }

  void _onLongPanStart(LongPressStartDetails details) {
    _start(details.localPosition);
    widget.marker.onLongDragStart?.call(details, markerPoint);
  }

  void _pan(Offset localPosition) {
    final dragPos = _offsetToCrs(localPosition);

    if (widget.mapState.isOutOfBounds(dragPos)) {
      // cancels the dragging, needed when the app runs in a window and the
      // cursor leaves the map while dragging. The on pan end event fails to
      // fire when doing a quick movement
      _end();
      return;
    }

    final deltaLat = dragPos.latitude - _dragPosStart.latitude;
    final deltaLon = dragPos.longitude - _dragPosStart.longitude;

    // If we're near an edge, move the map to compensate
    if (widget.marker.scrollMapNearEdge) {
      final scrollOffset = _getMapScrollOffset();
      // start the scroll timer if scrollOffset is not zero
      if (scrollOffset != Offset.zero) {
        _mapScrollTimer ??= Timer.periodic(
          const Duration(milliseconds: 10),
          _mapScrollTimerCallback,
        );
      }
    }

    setState(() {
      widget.marker.point = LatLng(
        _markerPointStart.latitude + deltaLat,
        _markerPointStart.longitude + deltaLon,
      );
      _updatePixelPos(markerPoint);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _pan(details.localPosition);
    widget.marker.onDragUpdate?.call(details, markerPoint);
  }

  void _onLongPanUpdate(LongPressMoveUpdateDetails details) {
    _pan(details.localPosition);
    widget.marker.onLongDragUpdate?.call(details, markerPoint);
  }

  void _onPanEnd(details) {
    _end();
    widget.marker.onDragEnd?.call(details, markerPoint);
  }

  void _onLongPanEnd(details) {
    _end();
    widget.marker.onLongDragEnd?.call(details, markerPoint);
  }

  void _end() {
    // setState is needed if using a different widget while dragging
    setState(() {
      _isDragging = false;
    });
  }

  /// If dragging near edge of the screen, adjust the map so we keep dragging
  void _mapScrollTimerCallback(Timer timer) {
    final mapState = widget.mapState;
    final scrollOffset = _getMapScrollOffset();

    // cancel conditions
    if (!_isDragging ||
        timer != _mapScrollTimer ||
        scrollOffset == Offset.zero ||
        !widget.marker.inMapBounds(mapState)) {
      timer.cancel();
      _mapScrollTimer = null;
      return;
    }

    // update marker position
    final oldMarkerPoint = mapState.project(markerPoint);
    widget.marker.point = mapState.unproject(CustomPoint(
      oldMarkerPoint.x + scrollOffset.dx,
      oldMarkerPoint.y + scrollOffset.dy,
    ));

    // scroll map
    final oldMapPos = mapState.project(mapState.center);
    final newMapLatLng = mapState.unproject(CustomPoint(
      oldMapPos.x + scrollOffset.dx,
      oldMapPos.y + scrollOffset.dy,
    ));
    mapState.move(newMapLatLng, mapState.zoom, source: MapEventSource.onDrag);
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

  /// this method is used for [marker.scrollMapNearEdge]. It checks if the
  /// marker is near an edge and returns the offset that the map should get
  /// scrolled.
  Offset _getMapScrollOffset() {
    final marker = widget.marker;
    final mapState = widget.mapState;

    final pixelB = mapState.getPixelBounds(mapState.zoom);
    final pixelPoint = mapState.project(markerPoint);
    // How much we'll move the map by to compensate
    var scrollMapX = 0.0;
    if (pixelPoint.x + marker.size.width * marker.scrollNearEdgeRatio >=
        pixelB.topRight.x) {
      scrollMapX = marker.scrollNearEdgeSpeed;
    } else if (pixelPoint.x - marker.size.width * marker.scrollNearEdgeRatio <=
        pixelB.bottomLeft.x) {
      scrollMapX = -marker.scrollNearEdgeSpeed;
    }
    var scrollMapY = 0.0;
    if (pixelPoint.y - marker.size.height * marker.scrollNearEdgeRatio <=
        pixelB.topRight.y) {
      scrollMapY = -marker.scrollNearEdgeSpeed;
    } else if (pixelPoint.y + marker.size.height * marker.scrollNearEdgeRatio >=
        pixelB.bottomLeft.y) {
      scrollMapY = marker.scrollNearEdgeSpeed;
    }
    return Offset(scrollMapX, scrollMapY);
  }
}
