import 'package:flutter/foundation.dart';
import 'registration_definitions.dart';

enum Gender { male, female, other }

extension GenderUi on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
      };
}

/// Provider state for the academic registration flow.
class RegistrationState extends ChangeNotifier {
  // Personal info
  String name = '';
  int? age;
  Gender? gender;
  String rollNumber = '';

  // Academic info
  ClassLevel? classLevel;

  /// Group chosen in Class 9 (and locked for Class 10).
  MatricGroup? matricGroup;

  /// Group chosen in Class 11/12 (restricted by matricGroup).
  InterGroup? interGroup;

  /// Elective selections for Arts (Matric) or FA (Inter).
  /// Keys are slot indexes in the current group's definition.
  final Map<int, String> electiveSelections = {};

  String? illegalSelectionMessage;

  void setName(String v) {
    name = v;
    notifyListeners();
  }

  void setAge(String v) {
    age = int.tryParse(v);
    notifyListeners();
  }

  void setGender(Gender? v) {
    gender = v;
    notifyListeners();
  }

  void setRollNumber(String v) {
    rollNumber = v;
    notifyListeners();
  }

  void setClassLevel(ClassLevel? next) {
    classLevel = next;

    // Reset dependent fields when class changes
    interGroup = null;
    electiveSelections.clear();
    illegalSelectionMessage = null;

    // If user jumps to Class 10 and matricGroup is already set from Class 9,
    // group is locked (UI will disable changes) so no additional work needed.
    notifyListeners();
  }

  /// Select Matric group.
  ///
  /// Rules:
  /// - Group selected in Class 9 is locked in Class 10.
  /// - If Arts in Class 9, cannot select Biology/CS/General Science in Class 10+.
  /// - If Biology in Class 9, cannot switch to CS in Class 10 (covered by lock).
  bool trySetMatricGroup(MatricGroup? next) {
    illegalSelectionMessage = null;

    if (next == null) {
      matricGroup = null;
      electiveSelections.clear();
      notifyListeners();
      return true;
    }

    // Lock: if we've already chosen a Class 9 group, don't allow changing it when
    // registering Class 10.
    if (classLevel == ClassLevel.class10 && matricGroup != null) {
      if (matricGroup != next) {
        illegalSelectionMessage =
            'Group selected in Class 9 is locked for Class 10.';
        notifyListeners();
        return false;
      }
    }

    // If Arts chosen earlier, disallow moving to science groups later.
    if ((classLevel == ClassLevel.class10 ||
            classLevel == ClassLevel.class11 ||
            classLevel == ClassLevel.class12) &&
        matricGroup == MatricGroup.arts &&
        next != MatricGroup.arts) {
      illegalSelectionMessage =
          'If you selected Arts in Class 9, you cannot switch to Science groups later.';
      notifyListeners();
      return false;
    }

    matricGroup = next;
    interGroup = null;
    electiveSelections.clear();
    notifyListeners();
    return true;
  }

  bool trySetInterGroup(InterGroup? next) {
    illegalSelectionMessage = null;

    if (next == null) {
      interGroup = null;
      electiveSelections.clear();
      notifyListeners();
      return true;
    }

    final mg = matricGroup;
    if (mg == null) {
      illegalSelectionMessage =
          'Please select your Matric group (Class 9/10) first.';
      notifyListeners();
      return false;
    }

    final allowed = allowedInterGroupsByMatric[mg] ?? const <InterGroup>[];
    if (!allowed.contains(next)) {
      illegalSelectionMessage =
          'This group is not allowed based on your Matric group.';
      notifyListeners();
      return false;
    }

    interGroup = next;
    electiveSelections.clear();
    notifyListeners();
    return true;
  }

  void setElectiveSelection({required int slotIndex, required String? subject}) {
    if (subject == null) {
      electiveSelections.remove(slotIndex);
    } else {
      electiveSelections[slotIndex] = subject;
    }
    notifyListeners();
  }

  /// Used to disable options dynamically (no duplicates across elective slots).
  bool isElectiveAlreadyChosen(String subject, {required int currentSlot}) {
    for (final entry in electiveSelections.entries) {
      if (entry.key != currentSlot && entry.value == subject) return true;
    }
    return false;
  }

  /// Validates progression + required academic selections.
  String? validateAcademic() {
    illegalSelectionMessage = null;

    final cl = classLevel;
    if (cl == null) return 'Please select class level.';

    if (cl.isMatric) {
      if (matricGroup == null) return 'Please select your Matric group.';
      final def = matricGroupDefinition(matricGroup!);
      final requiredElectives = def.subjectSlots.whereType<ElectiveSubjectSlot>();
      if (requiredElectives.isNotEmpty) {
        for (var i = 0; i < def.subjectSlots.length; i++) {
          if (def.subjectSlots[i] is ElectiveSubjectSlot &&
              (electiveSelections[i] == null ||
                  electiveSelections[i]!.trim().isEmpty)) {
            return 'Please select all elective subjects.';
          }
        }
      }
      return null;
    }

    // Inter
    if (matricGroup == null) {
      return 'Please select your Matric group (Class 9/10) first.';
    }
    if (interGroup == null) return 'Please select your 11th/12th group.';

    final allowed = allowedInterGroupsByMatric[matricGroup!] ?? const [];
    if (!allowed.contains(interGroup)) {
      return 'Selected 11th/12th group is not allowed for your Matric group.';
    }

    final def = interGroupDefinition(interGroup!, matricGroup!);
    final electives = def.subjectSlots.whereType<ElectiveSubjectSlot>().toList();
    if (electives.isNotEmpty) {
      for (var i = 0; i < def.subjectSlots.length; i++) {
        if (def.subjectSlots[i] is ElectiveSubjectSlot &&
            (electiveSelections[i] == null ||
                electiveSelections[i]!.trim().isEmpty)) {
          return 'Please select all elective subjects.';
        }
      }
    }

    return null;
  }
}

