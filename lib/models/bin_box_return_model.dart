class BinBoxReturn {
  final String id;
  final String destinationName;
  final int returnedBins;
  final int returnedBoxes;
  final DateTime date;

  BinBoxReturn({
    required this.id,
    required this.destinationName,
    required this.returnedBins,
    required this.returnedBoxes,
    required this.date,
  });

  factory BinBoxReturn.fromJson(Map<String, dynamic> json) {
    return BinBoxReturn(
      id: json['_id'] ?? '',
      destinationName: json['destinationName'] ?? '',
      returnedBins: json['returnedBins'] ?? 0,
      returnedBoxes: json['returnedBoxes'] ?? 0,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
