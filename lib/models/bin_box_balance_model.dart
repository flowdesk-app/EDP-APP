class BinBoxBalance {
  final String destinationName;
  final int totalSentBins;
  final int totalSentBoxes;
  final int totalReturnedBins;
  final int totalReturnedBoxes;
  final int netBins;
  final int netBoxes;

  BinBoxBalance({
    required this.destinationName,
    required this.totalSentBins,
    required this.totalSentBoxes,
    required this.totalReturnedBins,
    required this.totalReturnedBoxes,
    required this.netBins,
    required this.netBoxes,
  });

  factory BinBoxBalance.fromJson(Map<String, dynamic> json) {
    return BinBoxBalance(
      destinationName: json['destinationName'] ?? '',
      totalSentBins: json['totalSentBins'] ?? 0,
      totalSentBoxes: json['totalSentBoxes'] ?? 0,
      totalReturnedBins: json['totalReturnedBins'] ?? 0,
      totalReturnedBoxes: json['totalReturnedBoxes'] ?? 0,
      netBins: json['netBins'] ?? 0,
      netBoxes: json['netBoxes'] ?? 0,
    );
  }
}
