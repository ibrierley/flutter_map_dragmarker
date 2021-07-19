import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';

class DragMarkerPluginOptions extends LayerOptions {
  List<DragMarker> markers;
  DragMarkerPluginOptions({this.markers});
}

class DragMarkerPlugin implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is DragMarkerPluginOptions) {
      return StreamBuilder<int>(
          stream: stream,
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            var dragMarkers = <Widget>[];
            for (var marker in options.markers) {
              if (!_boundsContainsMarker(mapState, marker)) continue;

              dragMarkers.add(DragMarkerWidget(
                  mapState: mapState,
                  marker: marker,
                  stream: stream,
                  options: options));
            }
            return Container(
              child: Stack(children: dragMarkers),
            );
          });
    }

    throw Exception('Unknown options type for MyCustom'
        'plugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is DragMarkerPluginOptions;
  }

  static bool _boundsContainsMarker(MapState map, DragMarker marker) {
    var pixelPoint = map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);

    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }
}

class DragMarkerWidget extends StatefulWidget {
  DragMarkerWidget(
      {this.mapState,
      this.marker,
      AnchorPos anchorPos,
      this.stream,
      this.options}); //: anchor = Anchor.forPos(anchorPos, marker.width, marker.height);

  final MapState mapState;
  //final Anchor anchor;
  final DragMarker marker;
  final Stream<Null> stream;
  final LayerOptions options;

  @override
  _DragMarkerWidgetState createState() => _DragMarkerWidgetState();
}

class _DragMarkerWidgetState extends State<DragMarkerWidget> {
  CustomPoint pixelPosition;
  LatLng dragPosStart;
  LatLng markerPointStart;
  LatLng oldDragPosition;
  bool isDragging = false;

  static Timer autoDragTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DragMarker marker = widget.marker;
    updatePixelPos(widget.marker.point);

