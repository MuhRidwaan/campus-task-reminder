import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Model untuk sebuah catatan
class Note {
  final String id;
  final String courseCategoryId;
  String title;
  String content;
  final DateTime lastModified;

  Note({
    required this.id,
    required this.courseCategoryId,
    required this.title,
    required this.content,
    required this.lastModified,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      courseCategoryId: map['courseCategoryId'],
      title: map['title'],
      content: map['content'],
      lastModified: DateTime.parse(map['lastModified']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'courseCategoryId': courseCategoryId,
      'title': title,
      'content': content,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

// Provider untuk mengelola state catatan
class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  NoteProvider() {
    loadNotes();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString('user_notes') ?? '[]';
    final List<dynamic> notesList = jsonDecode(notesJson);

    _notes = notesList.map((noteMap) => Note.fromMap(noteMap)).toList();
    _notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesList = _notes.map((note) => note.toMap()).toList();
    await prefs.setString('user_notes', jsonEncode(notesList));
  }

  Future<void> addNote(
      String title, String content, String courseCategoryId) async {
    final newNote = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      courseCategoryId: courseCategoryId,
      lastModified: DateTime.now(),
    );
    _notes.insert(0, newNote);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note updatedNote) async {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      _notes.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((note) => note.id == id);
    await _saveNotes();
    notifyListeners();
  }
}
