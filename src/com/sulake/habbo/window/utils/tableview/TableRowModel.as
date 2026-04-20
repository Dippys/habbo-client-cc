package com.sulake.habbo.window.utils.tableview
{
    import com.sulake.core.runtime.IDisposable;

    public class TableRowModel implements IDisposable
    {
        private var _disposed:Boolean = false;
        private var _object:ITableObject;
        private var _index:int;
        private var _selected:Boolean = false;
        private var _hovered:Boolean = false;
        private var _hasFocus:Boolean = false;
        private var _view:TableRowView;

        public function TableRowModel(obj:ITableObject, index:int)
        {
            this._object = obj;
            this._index = index;
        }

        public function set index(value:int):void
        {
            this._index = value;
            if (this._view != null)
            {
                this._view.indexUpdated();
            }
        }

        public function update(obj:ITableObject):void
        {
            if (!(obj.isUpdated(this._object)))
            {
                this._object = obj;
                return;
            }
            var previous:ITableObject = this._object;
            this._object = obj;
            if (this._view != null)
            {
                this._view.objectUpdated(previous, obj);
            }
        }

        public function set hasFocus(value:Boolean):void
        {
            this._hasFocus = value;
        }

        public function set selected(value:Boolean):void
        {
            this._selected = value;
            if (this._view != null)
            {
                this._view.selectedUpdated();
            }
        }

        public function set hovered(value:Boolean):void
        {
            this._hovered = value;
            if (this._view != null)
            {
                this._view.hoveredUpdated();
            }
        }

        public function set view(value:TableRowView):void
        {
            this._view = value;
        }

        public function get object():ITableObject
        {
            return this._object;
        }

        public function get i():int
        {
            return this._index;
        }

        public function get selected():Boolean
        {
            return this._selected;
        }

        public function get hovered():Boolean
        {
            return this._hovered;
        }

        public function get hasFocus():Boolean
        {
            return this._hasFocus;
        }

        public function get view():TableRowView
        {
            return this._view;
        }

        public function dispose():void
        {
            if (this._disposed)
            {
                return;
            }
            this._object = null;
            if (this._view != null)
            {
                this._view.dispose();
                this._view = null;
            }
            this._disposed = true;
        }

        public function get disposed():Boolean
        {
            return this._disposed;
        }
    }
}
