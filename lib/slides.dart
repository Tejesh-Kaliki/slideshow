import 'package:flutter/material.dart';

import 'my_painter.dart';

class CreateSlideShowPage extends StatefulWidget {
  @override
  _CreateSlideShowPageState createState() => _CreateSlideShowPageState();
}

class _CreateSlideShowPageState extends State<CreateSlideShowPage> {
  List<Sentence> sentences = [];
  int current = 0;
  TextEditingController _controller, _textEditingController;

  void getName() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          title: Text("Enter name"),
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textEditingController,
                textAlignVertical: TextAlignVertical.bottom,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              mainAxisSize: MainAxisSize.max,
              children: [
                MaterialButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                MaterialButton(
                  child: Text("Save"),
                  onPressed: () {
                    String name = _textEditingController.value.text;
                    Navigator.of(context, rootNavigator: true).pop();
                    MyPainter.saveAsPicture(sentences, name);
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (current < sentences.length)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                sentences.removeAt(current);
                _controller.clear();
                current = sentences.length;
                setState(() {});
              },
            ),
          MaterialButton(
            child: Text(
              "SAVE",
              style:
                  TextStyle(fontFamily: "EuclidCircularA", color: Colors.white),
            ),
            onPressed: getName,
          )
        ],
      ),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CustomPaint(
                painter: MyPainter(sentences),
              ),
            ),
          ),
          Expanded(child: Container()),
          Container(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: sentences.length + 1,
              itemBuilder: (context, i) {
                return Padding(
                  padding: EdgeInsets.all(4),
                  child: MaterialButton(
                    color: current == i ? Colors.green[100] : Colors.red[100],
                    child: Center(child: Text("$i")),
                    onPressed: () {
                      current = i;
                      if (i < sentences.length)
                        _controller.text = sentences[i].rawSentence;
                      else
                        _controller.text = "";
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      hintText: "Add text..",
                      hintStyle: TextStyle(
                        fontFamily: "EuclidCircularA",
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      fillColor: Colors.white,
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: "EuclidCircularA",
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.left,
                    maxLines: null,
                    onChanged: (text) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.length > 0) {
                      if (current == sentences.length)
                        sentences.add(Sentence.parseFrom(_controller.text));
                      else
                        sentences.replaceRange(current, current + 1,
                            [Sentence.parseFrom(_controller.text)]);
                      current = sentences.length;
                      _controller.clear();
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
