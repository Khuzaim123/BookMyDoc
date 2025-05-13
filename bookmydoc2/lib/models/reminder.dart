class Reminder {
  final String id;
  final String patientId;
  final String task;
  final DateTime time;

  Reminder({
    required this.id,
    required this.patientId,
    required this.task,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'task': task,
    'time': time.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    patientId: json['patientId'] as String,
    task: json['task'] as String,
    time: DateTime.parse(json['time'] as String),
  );
}