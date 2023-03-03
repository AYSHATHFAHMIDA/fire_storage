import 'dart:core';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'firebase_options.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

   FirebaseStorage storage=FirebaseStorage.instance;

   Future<void> _upload(String s) async{
     final picker=ImagePicker();
     XFile? pickedImage;  //Xfile-cross plateform file (path)

     try{
       pickedImage=await picker.pickImage(
           source: s =='camera'?ImageSource.camera:ImageSource.gallery,
         maxWidth: 1920
       );
       final String fileName=path.basename(pickedImage!.path);
       File imageFile =File(pickedImage.path);
       try{
         await storage.ref(fileName).putFile(
           imageFile,
           SettableMetadata(
             customMetadata: {
               'uploaded_by':'aysha',
               'description':'my photo collection',
             }
           ),
         );
         setState(() {

         });
       }on FirebaseException catch(error){
         if(kDebugMode){
           print(error);
         }
       }
     }catch(e){
       if(kDebugMode){
         print(e);
       }
     }

   }

  Future<List<Map<String,dynamic>>> _loadImages() async{
     List<Map<String,dynamic>> files=[];
     final ListResult result=await storage.ref().list();
     final List<Reference>allFiles=result.items;

     await Future.forEach<Reference>(allFiles,
         (file)async{
       final String fileUrl =await file.getDownloadURL();
       final FullMetadata fileMeta =await file.getMetadata();
       files.add({
         "url": fileUrl,
         "path": file.fullPath,
         "uploaded_by": fileMeta.customMetadata?['uploaded_by']??'Nobody',
         "description": fileMeta.customMetadata?['description']??'No description',
       });
     });
     return files;
  }

   Future<void>  _delete(String ref) async{
     await storage.ref(ref).delete();
     setState(() {

     });
   }
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Storage'),
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton.icon(
                        onPressed: (){
                          _upload('camera');
                        },
                        icon: const Icon(Icons.camera),
                        label: const Text('camera')
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (){
                    _upload('gallery');
                  },
                  icon: const Icon(Icons.library_add),
                  label: const Text('Gallery'),
                )

              ],
            ),
            Expanded(
                child: FutureBuilder(
                  future: _loadImages(),
                  builder: (context, AsyncSnapshot<List<Map<String,dynamic>>> snapshot) {
                    if(snapshot.connectionState==ConnectionState.done){
                      return ListView.builder(
                        itemCount: snapshot.data?.length??0,
                        itemBuilder: (context,index){
                          final Map<String,dynamic>image=snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              dense: false,
                              leading: Image.network(image['url']),
                              title: Text(image['uploaded_by']),
                              subtitle: Text(image['description']),
                              trailing: IconButton(
                                onPressed: () {
                                  _delete(image['path']);
                                }, icon: const Icon(Icons.delete,color: Colors.red,),
                              ),
                            ),
                          );
                        },
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  },
                )
            ),
          ],
        ),
      ),

    );
  }
}


