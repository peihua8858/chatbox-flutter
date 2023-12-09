import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:chatbox_flutter/data/entry.dart';
import 'package:flutter/material.dart';

class _SinglePickerWidgetState extends State<SinglePickerWidget> {
  int _selectIndex = 0;
  FixedExtentScrollController? scrollController;
  LinkedHashMap values = LinkedHashMap();
  var value;
  Duration durationTime = const Duration(minutes: 300);
  var timer;
  List<EntryBean> datas = [];

  @override
  void initState() {
    super.initState();
    values = widget.optionsMap;
    value = widget.value;
    initDatas();
    getDefaultValue();
    scrollController = FixedExtentScrollController(initialItem: _selectIndex);
  }

  @override
  void dispose() {
    super.dispose();
    scrollController?.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CupertinoPageScaffold(
        backgroundColor: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [_buildPicker(context)],
        ),
      ),
    );
  }

  void _changed(index) {
    timer?.cancel();
    timer = Timer(durationTime, () {
      widget.onChanged(index);
    });
  }

  void initDatas() {
    final values = this.values;
    datas = [];
    var keys = values.keys;
    for (var key in keys) {
      final value = values[key];
      datas.add(EntryBean(key, value));
    }
  }

  void getDefaultValue() {
    int count = datas.length;
    for (var i = 0; i < count; i++) {
      if (datas[i].key == value) {
        setState(() {
          _selectIndex = i;
        });
        break;
      }
    }
  }
  // 中间分割线
  Widget _selectionOverlayWidget(){
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0),
      child: Column(
        children: [
          const Divider(
            height: 1,
            color: Colors.grey,
          ),
          Expanded(child: Container()),
          const Divider(
            height: 1,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
  Widget _buildPicker(BuildContext context) {
    return Container(
      height: widget.height,
      width: 800,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.unit != null
              ? Positioned(
              top: widget.height / 2 - (widget.itemHeight / 2),
              left: widget.width / 2 + 18.0,
              child: Container(
                alignment: Alignment.center,
                height: widget.itemHeight,
                child: Text(
                  widget.unit!,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      height: 1.5,
                      fontWeight: FontWeight.w500),
                ),
              ))
              : const Offstage(
            offstage: true,
          ),
          CupertinoPicker(
              useMagnifier: true,
              magnification: 1.2,
              selectionOverlay: _selectionOverlayWidget(),
              itemExtent: widget.itemHeight,
              onSelectedItemChanged: (index) {
                _changed(datas[index].key);
              },
              children: List<Widget>.generate(datas.length, (index) {
                return Container(
                  alignment: Alignment.center,
                  height: widget.itemHeight,
                  child: Text(
                    datas[index].value.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 21.0,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }))
        ],
      ),
    );
  }
}

///
/// 单选列表
class SinglePickerWidget<K, V> extends StatefulWidget {
  final LinkedHashMap<K, V> optionsMap;
  final value;
  final double itemHeight;
  final double height;
  final double width;
  final String? unit;
  final Function onChanged;

  const SinglePickerWidget(
      {super.key,
        required this.optionsMap,
        required this.onChanged,
        required this.value,
        this.unit,
        this.itemHeight = 37.5,
        this.height = 150.0,
        this.width = 150.0})
      : super();

  @override
  State<StatefulWidget> createState() => _SinglePickerWidgetState();
}
