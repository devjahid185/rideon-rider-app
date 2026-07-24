import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ride_on/core/services/data_store.dart';
import 'package:ride_on/core/utils/common_widget.dart';
import 'package:ride_on/core/utils/theme/project_color.dart';
import 'package:ride_on/core/utils/theme/theme_style.dart';
import 'package:ride_on/core/utils/translate.dart';
import 'package:ride_on/presentation/cubits/realtime/get_ride_request_status_cubit.dart';
import 'package:ride_on/presentation/screens/search/send_ride_request_screen.dart';

class RideChatScreen extends StatefulWidget {
  final String rideId;
  final String driverImage;
  final String driverName;

  final String myId;
  final String myType; // "driver" or "user"

  const RideChatScreen({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.driverImage,
    required this.myId,
    required this.myType,
  });

  @override
  State<RideChatScreen> createState() => _RideChatScreenState();
}

class _RideChatScreenState extends State<RideChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  bool _showSuggestions = true;

  final List<String> _messageSuggestions = [
    "I'm ready, please pick me up",
    "Waiting at pickup point",
    "Can you share your location?",
    "I see your car",
    "Please honk when you arrive",
    "Heading to pickup now",
    "Thanks for picking me up!",
  ];

  @override
  void initState() {
    super.initState();
    markMessagesAsSeen(widget.rideId, widget.myId);

    focusNode.addListener(() {
      if (focusNode.hasFocus && _showSuggestions) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void sendMessage(String msg) {
    if (msg.trim().isEmpty) return;

    // sendChatMessage(
    //   rideId: widget.rideId,
    //   senderId: widget.myId,
    //   senderType: widget.myType,
    //   message: msg.trim(),
    // );

    messageController.clear();
    _scrollToBottom();
  }

  void sendSuggestion(String msg) {
    sendMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        elevation: 0.3,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: appgreen,
              child: ClipOval(
                child: myNetworkImage(widget.driverImage),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.driverName, style: heading3Grey1(context)),
                Text(
                  "Active Ride".translate(context),
                  style: regular(context).copyWith(
                    fontSize: 11,
                    color: appgreen
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: BlocListener<GetRideRequestStatusCubit, String>(
  listener: (context, status) {
    if (status == "rejected") {
      box.delete("rideId");
      showDriverCancelledRideDialog(context);
      return;
    }
  },
  child: Column(
    children: [
      Expanded(
        child: StreamBuilder(
          stream: FirebaseDatabase.instance
              .ref("ride_requests/${widget.rideId}/chat/messages")
              .orderByChild("timestamp")
              .onValue,
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.data!.snapshot.value == null) {
              return const Center(
                child: Text("Start the conversation ðŸ‘‹"),
              );
            }

            Map data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            List messages = data.entries
                .map((e) => {"id": e.key, ...e.value})
                .toList();

            messages.sort(
              (a, b) => a["timestamp"].compareTo(b["timestamp"]),
            );

            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final bool isMe = msg["senderId"] == widget.myId;

                return _chatBubble(
                  msg,
                  isMe,
                  index == messages.length - 1,
                );
              },
            );
          },
        ),
      ),

      // Quick Suggestions
      if (_showSuggestions) _quickReplies(),

      // Input Bar
      _buildInputBar(),
    ],
  ),
) 
,
    );
  }

  Widget _quickReplies() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _messageSuggestions.map((msg) {
            return GestureDetector(
              onTap: () => sendSuggestion(msg),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: greentext.withValues(alpha: .3),
                  ),
                ),
                child: Text(
                  msg,
                  style: TextStyle(
                      fontSize: 12,
                      color: appgreen,
                      fontWeight: FontWeight.w500),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _chatBubble(dynamic msg, bool isMe, bool isLast) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFD7E7FF) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg["message"],
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg["timestamp"]),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (isMe && isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      msg["seen"] == true ? Icons.done_all : Icons.check,
                      size: 12,
                      color: msg["seen"] == true ? Colors.blue : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20,right: 20,bottom: 30,top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
           
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: messageController,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type a message...",
                  hintStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                onSubmitted: (_) => sendMessage(messageController.text),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: (){
              sendMessage(messageController.text);
            } ,
            child: Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: appgreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }
}

// MARK AS SEEN
Future<void> markMessagesAsSeen(String rideId, String myId) async {
  final messagesRef =
      FirebaseDatabase.instance.ref("ride_requests/$rideId/chat/messages");

  messagesRef.once().then((snapshot) {
    if (snapshot.snapshot.value == null) return;

    Map<dynamic, dynamic> messages = snapshot.snapshot.value as Map;

    messages.forEach((key, value) {
      if (value["senderId"] != myId) {
        messagesRef.child(key).update({"seen": true});
      }
    });
  });
}





