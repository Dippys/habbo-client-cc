package com.sulake.habbo.ui.widget.chooser
{
    import com.sulake.habbo.ui.widget.events._Str_3405;
    import com.sulake.habbo.window.utils.tableview.ITableObject;
    import com.sulake.habbo.window.utils.tableview.TableCell;

    public class UserChooserTableObject implements ITableObject
    {
        private var _item:_Str_3405;

        public function UserChooserTableObject(item:_Str_3405)
        {
            this._item = item;
        }

        public function get chooserItem():_Str_3405
        {
            return this._item;
        }

        public function get identifier():String
        {
            return (this._item.category + "-" + this._item.id);
        }

        public function getTableCell(columnId:String):TableCell
        {
            switch (columnId)
            {
                case UserChooserView.COLUMN_USER_NAME:
                    return new TableCell(TableCell.TYPE_TEXT, this._item.name, false, true);
                case UserChooserView.COLUMN_TYPE:
                    return new TableCell(TableCell.TYPE_TEXT, ("${new_user_chooser.usertype." + this._item.type) + "}");
                default:
                    return null;
            }
        }

        public function isPropertyUpdated(columnId:String, previous:Object):Boolean
        {
            return false;
        }

        public function isUpdated(previous:Object):Boolean
        {
            return false;
        }
    }
}
