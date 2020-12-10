import 'package:flutter/material.dart';
import 'package:papercups_flutter/models/message.dart';
import 'package:papercups_flutter/utils/joinConversation.dart';
import '../models/conversation.dart';
import '../models/customer.dart';
import '../utils/getConversationDetails.dart';
import '../utils/getCustomerDetails.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../models/classes.dart';

class SendMessage extends StatefulWidget {
  SendMessage({
    Key key,
    this.customer,
    this.setCustomer,
    this.setConversation,
    this.conversationChannel,
    this.setConversationChannel,
    this.conversation,
    this.socket,
    this.setState,
    this.messages,
    this.sending,
    @required this.props,
  }) : super(key: key);

  final Props props;
  final PapercupsCustomer customer;
  final Function setCustomer;
  final Function setState;
  final Function setConversation;
  final Function setConversationChannel;
  final PhoenixChannel conversationChannel;
  final Conversation conversation;
  final PhoenixSocket socket;
  final List<PapercupsMessage> messages;
  final bool sending;

  @override
  _SendMessageState createState() => _SendMessageState();
}

class _SendMessageState extends State<SendMessage> {
  final _msgController = TextEditingController();

  final _msgFocusNode = FocusNode();

  @override
  void dispose() {
    _msgController.dispose();
    _msgFocusNode.dispose();
    super.dispose();
  }

  void triggerSend() {
    _sendMessage(
      _msgFocusNode,
      _msgController,
      widget.customer,
      widget.props,
      widget.setCustomer,
      widget.conversation,
      widget.setConversation,
      widget.setConversationChannel,
      widget.conversationChannel,
      widget.socket,
      widget.setState,
      widget.messages,
      widget.sending,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 55,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: widget.props.newMessagePlaceholder,
                  hintStyle: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (_) => triggerSend(),
                controller: _msgController,
                focusNode: _msgFocusNode,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: widget.props.primaryColor,
                shape: const CircleBorder(),
                //padding: const EdgeInsets.all(12),
              ),
              child: Container(
                height: 36,
                width: 36,
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              onPressed: triggerSend,
            )
          ],
        ),
      ),
    );
  }
}

void _sendMessage(
  FocusNode fn,
  TextEditingController tc,
  PapercupsCustomer cu,
  Props p,
  Function setCust,
  Conversation conv,
  Function setConv,
  Function setConvChannel,
  PhoenixChannel conversationChannel,
  PhoenixSocket socket,
  Function setState,
  List<PapercupsMessage> messages,
  bool sending,
) {
  final text = tc.text;
  fn.requestFocus();
  if (text.trim().isEmpty || text == null) return null;
  tc.clear();

  setState(() {
    messages.add(
      PapercupsMessage(
        body: text,
        createdAt: DateTime.now(),
        customer: PapercupsCustomer(),
      ),
    );
  }, stateMsg: true);

  if (conversationChannel == null) {
    getCustomerDetails(p, cu, setCust).then(
      (customerDetails) {
        setCust(customerDetails);
        getConversationDetails(p, conv, customerDetails, setConv).then(
          (conversationDetails) {
            var conv = joinConversationAndListen(
              messages: messages,
              convId: conversationDetails.id,
              conversation: conversationChannel,
              socket: socket,
              setState: setState,
              setChannel: setConvChannel,
            );
            conv.push(
              "shout",
              {
                "body": text,
                "customer_id": customerDetails.id,
                "sent_at": DateTime.now().toUtc().toIso8601String(),
              },
            );
            setState(() {});
          },
        );
      },
    );
  } else {
    conversationChannel.push(
      "shout",
      {
        "body": text,
        "customer_id": cu.id,
        "sent_at": DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