    return GestureDetector(
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onTap: () {
        if (marker.onTap != null) marker.onTap(marker.point);
      },
      onLongPress: () {
        if (marker.onLongPress != null) marker.onLongPress(marker.point);
      },
      child: Stack(children: [
        Positioned(
          width: marker.width,
          height: marker.height,
          left: pixelPosition.x +
              ((isDragging && (marker.feedbackOffset != null))
                  ? marker.feedbackOffset.dx
                  : marker.offset.dx),
          top: pixelPosition.y +
              ((isDragging && (marker.feedbackOffset != null))
                  ? marker.feedbackOffset.dy
                  : marker.offset.dy),
          child: (isDragging && (marker.feedbackBuilder != null))
              ? marker.feedbackBuilder(context)
              : marker.builder(context),
        ),
      ]),
    );
  }

  void updatePixelPos(point) {
    DragMarker marker = widget.marker;
    MapState mapState = widget.mapState;

    var pos = mapState.project(point);
    pos = pos.multiplyBy(mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
        mapState.getPixelOrigin();

    pixelPosition = CustomPoint(
        (pos.x - (marker.width - widget.marker.anchor.left)).toDouble(),
        (pos.y - (marker.height - widget.marker.anchor.top)).toDouble());
  }

  void onPanStart(details) {
    isDragging = true;
    dragPosStart = _offsetToCrs(details.localPosition);
    markerPointStart =
        LatLng(widget.marker.point.latitude, widget.marker.point.longitude);

    if (widget.marker.onDragStart != null)
      widget.marker.onDragStart(details, widget.marker.point);
  }

  void onPanUpdate(DragUpdateDetails details) {
    bool isDragging = true;
    DragMarker marker = widget.marker;
    MapState mapState = widget.mapState;

    var dragPos = _offsetToCrs(details.localPosition);

    var deltaLat = dragPos.latitude - dragPosStart.latitude;
    var deltaLon = dragPos.longitude - dragPosStart.longitude;

    var pixelB = mapState.getLastPixelBounds();
    var pixelPoint = mapState.project(widget.marker.point);

    /// If we're near an edge, move the map to compensate.

    if (marker.updateMapNearEdge != null && marker.updateMapNearEdge) {
      /// How much we'll move the map by to compensate

      var autoOffsetX = 0.0;
      var autoOffsetY = 0.0;

      if (pixelPoint.x + marker.width * marker.nearEdgeRatio >=
          pixelB.topRight.x) autoOffsetX = marker.nearEdgeSpeed;
      if (pixelPoint.x - marker.width * marker.nearEdgeRatio <=
          pixelB.bottomLeft.x) autoOffsetX = -marker.nearEdgeSpeed;
      if (pixelPoint.y - marker.height * marker.nearEdgeRatio <=
          pixelB.topRight.y) autoOffsetY = -marker.nearEdgeSpeed;
      if (pixelPoint.y + marker.height * marker.nearEdgeRatio >=
          pixelB.bottomLeft.y) autoOffsetY = marker.nearEdgeSpeed;

      /// Sometimes when dragging the onDragEnd doesn't fire, so just stops dead.
      /// Here we allow a bit of time to keep dragging whilst user may move
      /// around a bit to keep it going.

      var lastTick = 0;
      if (autoDragTimer != null) lastTick = autoDragTimer.tick;

      if ((autoOffsetY != 0.0) || (autoOffsetX != 0.0)) {
        adjustMapToMarker(widget, autoOffsetX, autoOffsetY);

        if ((autoDragTimer == null || autoDragTimer.isActive == false) &&
            (isDragging == true)) {
          autoDragTimer =
              Timer.periodic(const Duration(milliseconds: 10), (Timer t) {
            if (isDragging == false || (autoDragTimer.tick > lastTick + 15)) {
              autoDragTimer.cancel();
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
      marker.point = LatLng(markerPointStart.latitude + deltaLat,
          markerPointStart.longitude + deltaLon);
      updatePixelPos(marker.point);
    });

    if (marker.onDragUpdate != null) marker.onDragUpdate(details, marker.point);
  }

  /// If dragging near edge of the screen, adjust the map so we keep dragging

  void adjustMapToMarker(DragMarkerWidget widget, autoOffsetX, autoOffsetY) {
    DragMarker marker = widget.marker;
    MapState mapState = widget.mapState;

    var oldMapPos = mapState.project(mapState.center);
    var newMapLatLng = mapState.unproject(
        CustomPoint(oldMapPos.x + autoOffsetX, oldMapPos.y + autoOffsetY));
    var oldMarkerPoint = mapState.project(marker.point);

    marker.point = mapState.unproject(CustomPoint(
        oldMarkerPoint.x + autoOffsetX, oldMarkerPoint.y + autoOffsetY));
    mapState.move(newMapLatLng, mapState.zoom);
  }

  void onPanEnd(details) {
    isDragging = false;
    if (autoDragTimer != null) autoDragTimer.cancel();
    if (widget.marker.onDragEnd != null)
      widget.marker.onDragEnd(details, widget.marker.point);
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

    // convert the point to global coordinates
    var localPoint = _offsetToPoint(offset);
    var localPointCenterDistance =
        CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    var mapCenter = widget.mapState.project(widget.mapState.center);
    var point = mapCenter - localPointCenterDistance;
    return widget.mapState.unproject(point);
  }
}

class DragMarker {
  LatLng point;
  final WidgetBuilder builder;
  final WidgetBuilder feedbackBuilder;
  final double width;
  final double height;
  final Offset offset;
  final Offset feedbackOffset;
  final Function(DragStartDetails, LatLng) onDragStart;
  final Function(DragUpdateDetails, LatLng) onDragUpdate;
  final Function(DragEndDetails, LatLng) onDragEnd;
  final Function(LatLng) onTap;
  final Function(LatLng) onLongPress;
  final bool updateMapNearEdge;
  final double nearEdgeRatio;
  final double nearEdgeSpeed;
  Anchor anchor;

  DragMarker({
    this.point,
    this.builder,
    this.feedbackBuilder,
    this.width = 30.0,
    this.height = 30.0,
    this.offset = const Offset(0.0, 0.0),
    this.feedbackOffset = const Offset(0.0, 0.0),
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
    this.updateMapNearEdge = false, // experimental
    this.nearEdgeRatio = 1.5,
    this.nearEdgeSpeed = 1.0,
    AnchorPos anchorPos,
  }) {
    anchor = Anchor.forPos(anchorPos, width, height);
  }
}
