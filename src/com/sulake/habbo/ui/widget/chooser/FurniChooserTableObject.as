package com.sulake.habbo.ui.widget.chooser
{
    import com.sulake.habbo.ui.widget.events._Str_3405;
    import com.sulake.habbo.utils.BuildersClubTools;
    import com.sulake.habbo.window.utils.tableview.ITableObject;
    import com.sulake.habbo.window.utils.tableview.TableCell;

    public class FurniChooserTableObject implements ITableObject
    {
        private var _item:_Str_3405;

        public function FurniChooserTableObject(item:_Str_3405)
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
                case FurniChooserView.COLUMN_FURNI_NAME:
                    return new TableCell(TableCell.TYPE_TEXT, this._item.name, false, true);
                case FurniChooserView.COLUMN_FURNI_OWNER:
                    if (BuildersClubTools.isBuildersClubFurniture(this._item.id))
                    {
                        return new TableCell(TableCell.TYPE_TEXT, "-", false, true);
                    }
                    if ((this._item.owner == null) || (this._item.owner.length == 0))
                    {
                        return new TableCell(TableCell.TYPE_TEXT, "-");
                    }
                    return new TableCell(TableCell.TYPE_TEXT, this._item.owner, false, true);
                case FurniChooserView.COLUMN_ID:
                    return new TableCell(TableCell.TYPE_TEXT, (this._item.id + ""), false, true);
                default:
                    return null;
            }
        }

        public function isPropertyUpdated(columnId:String, previous:Object):Boolean
        {
            return true;
        }

        public function isUpdated(previous:Object):Boolean
        {
            return true;
        }
    }
}
