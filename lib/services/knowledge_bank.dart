class KnowledgeEntry {
  final List<String> keywords;
  final String answer;
  final String category;
  final String? nodeId;

  const KnowledgeEntry({
    required this.keywords,
    required this.answer,
    required this.category,
    this.nodeId,
  });
}

class KnowledgeBank {
  static final KnowledgeBank _instance = KnowledgeBank._internal();
  factory KnowledgeBank() => _instance;
  KnowledgeBank._internal();

  static const List<KnowledgeEntry> entries = [
    // ── Academic Affairs / Registration ──
    KnowledgeEntry(
      category: 'Academic Affairs',
      keywords: [
        'register courses', 'course registration', 'register for classes',
        'how to register', 'enrol', 'enrolment', 'enrollment',
        'deregister', 'de-register', 'drop course', 'add course',
        'academic affairs', 'registration portal', 'sign up for courses',
        'register my classes', 'where to register', 'who handles registration',
      ],
      answer:
          'Academic Affairs handles all student registrations and de-registrations. '
          'Visit the Academic Affairs office on the ground floor of the Senate Building, '
          'or use the student portal online. Registration opens at the start of each semester.',
      nodeId: 'hall',
    ),

    // ── Fees / Bursary ──
    KnowledgeEntry(
      category: 'Bursary',
      keywords: [
        'pay fees', 'school fees', 'tuition', 'how much are fees',
        'fee payment', 'bursary', 'pay tuition', 'acceptance fee',
        'late registration fee', 'penalty fee', 'pay my school fees',
        'where to pay fees', 'fee schedule', 'how to pay fees',
      ],
      answer:
          'The Bursary Department handles all fee payments and financial transactions. '
          'You can pay fees at any designated bank branch or through the online payment portal. '
          'The Bursary is located in the Senate Building, first floor. Always keep your payment receipt.',
      nodeId: 'hall',
    ),

    // ── Admissions ──
    KnowledgeEntry(
      category: 'Admissions',
      keywords: [
        'admission', 'admissions', 'admission letter', 'admission status',
        'check admission', 'have i been admitted', 'accept admission',
        'admission list', 'post utme', 'post-utme', 'screening',
        'admission requirements', 'new student', 'fresher', 'freshers',
      ],
      answer:
          'The Admissions Office processes all new student admissions. '
          'Check your admission status on the university portal or JAMB CAPS. '
          'The Admissions Office is located in the Administrative Block, ground floor. '
          'Bring your original credentials for physical screening.',
      nodeId: 'hall',
    ),

    // ── Student Affairs / ID Cards ──
    KnowledgeEntry(
      category: 'Student Affairs',
      keywords: [
        'student id', 'id card', 'identity card', 'student identity',
        'replace id card', 'lost id card', 'get my id', 'student card',
        'school id', 'university id', 'identification card',
        'student affairs', 'dean of students',
      ],
      answer:
          'Student Affairs issues and replaces all student ID cards. '
          'Visit the Student Affairs office in the Administrative Block, first floor. '
          'You will need a passport photograph, your admission letter, and a police report if replacing a lost card.',
      nodeId: 'hall',
    ),

    // ── Exams & Records ──
    KnowledgeEntry(
      category: 'Exams & Records',
      keywords: [
        'exam timetable', 'exam schedule', 'when are exams',
        'transcript', 'academic transcript', 'get my transcript',
        'result', 'check result', 'semester result', 'gpa',
        'statement of result', 'exam venue', 'examination',
        'records office', 'exam officer',
      ],
      answer:
          'The Exams and Records Office manages all examination timetables, results, and transcripts. '
          'Check the department notice board or student portal for your exam schedule. '
          'For transcripts, apply at the Exams and Records office in the Senate Building, '
          'second floor. Transcript requests typically take 2-4 weeks to process.',
      nodeId: 'hall',
    ),

    // ── Library ──
    KnowledgeEntry(
      category: 'Library',
      keywords: [
        'library', 'borrow books', 'library card', 'library hours',
        'study space', 'reading room', 'e-library', 'digital library',
        'library registration', 'reference section', 'return book',
        'where is the library', 'main library',
      ],
      answer:
          'The Main University Library is open Monday to Saturday, 8 AM to 10 PM. '
          'Register at the circulation desk with your student ID to get a library card. '
          'The e-library section on the ground floor provides computers and online journal access. '
          'Group study rooms can be booked at the front desk.',
      nodeId: 'lib',
    ),

    // ── Hostel / Accommodation ──
    KnowledgeEntry(
      category: 'Hostel',
      keywords: [
        'hostel', 'accommodation', 'hall of residence', 'dorm',
        'where to stay', 'apply for hostel', 'hostel allocation',
        'bed space', 'hostel fees', 'move in', 'off campus accommodation',
        'on campus housing', 'where do i live',
      ],
      answer:
          'The Student Affairs office manages hostel allocations. '
          'Apply for accommodation through the student portal at the start of each session. '
          'Hall of residence options include Moremi Hall, Jaja Hall, and Biobaku Hall. '
          'Spaces are limited and allocated on a first-come, first-served basis.',
      nodeId: 'hall',
    ),

    // ── Medical / Health Centre ──
    KnowledgeEntry(
      category: 'Health Centre',
      keywords: [
        'sick', 'medical', 'health centre', 'clinic', 'hospital',
        'doctor', 'nurse', 'pharmacy', 'where is the clinic',
        'medical care', 'feel sick', 'not feeling well',
        'emergency', 'health services',
      ],
      answer:
          'The University Health Centre is open 24/7 for emergencies and 8 AM to 6 PM for regular consultations. '
          'It is located near the main gate, opposite the sports complex. '
          'Bring your student ID — basic consultation is free for registered students. '
          'For emergencies, call the university ambulance service.',
      nodeId: 'gate_a',
    ),

    // ── Faculty / Departments ──
    KnowledgeEntry(
      category: 'Faculties',
      keywords: [
        'faculty', 'department', 'lecturer', 'professor', 'hod',
        'head of department', 'faculty office', 'dean',
        'departmental office', 'where is my department',
        'course advisor', 'level adviser', 'academic adviser',
        'faculty of science', 'faculty of arts',
      ],
      answer:
          'Each faculty and department has its own administrative office. '
          'Your course adviser or level adviser is assigned at the start of each session. '
          'Visit your departmental office to find your Head of Department (HOD) or '
          'academic adviser for course-related issues.',
      nodeId: 'sci',
    ),

    // ── Sports / Recreation ──
    KnowledgeEntry(
      category: 'Sports',
      keywords: [
        'sport', 'sports', 'gym', 'fitness', 'sports complex',
        'football', 'basketball', 'swimming', 'track',
        'recreation', 'exercise', 'workout', 'sports centre',
      ],
      answer:
          'The University Sports Complex is located opposite the Health Centre. '
          'Facilities include a football pitch, basketball court, swimming pool, and gym. '
          'Student access is free with your ID card. The gym is open 6 AM to 9 PM daily.',
      nodeId: 'gate_a',
    ),

    // ── IT / Internet ──
    KnowledgeEntry(
      category: 'IT Services',
      keywords: [
        'wifi', 'internet', 'network', 'campus wifi', 'connect wifi',
        'student portal', 'portal login', 'password', 'forgot password',
        'reset password', 'email', 'student email', 'it support',
        'ict', 'computer', 'computer lab',
      ],
      answer:
          'The ICT Centre manages campus WiFi, student portals, and IT support. '
          'Connect to the campus WiFi using your matric number and portal password. '
          'For portal or email issues, visit the ICT Centre in the Senate Building annex '
          'or raise a ticket on the student portal. Computer labs are open 8 AM to 8 PM.',
      nodeId: 'hall',
    ),

    // ── Security ──
    KnowledgeEntry(
      category: 'Security',
      keywords: [
        'security', 'police', 'emergency', 'report', 'stolen',
        'theft', 'lost item', 'lost and found', 'safety',
        'campus security', 'security post', 'escort',
      ],
      answer:
          'The Campus Security Office is located at the main gate and operates 24/7. '
          'Report any incidents or lost items there. Emergency numbers are posted on '
          'notice boards across campus. Security escorts are available at night — '
          'dial the security desk from any campus phone.',
      nodeId: 'gate_a',
    ),

    // ── Transport / Parking ──
    KnowledgeEntry(
      category: 'Transport',
      keywords: [
        'parking', 'park', 'car park', 'shuttle', 'bus',
        'campus shuttle', 'transport', 'vehicle', 'driver',
        'where to park', 'bus stop', 'taxi rank',
      ],
      answer:
          'The campus shuttle runs every 15 minutes from the main gate to key locations across campus, '
          '8 AM to 6 PM on weekdays. Student parking is available at designated lots — '
          'register your vehicle with the Transport Unit at the Works Department. '
          'A student parking permit is required.',
      nodeId: 'gate_a',
    ),

    // ── General / Campus Navigation ──
    KnowledgeEntry(
      category: 'Campus Navigation',
      keywords: [
        'where is', 'how do i get to', 'navigate', 'direction',
        'location', 'find', 'building', 'office', 'auditorium',
        'lecture hall', 'classroom', 'venue',
        'orientation', 'campus map', 'find my way',
      ],
      answer:
          'For campus navigation, use the "Plan a Route" or "Where am I?" feature on the home screen. '
          'The app can guide you to any campus waypoint using GPS and camera-based scene recognition. '
          'Major landmarks include the Senate Building, Main Library, Sports Complex, and Main Gate.',
    ),
  ];

