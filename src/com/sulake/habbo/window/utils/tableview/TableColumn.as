package com.sulake.habbo.window.utils.tableview
{
    public class TableColumn
    {
        private var _id:String;
        private var _columnName:String;
        private var _widthFactor:Number;
        private var _alignment:String;

        public function TableColumn(id:String, columnName:String, widthFactor:Number, alignment:String="center")
        {
            this._id = id;
            this._columnName = columnName;
            this._widthFactor = widthFactor;
            if (alignment == "left")
            {
                alignment = "none";
            }
            this._alignment = alignment;
        }

        public function get id():String
        {
            return this._id;
        }

        public function get columnName():String
        {
            return this._columnName;
        }

        public function get widthFactor():Number
        {
            return this._widthFactor;
        }

        public function get alignment():String
        {
            return this._alignment;
        }
    }
}
