// main.dart
import 'package:flutter/material.dart';

import 'sql_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        // Supprimer la bannière de débogage
        debugShowCheckedModeBanner: false,
        title: 'Mes notes',
        theme: ThemeData(primarySwatch: Colors.grey),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Toutes les notes
  List<Map<String, dynamic>> _notes = [];

  bool _isLoading = true;
  // Récuperation de toutes les donnée de la bd
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _notes = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Chargement au démarrage de l'application
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Cette fonction est déclenchée lorsque l'on appuie sur le bouton flottant.
  // Il sera également déclenché lorsque vous voudrez mettre à jour une note
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _notes.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // Rendre le clavier souple pour pouvoir écrire
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Title'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Ajouter une note
                      if (id == null) {
                        await _addItem();
                      }

                      if (id != null) {
                        await _updateItem(id);
                      }

                      // Mettre les entrées à jour
                      _titleController.text = '';
                      _descriptionController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Ajouter' : 'Modifier'),
                  )
                ],
              ),
            ));
  }

// Insérer une nouvelle note dans la base de données
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  // Mettre une note à jour
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Votre note a bien été modifiée!'),
    ));
    _refreshJournals();
  }

  // Supprimer une note
  // void _deleteItem(int id) async {
  //   await SQLHelper.deleteItem(id);
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text('Votre note a bien été supprimée!'),
  //   ));
  //   _refreshJournals();
  // }

  // void _deleteItem(int id, String title) async {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Confirmation'),
  //         content: Text('Voulez-vous vraiment supprimer cette note ?'),
  //         actions: [
  //           TextButton(
  //             child: Text('Annuler'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text('Supprimer'),
  //             onPressed: () async {
  //               await SQLHelper.deleteItem(id);
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('Votre note "$title" a bien été supprimée!'),
  //                 ),
  //               );
  //               _refreshJournals();
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  void _deleteItem(int id, String title) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Voulez-vous vraiment supprimer la note "$title" ?'),
          actions: [
            TextButton(
              child: Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Supprimer'),
              onPressed: () async {
                await SQLHelper.deleteItem(id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('La note "$title" a bien été supprimée!'),
                  ),
                );
                _refreshJournals();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes notes'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) => Card(
                color: Color.fromARGB(255, 196, 201, 204),
                margin: const EdgeInsets.all(15),
                child: ListTile(
                    title: Text(_notes[index]['title']),
                    subtitle: Text(_notes[index]['description']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(_notes[index]['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(
                                _notes[index]['id'], _notes[index]['title']),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
