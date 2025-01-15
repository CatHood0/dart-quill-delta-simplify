import 'package:meta/meta.dart';

@internal
extension NumExt on num {
  @internal
  int get nonNegativeInt {
    return this < 0 ? 0 : toInt();
  }

  @internal
  double get nonNegativeDouble {
    return this < 0.0 ? 0.0 : toDouble();
  }
}
