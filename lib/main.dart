// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import 'type_meme.dart';
import 'platform_adaptive.dart';

const _name = 'Simon';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memechat',
      home: Container(color: Colors.black),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  List<ChatMessage> _messages = [];
  DatabaseReference _messagesReference = FirebaseDatabase.instance.reference();
  TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  var fireBaseSubscription;

  @override
  void initState() {
    super.initState();
    _googleSignIn.signInSilently();
  }

  @override
  void dispose() {
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }
    fireBaseSubscription.cancel();
    super.dispose();
  }

  void _handleMessageChanged(String text) {
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  void _handleSubmitted(String text) {}

  void _addMessage(
      {String name,
      String text,
      String imageUrl,
      String textOverlay,
      String senderImageUrl}) {
    var animationController;
    var sender = ChatUser(name: name, imageUrl: senderImageUrl);
    var message = ChatMessage(
      sender: sender,
      text: text,
      imageUrl: imageUrl,
      textOverlay: textOverlay,
    );
    if (imageUrl != null) {
      NetworkImage image = NetworkImage(imageUrl);
      image
          .resolve(createLocalImageConfiguration(context))
          .addListener((_, __) {
        animationController?.forward();
      });
    } else {
      animationController?.forward();
    }
  }

  Future<Null> _handlePhotoButtonPressed() async {}

  Widget _buildTextComposer() {
    return IconTheme(
        data: IconThemeData(color: Theme.of(context).accentColor),
        child: PlatformAdaptiveContainer(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
              ),
              Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  child: PlatformAdaptiveButton(
                    icon: Icon(Icons.send),
                    onPressed: _isComposing
                        ? () => _handleSubmitted(_textController.text)
                        : null,
                    child: Text('Send'),
                  )),
            ])));
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PlatformAdaptiveAppBar(
          title: Text('Memechat'),
          platform: Theme.of(context).platform,
        ),
        body: Column(children: [
          Flexible(
              child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            reverse: true,
            itemBuilder: (_, int index) =>
                ChatMessageListItem(_messages[index]),
            itemCount: _messages.length,
          )),
          Divider(height: 1.0),
          Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer()),
        ]));
  }
}

class ChatUser {
  ChatUser({this.name, this.imageUrl});

  final String name;
  final String imageUrl;
}

class ChatMessage {
  ChatMessage(
      {this.sender,
      this.text,
      this.imageUrl,
      this.textOverlay,
      this.animationController});

  final ChatUser sender;
  final String text;
  final String imageUrl;
  final String textOverlay;
  final AnimationController animationController;
}

class ChatMessageListItem extends StatelessWidget {
  ChatMessageListItem(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.sender.name,
                  style: Theme.of(context).textTheme.subhead),
              Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: ChatMessageContent(message)),
            ],
          ),
        ],
      ),
//      ),
    );
  }
}

class ChatMessageContent extends StatelessWidget {
  ChatMessageContent(this.message);

  final ChatMessage message;

  Widget build(BuildContext context) {
    if (message.imageUrl != null) {
      var image = Image.network(message.imageUrl, width: 200.0);
      if (message.textOverlay == null) {
        return image;
      } else {
        return Stack(
          alignment: FractionalOffset.topCenter,
          children: [
            image,
            Container(
                alignment: FractionalOffset.topCenter,
                width: 200.0,
                child: Text(message.textOverlay,
                    style: const TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 30.0,
                        color: Colors.white),
                    softWrap: true,
                    textAlign: TextAlign.center)),
          ],
        );
      }
    } else
      return Text(message.text);
  }
}
