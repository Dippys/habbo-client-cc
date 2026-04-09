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
        function get isPermanent():Boolean;
        function get isActive():Boolean;
        function get isInUse():Boolean;
        function get icon():BitmapData;
        function set icon(_arg_1:BitmapData):void;
        function get icon():BitmapData;
        function set Selected(_arg_1:Boolean):void;
        function get Selected():Boolean;
    }
}
