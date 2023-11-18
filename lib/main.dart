import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final keyApplicationId = '8z8h4lYcQuOyw7N2AV9A8n5icQGTcu7KAeqq8MIu';
  final keyClientKey = 'r1mHJbWxvw59YJjMM2keJGnc3OEno4jPh7HcZeSP';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl, clientKey: keyClientKey, autoSendSessionId: true,
  liveQueryUrl: 'bitswilp2022mt93577.b4a.io', debug: true);
  runApp(const MaterialApp(home: Home(),));

}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final taskController = TextEditingController();
  final descriptionController = TextEditingController();
  List<ParseObject> taskList = [];
  final QueryBuilder<ParseObject> queryTask =
      QueryBuilder<ParseObject>(ParseObject('Task'))
        ..orderByAscending('createdAt');

  StreamController<List<ParseObject>> streamController = StreamController();

  final LiveQuery liveQuery = LiveQuery(debug: true);
  late Subscription<ParseObject> subscription;

  void addTask() async {
    if (taskController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTask(taskController.text, descriptionController.text);
    taskController.clear();
    descriptionController.clear();
  }


  @override
  void initState() {
    super.initState();
    getTaskList();
    startLiveQuery();
  }

  void startLiveQuery() async {
    subscription = await liveQuery.client.subscribe(queryTask);

    subscription.on(LiveQueryEvent.create, (value) {
      debugPrint('*** CREATE ***: $value ');
      taskList.add(value);
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.update, (value) {
      debugPrint('*** UPDATE ***: $value ');
      taskList[taskList
          .indexWhere((element) => element.objectId == value.objectId)] = value;
      streamController.add(taskList);
    });

    subscription.on(LiveQueryEvent.delete, (value) {
      debugPrint('*** DELETE ***: $value ');
      taskList.removeWhere((element) => element.objectId == value.objectId);
      streamController.add(taskList);
    });
  }

  
  void cancelLiveQuery() async {
    liveQuery.client.unSubscribe(subscription);
  }

  Future<void> saveTask(String title, String description) async {
    final task = ParseObject('Task')
      ..set('title', title)
      ..set('description', description)
      ..set('done', false);
    await task.save();
  }

  void getTaskList() async {
    final ParseResponse apiResponse = await queryTask.query();

    if (apiResponse.success && apiResponse.results != null) {
      taskList.addAll(apiResponse.results as List<ParseObject>);
      streamController.add(apiResponse.results as List<ParseObject>);
    } else {
      taskList.clear();
      streamController.add([]);
    }
  }

  Future<void> updateTask(String id, bool done) async {
    var task = ParseObject('Task')
      ..objectId = id
      ..set('done', done);
    await task.save();
  }

  Future<void> deleteTask(String id) async {
    var task = ParseObject('Task')..objectId = id;
    await task.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task List", style: TextStyle(
    color: Colors.white
  )),
        backgroundColor: Color.fromARGB(255, 116, 50, 230),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
        Container(
          padding: const EdgeInsets.fromLTRB(17.0, 5.0, 7.0, 1.0),
          child: Column(
          children: <Widget>[
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Enter Title",
                labelStyle: TextStyle(color: Color.fromARGB(255, 128, 78, 13)),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              autocorrect: true,
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: "Enter Description",
                labelStyle: TextStyle(color: Color.fromARGB(255, 128, 78, 13)),
                // contentPadding: EdgeInsets.all(20.0),
              ),
            ),
                  SizedBox(height: 20),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                        onPrimary: Colors.white,
                        primary: Color.fromARGB(255, 55, 176, 18),
                      ),
                      onPressed: addTask,
                      child: const Text("ADD")),
                ],
              )),
          Expanded(
              child: StreamBuilder<List<ParseObject>>(
            stream: streamController.stream,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(
                    child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator()),
                  );
                default:
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error..."),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("No Data..."),
                    );
                  } else {
                    return ListView.builder(
                        padding: const EdgeInsets.only(top: 10.0),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          //*************************************
                          //Get Parse Object Values
                          final varTask = snapshot.data![index];
                          final varTitle = varTask.get<String>('title')!;
                          final varDescription = varTask.get<String>('description')!;
                          final varDone = varTask.get<bool>('done')!;
                          //*************************************

                          return ListTile(
                            title: Text(varTitle),
                            subtitle: Text(varDescription),
                            leading: CircleAvatar(
                              child: Icon(varDone ? Icons.check : Icons.error),
                              backgroundColor:
                                  varDone ? Color.fromARGB(255, 190, 89, 6) : Color.fromARGB(255, 193, 152, 6),
                              foregroundColor: Colors.white,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                    value: varDone,
                                    onChanged: (value) async {
                                      await updateTask(
                                          varTask.objectId!, value!);
                                      //setState(() {
                                      //  //Refresh UI
                                      //});
                                    }),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Color.fromARGB(255, 215, 11, 11),
                                  ),
                                  onPressed: () async {
                                    await deleteTask(varTask.objectId!);
                                    //setState(() {
                                    const snackBar = SnackBar(
                                      content: Text("Task deleted!"),
                                      duration: Duration(seconds: 2),
                                    );
                                    ScaffoldMessenger.of(context)
                                      ..removeCurrentSnackBar()
                                      ..showSnackBar(snackBar);
                                    //});
                                  },
                                )
                              ],
                            ),
                          );
                        });
                  }
              }
            },
          ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    cancelLiveQuery();
    streamController.close();
    super.dispose();
  }
}
