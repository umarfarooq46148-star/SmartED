import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../registration/registration_definitions.dart';
import '../registration/registration_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();

  bool _showAcademicErrors = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationState(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Student Registration (Punjab Board)'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Create Your Learning Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter student details and academic registration.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildPersonalSection(context),
                    const SizedBox(height: 24),
                    _buildAcademicSection(context),
                    const SizedBox(height: 24),
                    _buildSubmitButton(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalSection(BuildContext context) {
    final state = context.watch<RegistrationState>();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.next,
              onChanged: state.setName,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onChanged: state.setAge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your age';
                }
                final int? age = int.tryParse(value);
                if (age == null || age <= 0) {
                  return 'Please enter a valid age';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender>(
              value: state.gender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: Gender.values
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(g.label),
                    ),
                  )
                  .toList(),
              onChanged: state.setGender,
              validator: (v) => v == null ? 'Please select gender' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rollNumberController,
              decoration: const InputDecoration(
                labelText: 'Roll Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              textInputAction: TextInputAction.done,
              onChanged: state.setRollNumber,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your roll number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicSection(BuildContext context) {
    final state = context.watch<RegistrationState>();

    final academicError = _showAcademicErrors ? state.validateAcademic() : null;

    final illegalMessage = state.illegalSelectionMessage;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Academic Registration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ClassLevel>(
              value: state.classLevel,
              decoration: const InputDecoration(
                labelText: 'Class Level',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: ClassLevel.values
                  .map(
                    (cl) => DropdownMenuItem(
                      value: cl,
                      child: Text(cl.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                state.setClassLevel(v);
              },
              validator: (v) => v == null ? 'Please select class level' : null,
            ),
            const SizedBox(height: 16),
            if (state.classLevel == null)
              const SizedBox.shrink()
            else if (state.classLevel!.isMatric)
              _buildMatricGroupAndSubjects(context)
            else
              _buildInterGroupAndSubjects(context),
            if (illegalMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                illegalMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (academicError != null) ...[
              const SizedBox(height: 12),
              Text(
                academicError,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatricGroupAndSubjects(BuildContext context) {
    final state = context.watch<RegistrationState>();
    final classLevel = state.classLevel;
    if (classLevel == null || !classLevel.isMatric) return const SizedBox();

    final isLocked =
        classLevel == ClassLevel.class10 && state.matricGroup != null;

    final groupItems = MatricGroup.values
        .map(
          (g) => DropdownMenuItem<MatricGroup>(
            value: g,
            enabled: !isLocked || state.matricGroup == g,
            child: Text(g.label),
          ),
        )
        .toList();

    final selected = state.matricGroup;
    final def = selected == null ? null : matricGroupDefinition(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<MatricGroup>(
          value: selected,
          decoration: InputDecoration(
            labelText: 'Group / Stream',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.account_tree),
            helperText: isLocked
                ? 'Locked: Group selected in Class 9 is fixed for Class 10.'
                : null,
          ),
          items: groupItems,
          onChanged: isLocked
              ? null
              : (v) {
                  state.trySetMatricGroup(v);
                },
          validator: (v) => v == null ? 'Please select Matric group' : null,
        ),
        if (def != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Subjects',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildSubjectSlots(context, def),
        ],
      ],
    );
  }

  Widget _buildInterGroupAndSubjects(BuildContext context) {
    final state = context.watch<RegistrationState>();

    final mg = state.matricGroup;
    final allowed = mg == null
        ? const <InterGroup>[]
        : (allowedInterGroupsByMatric[mg] ?? []);

    final items = InterGroup.values
        .map(
          (g) => DropdownMenuItem<InterGroup>(
            value: g,
            enabled: allowed.contains(g),
            child: Text(g.label),
          ),
        )
        .toList();

    final selected = state.interGroup;
    final def = (selected != null && mg != null)
        ? interGroupDefinition(selected, mg)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<InterGroup>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Group / Stream',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_tree),
            helperText: 'Allowed groups depend strictly on your Matric group.',
          ),
          items: items,
          onChanged: (v) {
            state.trySetInterGroup(v);
          },
          validator: (v) => v == null ? 'Please select group' : null,
        ),
        if (def != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Subjects',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._buildSubjectSlots(context, def),
        ],
      ],
    );
  }

  List<Widget> _buildSubjectSlots(BuildContext context, GroupDefinition def) {
    final state = context.watch<RegistrationState>();

    final widgets = <Widget>[];
    for (var i = 0; i < def.subjectSlots.length; i++) {
      final slot = def.subjectSlots[i];
      widgets.add(_buildSubjectSlotField(context, i, slot));
      widgets.add(const SizedBox(height: 12));
    }
    if (widgets.isNotEmpty) widgets.removeLast();
    return widgets;
  }

  Widget _buildSubjectSlotField(
    BuildContext context,
    int slotIndex,
    SubjectSlot slot,
  ) {
    final state = context.watch<RegistrationState>();

    if (slot is FixedSubjectSlot) {
      // Show as disabled dropdown (still "dropdowns, not free text").
      return DropdownButtonFormField<String>(
        value: slot.subject,
        decoration: const InputDecoration(
          labelText: 'Subject',
          border: OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(value: slot.subject, child: Text(slot.subject)),
        ],
        onChanged: null,
      );
    }

    final elective = slot as ElectiveSubjectSlot;
    final selected = state.electiveSelections[slotIndex];

    final items = elective.options
        .map(
          (s) => DropdownMenuItem<String>(
            value: s,
            enabled:
                !state.isElectiveAlreadyChosen(s, currentSlot: slotIndex) ||
                    selected == s,
            child: Text(s),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: elective.label,
        border: const OutlineInputBorder(),
      ),
      items: items,
      onChanged: (v) {
        state.setElectiveSelection(slotIndex: slotIndex, subject: v);
      },
      validator: (v) {
        if (v == null || v.trim().isEmpty)
          return 'Please select ${elective.label}';
        return null;
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _onRegisterPressed(context),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      child: const Text(
        'Submit Registration',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  void _onRegisterPressed(BuildContext pageContext) {
    final state = pageContext.read<RegistrationState>();

    setState(() {
      _showAcademicErrors = true;
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    final academicError = state.validateAcademic();

    if (!formValid || academicError != null) {
      return;
    }

    // TODO: Persist data to backend/local storage.
    // For now, navigate back to LoginPage.
    Navigator.pushAndRemoveUntil(
      pageContext,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }
}
