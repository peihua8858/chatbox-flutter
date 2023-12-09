import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/chat_box_localizations.dart';

import '../../data/entry.dart';
import '../../widgets/CommWidget.dart';

void showSettingsOptionsDialog<K, V>(
    {required BuildContext context,
      required LinkedHashMap<K, V> optionsMap,
      required selectOptions,
      required Function onChanged}) {
  List<EntryBean> datas = [];
  var keys = optionsMap.keys;
  for (var key in keys) {
    final value = optionsMap[key];
    datas.add(EntryBean(key, value));
  }
  showDialog<void>(
    context: context,
    builder: (context) {
      return SettingsOptionsDialog(
        datas: datas,
        selectOptions: selectOptions,
        onChanged: onChanged,
      );
    },
  );
}

class SettingsOptionsDialog extends StatefulWidget {
  final List<EntryBean> datas;
  var selectOptions;
  final Function onChanged;

  SettingsOptionsDialog({
    super.key,
    required this.datas,
    required this.selectOptions,
    required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => _SttingsOptionsDialogState();
}

class _SttingsOptionsDialogState extends State<SettingsOptionsDialog> {
  var selectOptions;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this.selectOptions = widget.selectOptions;
  }

  @override
  Widget build(BuildContext context) {
    final local = ChatBoxLocalizations.of(context)!;
    final themes = Theme.of(context);
    final colorScheme = themes.colorScheme;
    final textTheme = themes.textTheme;
    return AlertDialog(
        title: Text(
          local.please_select_an_item,
          style: textTheme.titleLarge,
        ),
        backgroundColor: colorScheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: SizedBox(
            width: double.maxFinite,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.datas.length,
                      itemBuilder: (context, index) {
                        return Container(
                          alignment: Alignment.center,
                          child: RadioListTile(
                            selected: true,
                            title: Text(
                              widget.datas[index].value.toString(),
                              style: textTheme.bodyMedium,
                            ),
                            value: widget.datas[index].key,
                            groupValue: selectOptions,
                            onChanged: (value) {
                              print("》》》》selItem:$selectOptions, value:$value");
                              setState(() {
                                selectOptions = value;
                              });
                            },
                          ),
                        );
                      }),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CommWidget.buttonWidget(
                          title: local.dialogCancel,
                          textStyle: textTheme.titleLarge,
                          callback: () {
                            Navigator.of(context).pop();
                          }),
                      Expanded(child: Container()),
                      CommWidget.buttonWidget(
                          title: local.sure,
                          textStyle: textTheme.titleLarge,
                          callback: () {
                            widget.onChanged(selectOptions);
                            Navigator.of(context).pop();
                          })
                    ],
                  )
                ])));
  }
}
