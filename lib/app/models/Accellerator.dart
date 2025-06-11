class Accellerator {
  double? x;
  double? y;
  double? z;
  DateTime? timestamp;

  Accellerator({
    this.x,
    this.y,
    this.z,
    this.timestamp,
  });
  factory Accellerator.fromMap(Map<String, dynamic> map) {
    return Accellerator(
      x: map['x'],
      y: map['y'],
      z: map['z'],
      timestamp: map['timestamp'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'timestamp': timestamp,
    };
  }
}
