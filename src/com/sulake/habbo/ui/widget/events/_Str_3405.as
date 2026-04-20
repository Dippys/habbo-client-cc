package com.sulake.habbo.ui.widget.events
{
    public class _Str_3405
    {
        private var _id:int;
        private var _category:int;
        private var _name:String;
        private var _owner:String;
        private var _type:int;
        private var _lowerCaseName:String;

        public function _Str_3405(k:int, _arg_2:int, _arg_3:String, _arg_4:String="", _arg_5:int=0)
        {
            this._id = k;
            this._category = _arg_2;
            this._name = ((_arg_3 != null) ? _arg_3 : "");
            this._owner = ((_arg_4 != null) ? _arg_4 : "");
            this._type = _arg_5;
            this._lowerCaseName = this._name.toLowerCase();
        }

        public function get id():int
        {
            return this._id;
        }

        public function get category():int
        {
            return this._category;
        }

        public function get name():String
        {
            return this._name;
        }

        public function get owner():String
        {
            return this._owner;
        }

        public function get type():int
        {
            return this._type;
        }

        public function get lowerCaseName():String
        {
            return this._lowerCaseName;
        }
    }
}
