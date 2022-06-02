# flutter_map_dragmarker
A drag marker for flutter_map

See the main.dart file for example use, but the example below should show pretty much everything.

If using flutter_map 0.14.0+ then you probably need allowPanningOnScrollingParent: false, in MapOptions

Note: This layer should probably be the last layer IF it needs to be dragged (otherwise why would you use this :)), otherwise other layers may intercept the gestures.

Add the `DragMarkerPlugin(),` to the plugins list, and then reference `DragMarkerPluginOptions` in your flutter_map layers.

Most options should be self-explanatory. Offsets are just there for tweaking icon/images if they aren't centered, it may need a further tweak in code if there are some oddities like changing the bounds.

feedbackBuilder and feedbackOffset are for a replacement widget/effect when actually dragging.

height is mainly for Images, use size for Icons, but be aware internal calculations are based on size.

rotateMarker decides whether to rotate in the opposite direction to the map rotation, keeping markers upright.

Experimental automoving the map when near the edge is implemented (optional), but if anyone wants to improve it, pull requests welcome!

Also may be interesting to move the map alternately to marker, so the marker stays in place, but then technically you aren't
dragging any more, so thoughts welcome.


```dart

FlutterMap(
  options: MapOptions(
    allowPanningOnScrollingParent: false, /// IMPORTANT for dragging
    plugins: [
      DragMarkerPlugin(),
    ],
    center: LatLng(45.5231, -122.6765),
    zoom: 6.4,
  ),
  layers: [
    TileLayerOptions(
        urlTemplate:
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: ['a', 'b', 'c']),
        DragMarkerPluginOptions(
          markers: [
            DragMarker(
              point: LatLng(45.2131, -122.6765),
              width: 80.0,
              height: 80.0,
              offset: Offset(0.0, -8.0),
              builder: (ctx) => Container( child: Icon(Icons.location_on, size: 50) ),
              onDragStart:  (details,point) => print("Start point $point"),
              onDragEnd:    (details,point) => print("End point $point"),
              onDragUpdate: (details,point) {},
              onTap:        (point) { print("on tap"); },
              onLongPress:  (point) { print("on long press"); },
              feedbackBuilder: (ctx) => Container( child: Icon(Icons.edit_location, size: 75) ),
              feedbackOffset: Offset(0.0, -18.0),
              updateMapNearEdge: true,	// Experimental, move the map when marker close to edge
              nearEdgeRatio: 2.0,	// Experimental
              nearEdgeSpeed: 1.0,	// Experimental
              rotateMarker: true,   // Experimental
            ),
            DragMarker(
              point: LatLng(45.535, -122.675),
              width: 80.0,
              height: 80.0,
              builder: (ctx) => Container( child: Icon(Icons.location_on, size: 50) ),
              onDragEnd: (details,point) { print('Finished Drag $details $point'); },
              updateMapNearEdge: false,
              rotateMarker: true,
            )
          ],
      ),
  ],
),

```
