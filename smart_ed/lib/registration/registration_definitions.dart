/// Punjab Board (Pakistan) academic registration definitions.
///
/// This file is intentionally framework-agnostic (no Flutter imports).

enum ClassLevel {
  class9,
  class10,
  class11,
  class12,
}

extension ClassLevelUi on ClassLevel {
  String get label => switch (this) {
        ClassLevel.class9 => 'Class 9',
        ClassLevel.class10 => 'Class 10',
        ClassLevel.class11 => 'Class 11 (1st Year)',
        ClassLevel.class12 => 'Class 12 (2nd Year)',
      };

  bool get isMatric => this == ClassLevel.class9 || this == ClassLevel.class10;
}

/// Matric groups (Class 9 & 10).
enum MatricGroup {
  biology,
  computerScience,
  generalScience,
  arts,
}

extension MatricGroupUi on MatricGroup {
  String get label => switch (this) {
        MatricGroup.biology => 'Biology Group',
        MatricGroup.computerScience => 'Computer Science Group',
        MatricGroup.generalScience => 'General Science Group',
        MatricGroup.arts => 'Arts Group',
      };
}

/// Intermediate groups (Class 11 & 12).
enum InterGroup {
  fscPreMedical,
  fscPreEngineering,
  ics,
  fa,
  iCom,
}

extension InterGroupUi on InterGroup {
  String get label => switch (this) {
        InterGroup.fscPreMedical => 'FSc Pre-Medical',
        InterGroup.fscPreEngineering => 'FSc Pre-Engineering',
        InterGroup.ics => 'ICS',
        InterGroup.fa => 'FA',
        InterGroup.iCom => 'I.Com',
      };
}

/// A subject "slot" in UI: either fixed (one subject) or elective (choose from options).
sealed class SubjectSlot {
  const SubjectSlot();
}

class FixedSubjectSlot extends SubjectSlot {
  final String subject;
  const FixedSubjectSlot(this.subject);
}

class ElectiveSubjectSlot extends SubjectSlot {
  final String label;
  final List<String> options;
  const ElectiveSubjectSlot({
    required this.label,
    required this.options,
  });
}

class GroupDefinition {
  final String groupLabel;
  final List<SubjectSlot> subjectSlots;

  const GroupDefinition({
    required this.groupLabel,
    required this.subjectSlots,
  });
}

/// Common compulsory subjects used across groups.
const List<String> _compulsoryMatric = <String>[
  'English',
  'Urdu',
  'Islamiat / Pak Studies',
];

const List<String> _artsElectives = <String>[
  'Civics',
  'Economics',
  'Education',
  'Islamiyat Elective',
  'History',
  'Geography',
  'Computer Science (Arts)',
  'General Science',
  'Home Economics',
  'Arabic',
  'Persian',
];

GroupDefinition matricGroupDefinition(MatricGroup group) {
  switch (group) {
    case MatricGroup.biology:
      return GroupDefinition(
        groupLabel: group.label,
        subjectSlots: const [
          FixedSubjectSlot('Biology'),
          FixedSubjectSlot('Physics'),
          FixedSubjectSlot('Chemistry'),
          FixedSubjectSlot('Mathematics'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case MatricGroup.computerScience:
      return GroupDefinition(
        groupLabel: group.label,
        subjectSlots: const [
          FixedSubjectSlot('Computer Science'),
          FixedSubjectSlot('Physics'),
          FixedSubjectSlot('Chemistry'),
          FixedSubjectSlot('Mathematics'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case MatricGroup.generalScience:
      return GroupDefinition(
        groupLabel: group.label,
        subjectSlots: const [
          FixedSubjectSlot('General Science'),
          FixedSubjectSlot('Mathematics'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case MatricGroup.arts:
      return GroupDefinition(
        groupLabel: group.label,
        subjectSlots: const [
          ElectiveSubjectSlot(label: 'Elective 1', options: _artsElectives),
          ElectiveSubjectSlot(label: 'Elective 2', options: _artsElectives),
          ElectiveSubjectSlot(label: 'Elective 3', options: _artsElectives),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
  }
}

/// Allowed Inter groups strictly depend on Matric group.
const Map<MatricGroup, List<InterGroup>> allowedInterGroupsByMatric = {
  MatricGroup.biology: [InterGroup.fscPreMedical],
  MatricGroup.computerScience: [InterGroup.fscPreEngineering, InterGroup.ics],
  MatricGroup.generalScience: [InterGroup.ics, InterGroup.fa],
  MatricGroup.arts: [InterGroup.fa, InterGroup.iCom],
};

/// Simple (scalable) mapping for Inter group → subjects.
///
/// Note: Punjab Board subject details vary; this keeps a clean structure and can be expanded.
GroupDefinition interGroupDefinition(
    InterGroup group, MatricGroup matricGroup) {
  // Subjects in 11th/12th depend strictly on Matric group (the allowed group list
  // already enforces that), and then on chosen Inter group.
  switch (group) {
    case InterGroup.fscPreMedical:
      return const GroupDefinition(
        groupLabel: 'FSc Pre-Medical',
        subjectSlots: [
          FixedSubjectSlot('Biology'),
          FixedSubjectSlot('Physics'),
          FixedSubjectSlot('Chemistry'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case InterGroup.fscPreEngineering:
      return const GroupDefinition(
        groupLabel: 'FSc Pre-Engineering',
        subjectSlots: [
          FixedSubjectSlot('Mathematics'),
          FixedSubjectSlot('Physics'),
          FixedSubjectSlot('Chemistry'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case InterGroup.ics:
      return const GroupDefinition(
        groupLabel: 'ICS',
        subjectSlots: [
          FixedSubjectSlot('Computer Science'),
          FixedSubjectSlot('Mathematics'),
          FixedSubjectSlot('Physics'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case InterGroup.fa:
      // FA subjects depend on Matric group; keep it as elective slots for now.
      // You can later expand FA elective lists by board rules.
      return const GroupDefinition(
        groupLabel: 'FA',
        subjectSlots: [
          ElectiveSubjectSlot(label: 'Elective 1', options: _artsElectives),
          ElectiveSubjectSlot(label: 'Elective 2', options: _artsElectives),
          ElectiveSubjectSlot(label: 'Elective 3', options: _artsElectives),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
    case InterGroup.iCom:
      return const GroupDefinition(
        groupLabel: 'I.Com',
        subjectSlots: [
          FixedSubjectSlot('Principles of Accounting'),
          FixedSubjectSlot('Principles of Economics'),
          FixedSubjectSlot('Principles of Commerce'),
          FixedSubjectSlot('English'),
          FixedSubjectSlot('Urdu'),
          FixedSubjectSlot('Islamiat / Pak Studies'),
        ],
      );
  }
}
