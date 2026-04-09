package com.sulake.habbo.inventory
{
    import flash.display.BitmapData;

    public interface IThumbListDrawableItem 
    {
        function set icon(_arg_1:BitmapData):void;
        function get icon():BitmapData;
        function set Selected(_arg_1:Boolean):void;
        function get Selected():Boolean;
    }
}
