class Schedule {
  final int? id;
  final String courseName;
  final String lecturer;
  final String room;
  final String day;
  final String startTime;
  final String endTime;

  Schedule({
    this.id,
    required this.courseName,
    required this.lecturer,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_name': courseName,
      'lecturer': lecturer,
      'room': room,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      courseName: map['course_name'],
      lecturer: map['lecturer'],
      room: map['room'],
      day: map['day'],
      startTime: map['start_time'],
      endTime: map['end_time'],
    );
  }
}
