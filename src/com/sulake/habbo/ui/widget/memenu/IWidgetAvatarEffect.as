package com.sulake.habbo.ui.widget.memenu
{
    import flash.display.BitmapData;

    public interface IWidgetAvatarEffect 
    {
        function get amount():int;
        function get type():int;
        function get secondsRemaining():int;
        function get duration():int;
        function get isActive():Boolean;
        function get isInUse():Boolean;
        function get icon():BitmapData;
    }
}
