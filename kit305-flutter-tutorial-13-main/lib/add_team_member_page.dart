import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddTeamMemberPage extends StatefulWidget {
  final String teamName;
  final String? playerId;
  final Map<String, dynamic>? initialData;

  const AddTeamMemberPage({Key? key, required this.teamName, this.playerId, this.initialData}) : super(key: key);

  @override
  State<AddTeamMemberPage> createState() => _AddTeamMemberPageState();
}

class _AddTeamMemberPageState extends State<AddTeamMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final ageController = TextEditingController();
  final jerseyNumberController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;


  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      nameController.text = widget.initialData!['name'] ?? '';
      positionController.text = widget.initialData!['position'] ?? '';
      ageController.text = widget.initialData!['age']?.toString() ?? '';
      jerseyNumberController.text = widget.initialData!['jerseyNumber'] ?? '';
      _imageUrl = widget.initialData!['imageUrl']; // <-- Load image URL
    }
  }


  @override
  void dispose() {
    nameController.dispose();
    positionController.dispose();
    ageController.dispose();
    jerseyNumberController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> savePlayer() async {
    final playersRef = FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamName)
        .collection('players');

    final playerData = {
      'name': nameController.text.trim(),
      'position': positionController.text.trim(),
      'age': int.tryParse(ageController.text.trim()) ?? 0,
      'jerseyNumber': jerseyNumberController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    DocumentReference docRef;

    if (widget.playerId != null) {
      docRef = playersRef.doc(widget.playerId);
      await docRef.update(playerData);
    } else {
      docRef = await playersRef.add(playerData);
    }

    // ✅ Upload image and store URL
    if (_imageFile != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('teams')
            .child(widget.teamName)
            .child('players')
            .child(docRef.id)
            .child('profile.jpg');

        final uploadTask = await storageRef.putFile(_imageFile!);

        final downloadUrl = await uploadTask.ref.getDownloadURL();

        // 🔁 Update Firestore with image URL
        await docRef.update({'imageUrl': downloadUrl});
      } catch (e) {
        print('Image upload failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${e.toString()}')),
        );
      }
    }

    if (context.mounted) Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playerId == null ? 'Add Player' : 'Edit Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_imageUrl != null ? NetworkImage(_imageUrl!) : null) as ImageProvider?,
                  child: (_imageFile == null && _imageUrl == null)
                      ? const Icon(Icons.camera_alt, size: 40)
                      : null,
                ),

              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Player Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              TextFormField(
                controller: positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              TextFormField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              TextFormField(
                controller: jerseyNumberController,
                decoration: const InputDecoration(labelText: 'Jersey Number'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    savePlayer();
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(widget.playerId == null ? 'Add Player' : 'Update Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
