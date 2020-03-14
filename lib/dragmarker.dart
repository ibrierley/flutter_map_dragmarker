import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
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
            for( var marker in options.markers ) {

              if(!_boundsContainsMarker(mapState, marker)) continue;

              dragMarkers.add(
                  DragMarkerWidget(mapState: mapState, marker: marker, stream: stream)
              );
            }
            return Container(
              child: Stack(children: dragMarkers),
            );
          }
      );
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

    final width  = marker.width  - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y - height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);

    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }
}


class DragMarkerWidget extends StatefulWidget {

  DragMarkerWidget({this.mapState, this.marker, AnchorPos anchorPos, this.stream }) : anchor = Anchor.forPos(anchorPos, marker.width, marker.height);

  final MapState mapState;
  final Anchor anchor;
  final DragMarker marker;
  final Stream<Null> stream;

  @override
  _DragMarkerWidgetState createState() => _DragMarkerWidgetState();

}

class _DragMarkerWidgetState extends State<DragMarkerWidget> {

  double pixelPosX;
  double pixelPosY;
  LatLng dragPosStart;
  LatLng myPointStart;
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    updatePixelPos(widget.marker.point);

    return GestureDetector(
      onPanStart:  onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd:    onPanEnd,
      onTap:       () { if (widget.marker.onTap != null )
        widget.marker.onTap(widget.marker.point); },
      onLongPress: () { if (widget.marker.onLongPress != null)
        widget.marker.onLongPress(widget.marker.point); },

      child: Stack(children: [
        Positioned(
          width: widget.marker.width,
          height: widget.marker.height,
          left: pixelPosX + ((isDragging && (widget.marker.feedbackOffset != null)) ?
          widget.marker.feedbackOffset.dx : widget.marker.offset.dx),
          top:  pixelPosY + ((isDragging && (widget.marker.feedbackOffset != null)) ?
          widget.marker.feedbackOffset.dy : widget.marker.offset.dy),
          child: (isDragging && (widget.marker.feedbackBuilder != null)) ?
          widget.marker.feedbackBuilder(context) : widget.marker.builder(context),
        ),
      ]),
    );

  }

  void updatePixelPos(point) {
    var pos = widget.mapState.project(point);
    pos = pos.multiplyBy(widget.mapState.getZoomScale(widget.mapState.zoom, widget.mapState.zoom)) -
        widget.mapState.getPixelOrigin();

    pixelPosX = (pos.x - (widget.marker.width - widget.anchor.left)).toDouble();
    pixelPosY = (pos.y - (widget.marker.height - widget.anchor.top)).toDouble();
  }


  void onPanStart(details) {
    isDragging = true;
    dragPosStart = _offsetToCrs(details.localPosition);
    myPointStart = LatLng( widget.marker.point.latitude, widget.marker.point.longitude);

    if( widget.marker.onDragStart != null ) widget.marker.onDragStart(details,widget.marker.point);
  }

  void onPanUpdate(details) {
    isDragging = true;
    var dragPos = _offsetToCrs(details.localPosition);

    var deltaLat = dragPos.latitude  - dragPosStart.latitude;
    var deltaLon = dragPos.longitude - dragPosStart.longitude;

    setState(() {
      widget.marker.point = LatLng(myPointStart.latitude + deltaLat, myPointStart.longitude + deltaLon);
      updatePixelPos(widget.marker.point);
    });

    if( widget.marker.onDragUpdate != null ) widget.marker.onDragUpdate(details,widget.marker.point);

  }

  void onPanEnd(details) {
    isDragging = false;
    if( widget.marker.onDragEnd != null ) widget.marker.onDragEnd(details,widget.marker.point);
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
  final Anchor anchor;
  final Function(DragStartDetails,LatLng) onDragStart;
  final Function(DragUpdateDetails,LatLng) onDragUpdate;
  final Function(DragEndDetails,LatLng) onDragEnd;
  final Function(LatLng) onTap;
  final Function(LatLng) onLongPress;

  DragMarker({
    this.point,
    this.builder,
    this.feedbackBuilder,
    this.width = 30.0,
    this.height = 30.0,
    this.offset = const Offset(0.0,0.0),
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onTap,
    this.onLongPress,
    this.feedbackOffset,
    AnchorPos anchorPos,
  }) : anchor = Anchor.forPos(anchorPos, width, height);
}