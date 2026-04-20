package com.sulake.habbo.ui.widget.messages
{
    public class RoomWidgetRequestWidgetMessage extends RoomWidgetMessage 
    {
        public static const RWRWM_USER_CHOOSER:String = "RWRWM_USER_CHOOSER";
        public static const RWRWM_FURNI_CHOOSER:String = "RWRWM_FURNI_CHOOSER";
        public static const RWRWM_FURNI_CHOOSER_ADD:String = "RWRWM_FURNI_CHOOSER_ADD";
        public static const RWRWM_ME_MENU:String = "RWRWM_ME_MENU";
        public static const RWRWM_EFFECTS:String = "RWRWM_EFFECTS";

        private var _id:int;
        private var _category:int;

        public function RoomWidgetRequestWidgetMessage(k:String, _arg_2:int=-1, _arg_3:int=-1)
        {
            super(k);
            this._id = _arg_2;
            this._category = _arg_3;
        }

        public function get id():int
        {
            return this._id;
        }

        public function get category():int
        {
            return this._category;
        }
    }
}
