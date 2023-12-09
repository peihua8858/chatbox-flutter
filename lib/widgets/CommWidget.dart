
import 'package:flutter/material.dart';

class CommWidget{
  static Widget buttonWidget({required String title ,TextStyle? textStyle ,required VoidCallback callback}){
    return InkWell(
      onTap: callback,
      child: Container(
        alignment: Alignment.center,
        padding:const EdgeInsets.only(left: 16,right: 16),
        height: 40,
        child: Text(title,style: textStyle,),
      ),
    );
  }
}