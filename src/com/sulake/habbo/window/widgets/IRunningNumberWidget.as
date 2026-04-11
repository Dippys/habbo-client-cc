package com.sulake.habbo.window.widgets
{
    import com.sulake.core.window.IWidget;

    public interface IRunningNumberWidget extends IWidget 
    {
        function get number():int;
        function set number(_arg_1:int):void;
        function set _Str_19520(_arg_1:int):void;
        function get _Str_4056():uint;
        function set _Str_4056(_arg_1:uint):void;
        function get colorStyle():int;
        function set colorStyle(_arg_1:int):void;
        function get updateFrequency():int;
        function set updateFrequency(_arg_1:int):void;
    }
}
