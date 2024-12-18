import 'dart:convert';
import 'dart:io';

import 'package:chatbox_flutter/pages/settings/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatbox_flutter/layout/adaptive.dart';
import 'package:flutter_gen/gen_l10n/chat_box_localizations.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:chatbox_flutter/widgets/CustomSidebarDrawer.dart';
import 'package:chatbox_flutter/widgets/foldable_sidebar.dart';

class ToggleSplashNotification extends Notification {}

class HomePage extends StatefulWidget
   {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>  with SingleTickerProviderStateMixin{
  List<types.Message> _messages = [];
  late AnimationController _animationController;
  late  Animation<double> _animation;
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animation = Tween<double>(begin: 0, end: 200).animate(_animationController);
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themes = Theme.of(context);
    final textTheme = themes.textTheme;
    final colorScheme = themes.colorScheme;
    final isDesktop = isDisplayDesktop(context);
    final localization = ChatBoxLocalizations.of(context)!;
    final homeTitle = localization.home;
    final drawerItems = ListView(
      children: [
        ListTile(
          title: Text(
            localization.demoNavigationDrawerToPageOne,
          ),
          leading: const Icon(Icons.favorite),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          title: Text(
            localization.demoNavigationDrawerToPageTwo,
          ),
          leading: const Icon(Icons.comment),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
    final appbar=AppBar(
      // TRY THIS: Try changing the color here to a specific color (to
      // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
      // change color while the other colors stay the same.
      backgroundColor: colorScheme.background,
      // Here we take the value from the MyHomePage object that was created by
      // the App.build method, and use it to set our appbar title.
      title: Text(homeTitle, style: themes.appBarTheme.titleTextStyle),
      titleTextStyle: themes.appBarTheme.titleTextStyle,
      iconTheme: themes.appBarTheme.iconTheme,
      actionsIconTheme: themes.appBarTheme.actionsIconTheme,
      actions: [
        IconButton(
            onPressed: () {
              //添加新会话
            },
            icon: const Icon(Icons.add)),
        IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_applications))
      ],
    );
    return Scaffold(
      appBar: appbar,
      drawer: Drawer(
        backgroundColor: colorScheme.background,
        child: drawerItems,
      ),
      // onDrawerChanged: (isOpened){
      //   if (isOpened) {
      //     _animationController.forward();
      //   } else {
      //     _animationController.reverse();
      //   }
      // },
      body:/*AnimatedBuilder(
        animation: _animationController,
        builder: (context, child1) {
          return Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: _animation.value,
                right: -_animation.value,
                child:appbar,
              ),
              Positioned(
                top: 56,
                left: _animation.value ,
                right: -_animation.value,
                bottom: 0,
                child: child1!,
              ),
            ],
          );
        },
        child: Center(
          child: Chat(
            messages: _messages,
            // onAttachmentPressed: _handleAttachmentPressed,
            onMessageTap: _handleMessageTap,
            onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: _user,
            theme: DefaultChatTheme(
              backgroundColor: colorScheme.background,
              seenIcon: Text(
                'read',
                style: textTheme.bodySmall,
              ),
            ),
          ),
        ),
      )*/


      AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_animation.value, 0),
            child: child,
          );
        },
        child: Chat(
          messages: _messages,
          // onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          showUserAvatars: true,
          showUserNames: true,
          user: _user,
          theme: DefaultChatTheme(
            backgroundColor: colorScheme.onPrimaryContainer,
            seenIcon: Text(
              '佩华',
              style: textTheme.bodySmall,
            ),
            inputBackgroundColor: colorScheme.onSecondary,
            inputTextColor: colorScheme.onPrimary
          ),
        ),
      ) ,
    );
  }
}
