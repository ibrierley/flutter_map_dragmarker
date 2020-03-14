# flutter_map_dragmarker
A drag marker for flutter_map

See the main.dart file for example use.

May want future things adding like automoving the map when dragging close to the edge of the screen.

Add the `DragMarkerPlugin(),` to the plugins list, and then reference `DragMarkerPluginOptions` in your flutter_map layers.

Most options should be self-explanatory. Offsets are just there for tweaking icon/images if they aren't centered, it may need a further tweak in code if there are some oddities like changing the bounds.

feedbackBuilder and feedbackOffset are for a replacement widget/effect when actually dragging.

height is mainly for Images, use size for Icons, but be aware internal calculations are based on size.

```

FlutterMap(
  options: MapOptions(
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
	    ),
	    DragMarker(
	      point: LatLng(45.535, -122.675),
	      width: 80.0,
	      height: 80.0,
	      builder: (ctx) => Container( child: Icon(Icons.location_on, size: 50) ),
	      onDragEnd: (details,point) { print('Finished Drag $details $point'); },
	    )
      ],
    ),
  ],
),

```
