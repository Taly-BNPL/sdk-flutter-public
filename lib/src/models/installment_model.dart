class InstallmentModel {
  final double amount;
  final String currency;
  final String dueDate;
  final String dueDateDesc;
  final int nbOfInstallment;
  final String noOfInstallmentDesc;
  final String status;
  final double finalAmount;

  const InstallmentModel({
    required this.amount,
    required this.currency,
    required this.dueDate,
    required this.dueDateDesc,
    required this.nbOfInstallment,
    required this.noOfInstallmentDesc,
    required this.status,
    required this.finalAmount,
  });

  factory InstallmentModel.fromMap(Map<Object?, Object?> m) {
    return InstallmentModel(
      amount: (m['amount'] as num).toDouble(),
      currency: m['currency'] as String,
      dueDate: m['dueDate'] as String,
      dueDateDesc: m['dueDateDesc'] as String? ?? '',
      nbOfInstallment: m['nbOfInstallment'] as int,
      noOfInstallmentDesc: m['noOfInstallmentDesc'] as String? ?? '',
      status: m['status'] as String,
      finalAmount: (m['finalAmount'] as num).toDouble(),
    );
  }
}
