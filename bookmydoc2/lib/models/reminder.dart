class Reminder {
  final String id;
  final String userid;
  final String task;
  final DateTime time;

  Reminder({
    required this.id,
    required this.userid,
    required this.task,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userid': userid,
    'task': task,
    'time': time.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    userid: json['patientId'] as String,
    task: json['task'] as String,
    time: DateTime.parse(json['time'] as String),
  );
}