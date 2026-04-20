package com.sulake.habbo.window.utils.tableview
{
    public interface ITableObject
    {
        function get identifier():String;
        function getTableCell(columnId:String):TableCell;
        function isPropertyUpdated(columnId:String, previous:Object):Boolean;
        function isUpdated(previous:Object):Boolean;
    }
}
