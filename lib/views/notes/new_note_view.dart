import 'package:flutter/material.dart';
import 'package:notes_app/services/auth/auth_service.dart';
import 'package:notes_app/services/crud/notes_service.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNotesViewState();
}

class _NewNotesViewState extends State<NewNoteView> {
  //Keep hold of our current note view
  //otherwise new note will be created every time we hot reload
  DatabaseNote? _note;
  //keep refrence to NoteService to not call over and over the singelton to noteservice
  late final NotesService _notesService;
  //keep track of text changes
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    //NotesService is a singeltone and will not create again wich is a good thing
    _notesService = NotesService();
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
      note: note,
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
  Future<DatabaseNote> createNewNote() async {
    //have we create the note before
    final existingNote = _note;
    if (existingNote != null) {
      return existingNote;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _notesService.getUser(email: email);
    return await _notesService.createNote(owner: owner);
  }

  //If the note is empty, and user goes back, delete the note
  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textEditingController.text.isEmpty && note != null) {
      _notesService.deleteNote(id: note.id);
    }
  }

  //Save the note automaticaly if text is not empty
  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textEditingController.text;
    if (text.isNotEmpty && note != null) {
      await _notesService.updateNote(note: note, text: text);
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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Note'),
      ),
      body: FutureBuilder(
        //when this createNewNote is finished return note
        // if we are waiting then CircularProgressIndicator
        future: createNewNote(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _note = snapshot.data;
              _setupTextControllerListener();
              return TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.multiline,
                //give the textfield unlimited lines so it expends
                maxLines: null,
              );
            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