  static const List<MapEntry<String, String>> _nodeRef = [
    MapEntry('hall', 'UNILAG Senate House (Senate Building / Administrative Block)'),
    MapEntry('lib', 'University Library'),
    MapEntry('sci', 'Faculty of Science'),
    MapEntry('arts', 'Faculty of Arts'),
    MapEntry('gate_a', 'UNILAG Main Gate (Security, Health Centre, Transport)'),
    MapEntry('gate_b', 'UNILAG Lagoon Front Gate'),
    MapEntry('caf', 'Campus Cafeteria'),
    MapEntry('shelter1', 'Library Covered Walkway'),
  ];

  KnowledgeEntry? search(String query) {
    final lower = query.toLowerCase();
    KnowledgeEntry? bestMatch;
    int bestScore = 0;

    for (final entry in entries) {
      int score = 0;
      for (final keyword in entry.keywords) {
        if (lower == keyword) {
          score += 100;
        } else if (lower.contains(keyword)) {
          score += 50;
        } else if (keyword.contains(lower)) {
          score += 30;
        } else {
          final queryWords = lower.split(RegExp(r'\s+'));
          final kwWords = keyword.split(RegExp(r'\s+'));
          for (final qw in queryWords) {
            if (qw.length < 3) continue;
            for (final kw in kwWords) {
              if (kw.contains(qw) || qw.contains(kw)) {
                score += 10;
              }
            }
          }
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry;
      }
    }

    return bestScore >= 10 ? bestMatch : null;
  }

  String buildSystemPrompt() {
    final buf = StringBuffer();
    buf.writeln('You are Iris, a campus assistant for visually impaired students.');
    buf.writeln('Answer questions about campus services, locations, and procedures using ONLY the knowledge below.');
    buf.writeln('If the knowledge below does not contain the answer, say "I don\'t have that information yet."');
    buf.writeln('Keep responses under 80 words, in plain spoken English, no preamble.');
    buf.writeln();
    buf.writeln('─── CAMPUS KNOWLEDGE BANK ───');
    buf.writeln();
    for (final entry in entries) {
      buf.writeln('[${entry.category}] ${entry.answer}');
    }
    buf.writeln();
    buf.writeln('─── CAMPUS WAYPOINT NODES ───');
    buf.writeln();
    for (final n in _nodeRef) {
      buf.writeln('${n.key}: ${n.value}');
    }
    buf.writeln();
    buf.writeln('─── NAVIGATION INSTRUCTION ───');
    buf.writeln('If the user\'s question relates to a specific campus location that has a waypoint node above,');
    buf.writeln('append exactly one line at the very end of your response in this format:');
    buf.writeln('[NAV:node_id]');
    buf.writeln('where node_id is one of: hall, lib, sci, arts, gate_a, gate_b, caf, shelter1.');
    buf.writeln('If the question does not relate to a specific waypoint, do NOT include the [NAV:] line.');
    buf.writeln('The [NAV:] line must be the LAST line of your response, separated by a newline from the answer.');
    buf.writeln();
    buf.writeln('─── END ───');
    return buf.toString();
  }
}
