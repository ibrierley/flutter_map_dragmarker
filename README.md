# flutter_map_dragmarker

A drag marker for [flutter_map](https://github.com/fleaflet/flutter_map/).

See the [example/lib/main.dart](example/lib/main.dart) for usage, but the
included example below in this file should show pretty much everything.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F1F8E2YBE)

## Usage

- This layer should probably be the last layer so IF it needs to be dragged
  (otherwise why would you use this :)). If not, other layers may intercept
  the gestures.
- `offset` and `dragOffset` are there for tweaking icon/images if they should 
  not get displayed centered.
- `height` is mainly for `Images`, use `Icon(..., size: ...)`, but be aware 
  internal calculations are based on size.
- `rotateMarker` toggles the markers' rotation on and off. True keeping markers 
  upright.
- Use `scrollMapNearEdge` if the map should scroll when a marker is dragged 
  near the edge.
- Enable `useLongPress` if you want to enable dragging after a long press

```dart
  FlutterMap(
    options: MapOptions(center: LatLng(45.5231, -122.6765), zoom: 9),
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

## Further notes
It may be interesting to move the map alternately to marker, too. So the marker
stays in place, but then technically you aren't dragging anymore, so thoughts
welcome.
