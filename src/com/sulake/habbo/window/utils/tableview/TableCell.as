package com.sulake.habbo.window.utils.tableview
{
    public class TableCell
    {
        public static const TYPE_TEXT:int = 0;
        public static const TYPE_LINK:int = 1;

        private var _type:int;
        private var _contents:Object;
        private var _isInspectable:Boolean;
        private var _isEditable:Boolean;
        private var _textFieldValue:String;
        private var _linkClickCallback:Function;
        private var _highlightOnChange:Boolean;
        private var _tooltipText:String;
        private var _textColor:uint;
        private var _extraBtn:String;
        private var _extraBtnCallback:Function;

        public function TableCell(type:int, contents:Object, isEditable:Boolean=false, isInspectable:Boolean=false, textFieldValue:String=null, linkClickCallback:Function=null, highlightOnChange:Boolean=false, tooltipText:String=null, textColor:uint=0)
        {
            this._type = type;
            this._contents = contents;
            this._isEditable = isEditable;
            this._isInspectable = isInspectable;
            this._linkClickCallback = linkClickCallback;
            if ((textFieldValue == null) && ((isEditable) || (isInspectable)))
            {
                textFieldValue = (contents as String);
            }
            this._textFieldValue = textFieldValue;
            this._highlightOnChange = highlightOnChange;
            this._tooltipText = tooltipText;
            this._textColor = textColor;
        }

        public function get type():int
        {
            return this._type;
        }

        public function get contents():Object
        {
            return this._contents;
        }

        public function get isEditable():Boolean
        {
            return this._isEditable;
        }

        public function get isInspectable():Boolean
        {
            return this._isInspectable;
        }

        public function get textFieldValue():String
        {
            return this._textFieldValue;
        }

        public function get linkClickCallback():Function
        {
            return this._linkClickCallback;
        }

        public function get highlightOnChange():Boolean
        {
            return this._highlightOnChange;
        }

        public function get tooltipText():String
        {
            return this._tooltipText;
        }

        public function get textColor():uint
        {
            return this._textColor;
        }

        public function setExtraBtn(assetUri:String, callback:Function):void
        {
            this._extraBtn = assetUri;
            this._extraBtnCallback = callback;
        }

        public function get extraBtn():String
        {
            return this._extraBtn;
        }

        public function get extraBtnCallback():Function
        {
            return this._extraBtnCallback;
        }
    }
}
