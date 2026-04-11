package com.sulake.habbo.inventory
{
    import com.sulake.core.runtime.IDisposable;
    import com.sulake.core.window.IWindowContainer;

    public interface IInventoryModel extends IDisposable 
    {
        function getWindowContainer():IWindowContainer;
        function onInventoryOpen():void;
        function initCategory(_arg_1:String):void;
        function onCategorySwitch(_arg_1:String):void;
        function onInventoryClose():void;
        function updateView():void;
        function onSubcategorySwitch(_arg_1:String):void;
    }
}
