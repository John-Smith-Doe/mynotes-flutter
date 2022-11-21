import 'package:flutter/material.dart';
import 'package:notes_app/services/auth/auth_service.dart';
import 'package:notes_app/services/cloud/firebase_cloud_storage.dart';
import 'package:notes_app/services/logging.dart';
import 'package:notes_app/utilities/generics/get_arguments.dart';
import 'package:notes_app/services/cloud/cloud_note.dart';
import 'package:notes_app/services/cloud/cloud_storage_exception.dart';

class CreateUpdateNoteView extends StatefulWidget {
  const CreateUpdateNoteView({super.key});

  @override
  State<CreateUpdateNoteView> createState() => _NewNotesViewState();
}

class _NewNotesViewState extends State<CreateUpdateNoteView> {
  var log = logger(_NewNotesViewState);
  //Keep hold of our current note view
  //otherwise new note will be created every time we hot reload
  CloudNote? _note;
  //keep refrence to NoteService to not call over and over the singelton to noteservice
  late final FirebaseCloudStorage _notesService;
  //keep track of text changes
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    //NotesService is a singeltone and will not create again wich is a good thing
    _notesService = FirebaseCloudStorage();
    _textEditingController = TextEditingController();
    super.initState();
  }

  //Update out current note upon every text change
  void _textControllerListener() async {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textEditingController.text;
    await _notesService.updateNote(
      documentId: note.documentId,
      text: text,
    );
  }

//hook our text field changes to the listener
//remove and add listener if case the function is called multiple times
  void _setupTextControllerListener() {
    _textEditingController.removeListener(_textControllerListener);
    _textEditingController.addListener(_textControllerListener);
  }

  //create new note
  Future<CloudNote> createOrGetExistingNote(BuildContext context) async {
    log.i('createNewNote funciton is called');

    //get existing notes if any exist
    final widgetNote = context.getArgument<CloudNote>();
    if (widgetNote != null) {
      _note = widgetNote;
      _textEditingController.text = widgetNote.text;
      return widgetNote;
    }
    //have we create the note before
    final existingNote = _note;
    if (existingNote != null) {
      log.i('existingNote is not null');

      return existingNote;
    } else {
      final currentUser = AuthService.firebase().currentUser!;
      log.i('currentUser: $currentUser');
      final email = currentUser.email;
      log.i('email: $email');
      final userId = currentUser.id;
      final newNote = await _notesService.createNewNote(ownerUserId: userId);
      _note = newNote;
      return newNote;
    }
  }

  //If the note is empty, and user goes back, delete the note
  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(documentId: note.documentId);
    }
  }

  //Save the note automaticaly if text is not empty
  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textEditingController.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(
        documentId: note.documentId,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    //always dispose the textEditingControllers
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        //when this createNewNote is finished return note
        // if we are waiting then CircularProgressIndicator
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                //give the textfield unlimited lines so it expends
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Start typing your note...',
                ),
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
