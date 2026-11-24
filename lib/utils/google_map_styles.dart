import 'package:flutter/material.dart';

class GoogleMapStyles {
  static String forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static const light = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f1f7f3"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#536b5c"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#e1f0e6"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#cfe2d5"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#e1f0e6"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#d5ebdb"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#cde8ed"}]}
]
''';

  static const dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#151c17"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a0b2a5"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#090d0b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#344036"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#405044"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#50634e"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#202a23"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#20392b"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#122a2a"}]}
]
''';
}
