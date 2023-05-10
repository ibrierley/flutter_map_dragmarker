# flutter_map_dragmarker

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F1F8E2YBE)

A drag marker for [flutter_map](https://github.com/fleaflet/flutter_map/).

See the [example/lib/main.dart](example/lib/main.dart) for usage, but the
included example below in this file should show pretty much everything.

Note: This layer should probably be the last layer IF it needs to be dragged (
otherwise why would you use this :)), otherwise other layers may intercept the
gestures.

Most options should be self-explanatory. Offsets are just there for tweaking
icon/images if they aren't centered, it may need a further tweak in code if
there are some oddities like changing the bounds.

```dart
  FlutterMap(
    options: MapOptions(
      center: LatLng(45.5231, -122.6765),
      zoom: 9,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      DragMarkers(
        markers: [
          DragMarker(
            point: LatLng(45.535, -122.675),
            offset: const Offset(0.0, -8.0),
            builder: (ctx) => const Icon(Icons.location_on, size: 50),
            onDragUpdate: (details, latLng) => print(latLng),
          ),
        ],
      ),
    ],
  ),
```

`feedbackBuilder` and `feedbackOffset` are for a replacement widget/effect when
actually dragging.

`height` is mainly for `Images`, use `size` for `Icons`, but be aware internal
calculations are based on size.

`rotateMarker` decides whether to rotate in the opposite direction to the map
rotation, keeping markers upright.

Experimental automatically scroll the map when near the edge is implemented (
optional), but if anyone wants to improve it, pull requests welcome!

It may be interesting to move the map alternately to marker, too. So the marker
stays in place, but then technically you aren't dragging anymore, so thoughts 
welcome.
