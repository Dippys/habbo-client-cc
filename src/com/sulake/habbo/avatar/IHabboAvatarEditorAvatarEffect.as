package com.sulake.habbo.avatar
{
    import flash.display.BitmapData;

    public interface IHabboAvatarEditorAvatarEffect 
    {
        function get amount():int;
        function get type():int;
        function get subType():int;
        function get secondsRemaining():int;
        function get duration():int;
        function get _Str_4010():Boolean;
        function get isActive():Boolean;
        function get isInUse():Boolean;
        function get icon():BitmapData;
        function set _Str_3093(_arg_1:BitmapData):void;
        function get _Str_3093():BitmapData;
        function set Selected(_arg_1:Boolean):void;
        function get Selected():Boolean;
    }
}
