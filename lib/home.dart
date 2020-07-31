import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _todoList = [];
  TextEditingController _textController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveFile() async {
    try {
      String data = json.encode(_todoList);
      File file = await _getFile();

      return file.writeAsString(data);
    } catch (e) {
      return null;
    }
  }

  Future<List> _readData() async {
    File file = await _getFile();
    String data = await file.readAsString();
    return json.decode(data);
  }

  void _addItem() {
    setState(() {
      if (_textController.text.isNotEmpty) {
        _todoList.add({
          'title': _textController.text,
          'done': false,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
        _saveFile();
      }
    });
    _textController.text = '';
  }

  Widget _buildItem(context, index) {
    Map<String, dynamic> item = _todoList[index];

    return Dismissible(
      key: Key(item['id']),
      background: Container(
        color: Colors.red,
        alignment: Alignment(-0.85, 0),
        child: Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(item);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
        });

        _saveFile();

        final snack = SnackBar(
          content: Text('Tarefa \"${_lastRemoved['title']}\" removida'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () {
              setState(() {
                _todoList.insert(_lastRemovedPos, _lastRemoved);
              });
              _saveFile();
            },
          ),
        );

        Scaffold.of(context).removeCurrentSnackBar();
        Scaffold.of(context).showSnackBar(snack);
      },
      child: CheckboxListTile(
        title: Text(item['title']),
        value: item['done'],
        secondary: CircleAvatar(
          child: Icon(item['done'] ? Icons.check : Icons.error),
        ),
        onChanged: (value) {
          setState(() {
            item['done'] = value;
          });
          _saveFile();
        },
      ),
    );
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if (a['done'] && !b['done'])
          return 1;
        else if (!a['done'] && b['done'])
          return -1;
        else
          return 0;
      });
    });

    _saveFile();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _readData().then((value) {
      print(value);
      setState(() {
        _todoList = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                    controller: _textController,
                    onSubmitted: (String _t) => _addItem(),
                  ),
                ),
                Container(
                  height: 48,
                  padding: EdgeInsets.only(left: 8),
                  margin: EdgeInsets.only(top: 12),
                  child: RaisedButton(
                    onPressed: _addItem,
                    child: Text('ADD'),
                    textColor: Colors.white,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _todoList.length,
                itemBuilder: _buildItem,
              ),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
    );
  }
}
