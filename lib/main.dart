

import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async{
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
runApp(MaterialApp(home: myapp(),debugShowCheckedModeBanner: false,theme: ThemeData(primarySwatch: Colors.green),));
}
class myapp extends StatefulWidget{
  @override
  State<myapp> createState() => _myappState();
}

class _myappState extends State<myapp> {
  FirebaseStorage storage=FirebaseStorage.instance;
  Future<void>upload(String inputsource)async{
    final picker=ImagePicker();
    XFile? pickedimage;
    try{
      pickedimage=await picker.pickImage(
        source:inputsource=="camera"
        ?ImageSource.camera
        :ImageSource.gallery,
        maxWidth: 1920 );

        final String filename=path.basename(pickedimage!.path);
        File imagefile=File(pickedimage.path);

      try{
        await storage.ref(filename).putFile(
          imagefile,
          SettableMetadata(
            customMetadata: {
              "uploaded_by":"A New User",
              "description":"Some descriptions..."
            }
          )
        );
        setState(() {
          
        });
      } 
       on FirebaseException catch(error){
        if(kDebugMode){
          print(error);
        }
       }
    }
    catch(err){
      if(kDebugMode){
        print(err);
      }
    }
  }
  Future <List<Map<String,dynamic>>>loadimages()async{
  List<Map<String,dynamic>>files=[];

  final ListResult result=await storage.ref().list();
  final List<Reference>allfiles=result.items;
  await Future.forEach<Reference>(allfiles, (file) async{
  final String fileurl=await file.getDownloadURL();
  final FullMetadata filemeta=await file.getMetadata();
  
   files.add({
        "url": fileurl,
        "path": file.fullPath,
        "uploaded_by": filemeta.customMetadata?['uploaded_by'] ?? 'Nobody',
        "description": filemeta.customMetadata?['description'] ?? 'No description'
      });
    });

    return files;
  }
  Future<void>delete(String ref)async{
    await storage.ref(ref).delete();
    setState(() {
      
    });
  }
  @override
  Widget build(BuildContext context) {
   return Scaffold(
appBar: AppBar(title: Text("FIREBASE STORAGE"),),
body: Padding(padding: EdgeInsets.all(20),
child: Column(
  children: [Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [ElevatedButton.icon(
    onPressed: (() => upload("camera")),
     icon: Icon(Icons.camera),
      label: Text("CAMERA")),
    ElevatedButton.icon(
      onPressed:(() => upload("gallery")) ,
       icon: Icon(Icons.browse_gallery_outlined), 
       label: Text("GALLERY"))
      ],),
      Expanded(child: 
      FutureBuilder(
        future: loadimages(),
        builder:((context, 
        AsyncSnapshot<List<Map<String,dynamic>>>
        snapshot) {
         if(snapshot.connectionState==ConnectionState.done){
          return ListView.builder(
            itemCount: snapshot.data?.length??0,
            itemBuilder: ((context, index) {
              final Map<String,dynamic>image=snapshot.data![index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  dense: false,
                  leading: Image.network(image["url"]),
                  title: Text(image["uploadedby"]),
                  subtitle: Text(image["description"]),
                  trailing: IconButton(onPressed: (() => delete(image["path"])),
                   icon: Icon(Icons.delete),color: Colors.red,),

                ),
              );
            }));
         } 
         return Center(
          child: CircularProgressIndicator(),
         );
        }) ))
      ],

),
),

   );
  }
}