import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/classes.dart';
import '../models/message.dart';

import '../utils/colorMod.dart';

class ChatMessages extends StatelessWidget {
  final Props props;
  final List<PapercupsMessage> messages;
  final bool sending;
  final ScrollController _controller;

  ChatMessages(this.props, this.messages, this._controller, this.sending,
      {Key key})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topCenter,
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.zero,
        reverse: true,
        shrinkWrap: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ChatMessage(
            msgs: messages.reversed.toList(),
            index: index,
            props: props,
            sending: sending,
            lvKey: key,
          );
        },
      ),
    );
  }
}

class ChatMessage extends StatefulWidget {
  const ChatMessage({
    Key key,
    @required this.msgs,
    @required this.index,
    @required this.props,
    @required this.sending,
    @required this.lvKey,
  }) : super(key: key);

  final List<PapercupsMessage> msgs;
  final int index;
  final Props props;
  final bool sending;
  final GlobalKey lvKey;

  @override
  _ChatMessageState createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  double opacity = 0;
  double maxWidth = 0;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maxWidth = widget.lvKey.currentContext.size.width * 0.65;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (opacity == 0)
      Timer(
          Duration(
            milliseconds: 0,
          ), () {
        setState(() {
          opacity = 1;
        });
      });
    var msg = widget.msgs[widget.index];

    bool userSent = true;
    if (msg.userId != null) userSent = false;

    var text = msg.body;
    var nextMsg = widget.msgs[max(widget.index - 1, 0)];

    return AnimatedOpacity(
      curve: Curves.easeIn,
      duration: Duration(milliseconds: 300),
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                userSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!userSent)
                Padding(
                  padding: EdgeInsets.only(
                    right: 14,
                    left: 14,
                    top: (widget.index == widget.msgs.length - 1) ? 15 : 4,
                  ),
                  child: (nextMsg.userId != msg.userId)
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor: widget.props.primaryColor,
                          backgroundImage: (msg.user.profilePhotoUrl != null)
                              ? NetworkImage(msg.user.profilePhotoUrl)
                              : null,
                          child: (msg.user.profilePhotoUrl != null)
                              ? null
                              : (msg.user != null && msg.user.fullName == null)
                                  ? Text(
                                      msg.user.email
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: Theme.of(context).cardColor),
                                    )
                                  : Text(
                                      msg.user.fullName
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                          color: Theme.of(context).cardColor),
                                    ),
                        )
                      : SizedBox(
                          width: 32,
                        ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: userSent
                      ? widget.props.primaryColor
                      : Theme.of(context).brightness == Brightness.light
                          ? brighten(Theme.of(context).disabledColor, 80)
                          : Color(0xff282828),
                  borderRadius: BorderRadius.circular(4),
                ),
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                margin: EdgeInsets.only(
                  top: (widget.index == widget.msgs.length - 1) ? 15 : 4,
                  bottom: 4,
                  left: userSent ? 18 : 0,
                  right: userSent ? 18 : 0,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 14,
                ),
                child: MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: userSent
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyText1.color,
                    ),
                    a: TextStyle(
                      color: userSent
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyText1.color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!userSent &&
              ((nextMsg.userId != msg.userId) || (widget.index == 0)))
            Padding(
                padding: EdgeInsets.only(left: 16, bottom: 5, top: 4),
                child: (msg.user.fullName == null)
                    ? Text(
                        msg.user.email,
                        style: TextStyle(
                          color:
                              Theme.of(context).disabledColor.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        msg.user.fullName,
                        style: TextStyle(
                          color:
                              Theme.of(context).disabledColor.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      )),
          if (userSent && widget.index == 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 4,
                left: 18,
                right: 18,
              ),
              child: Text(
                widget.sending ? "Sending..." : "Sent",
                textAlign: TextAlign.end,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          if (widget.index == 0 || nextMsg.userId != msg.userId)
            SizedBox(
              height: 10,
            ),
        ],
      ),
    );
  }
}
