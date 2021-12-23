import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final firestore = FirebaseFirestore.instance;
  late final CollectionReference notesRef;
  final formKey = GlobalKey<FormState>();
  String title = '', description = '';

  Future<void> insertNote() async {
    await notesRef.add({
      'title': title,
      'description': description,
    });
    // Navigator.pop(context);
  }

  Future<QuerySnapshot<Object?>> getDocuments() async {
    return notesRef.get();
  }

  updateDialog(QueryDocumentSnapshot doc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Note'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: doc.get('title'),
                  validator: (value) {
                    if (value != null) {
                      if (value.isEmpty) return 'Title is required';
                      if (value.length < 3) return 'Invalid Title Length';
                    }
                  },
                  onSaved: (newValue) {
                    if (newValue != null) title = newValue;
                  },
                  decoration: InputDecoration(hintText: 'Title'),
                ),
                TextFormField(
                  initialValue: doc.get('description'),
                  validator: (value) {
                    if (value != null) {
                      if (value.isEmpty) return 'Desc is required';
                      if (value.length < 3) return 'Invalid Desc Length';
                    }
                  },
                  onSaved: (newValue) {
                    if (newValue != null) description = newValue;
                  },
                  decoration: InputDecoration(hintText: 'Description'),
                )
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                if (formKey.currentState != null) {
                  formKey.currentState!.save();
                  if (formKey.currentState!.validate()) {
                    notesRef.doc(doc.id).update({
                      'title': title,
                      'description': description,
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    notesRef = firestore.collection('Notes');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Note App'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: Text('New Note'),
                    content: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            validator: (value) {
                              if (value != null) {
                                if (value.isEmpty) return 'Title is required';
                                if (value.length < 3)
                                  return 'Invalid Title Length';
                              }
                            },
                            onSaved: (newValue) {
                              if (newValue != null) title = newValue;
                            },
                            decoration: InputDecoration(hintText: 'Title'),
                          ),
                          TextFormField(
                            validator: (value) {
                              if (value != null) {
                                if (value.isEmpty) return 'Desc is required';
                                if (value.length < 3)
                                  return 'Invalid Desc Length';
                              }
                            },
                            onSaved: (newValue) {
                              if (newValue != null) description = newValue;
                            },
                            decoration:
                                InputDecoration(hintText: 'Description'),
                          )
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text('Close'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      TextButton(
                        child: Text('Save'),
                        onPressed: () {
                          if (formKey.currentState != null) {
                            formKey.currentState!.save();
                            if (formKey.currentState!.validate()) {
                              insertNote();
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
        // StreamBuilder
        body: FutureBuilder<QuerySnapshot>(
          future: getDocuments(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final docs = snapshot.data!.docs;
                if (docs.isNotEmpty)
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onLongPress: () => updateDialog(docs[index]),
                        child: ListTile(
                          title: Text(docs[index].get('title')),
                          subtitle: Text(docs[index].id),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              await notesRef.doc(docs[index].id).delete();
                            },
                          ),
                        ),
                      );
                    },
                  );
                return Center(child: Text('No Notes Found'));
              default:
                return Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}
