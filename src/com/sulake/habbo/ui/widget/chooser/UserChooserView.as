package com.sulake.habbo.ui.widget.chooser
{
    import com.sulake.core.assets.XmlAsset;
    import com.sulake.core.window.IWindow;
    import com.sulake.core.window.IWindowContainer;
    import com.sulake.core.window.components.IDropMenuWindow;
    import com.sulake.core.window.components.IFrameWindow;
    import com.sulake.core.window.components.ITextFieldWindow;
    import com.sulake.core.window.components.ITextWindow;
    import com.sulake.core.window.events.WindowEvent;
    import com.sulake.core.window.events.WindowMouseEvent;
    import com.sulake.habbo.ui.widget.events._Str_3405;
    import com.sulake.habbo.window.utils.tableview.ITableObject;
    import com.sulake.habbo.window.utils.tableview.TableColumn;
    import com.sulake.habbo.window.utils.tableview.TableView;

    public class UserChooserView
    {
        public static const COLUMN_USER_NAME:String = "name";
        public static const COLUMN_TYPE:String = "type";

        private var _widget:UserChooserWidget;
        private var _title:String;
        private var _tableView:TableView;
        private var _window:IFrameWindow;
        private var _ignoreListeners:Boolean;

        public function UserChooserView(widget:UserChooserWidget, title:String)
        {
            this._widget = widget;
            this._title = title;
        }

        public function dispose():void
        {
            this.hideWindow();
            this._widget = null;
        }

        public function isOpen():Boolean
        {
            return ((this._window != null) && (this._window.visible));
        }

        public function onItemsChanged():void
        {
            if (this._widget == null)
            {
                return;
            }
            if (this._window == null)
            {
                this.createWindow();
            }
            this.populateWithFilters();
        }

        private function createWindow():void
        {
            var asset:XmlAsset = (XmlAsset(this._widget.assets.getAssetByName("new_user_chooser_view")));
            if (asset == null)
            {
                return;
            }
            this._window = (this._widget.windowManager.buildFromXML((asset.content as XML)) as IFrameWindow);
            if (this._window == null)
            {
                return;
            }
            this._window.caption = this._title;
            this.createTable();
            this.closeButton.addEventListener(WindowMouseEvent.CLICK, this.onClose);
            this.searchTextInput.addEventListener(WindowEvent.WINDOW_EVENT_CHANGE, this.onSearchChanged);
            this.typeDropdown.addEventListener(WindowEvent.WINDOW_EVENT_SELECTED, this.onTypeChanged);
            this.clearButton.addEventListener(WindowMouseEvent.CLICK, this.onClearClicked);
            if (this._window.parent != null)
            {
                this._window.x = ((this._window.parent.width - this._window.width) - 10);
                this._window.y = 10;
            }
        }

        private function createTable():void
        {
            var cols:Array;
            this._tableView = new TableView(this._widget.windowManager, this.tableViewContainer, true, true, (XmlAsset(this._widget.assets.getAssetByName("table_view_xml"))));
            cols = [
                new TableColumn(COLUMN_USER_NAME, this.localize("new_user_chooser.col.name"), 0.65, "left"),
                new TableColumn(COLUMN_TYPE, this.localize("new_user_chooser.col.type"), 0.35, "left")
            ];
            this._tableView.initialize(Vector.<TableColumn>(cols), true, true);
            this._tableView.onRowClickedCallback = this.onListItemClicked;
        }

        private function populateWithFilters():void
        {
            var filtered:Array;
            var objects:Vector.<ITableObject>;
            var item:_Str_3405;
            var selectedType:int;
            var searchValue:String;

            if ((this._window == null) || (this._widget.items == null))
            {
                return;
            }

            searchValue = this.searchTextInput.text.toLowerCase();
            selectedType = this.typeDropdown.selection;
            if (selectedType == 3)
            {
                selectedType = 4;
            }

            filtered = [];
            for each (item in this._widget.items)
            {
                if (((searchValue.length > 0) && (item.lowerCaseName.indexOf(searchValue) == -1)))
                {
                    continue;
                }
                if (((selectedType > 0) && (item.type != selectedType)))
                {
                    continue;
                }
                filtered.push(item);
            }

            objects = new Vector.<ITableObject>();
            for each (item in filtered)
            {
                objects.push(new UserChooserTableObject(item));
            }
            this._tableView.setObjects(objects);
            this.amountIndicator.text = this._widget.localizations.getLocalizationWithParams("new_user_chooser.amount_indicator", "", "amount", filtered.length);
        }

        private function onListItemClicked(row:UserChooserTableObject):void
        {
            var item:_Str_3405;
            if (row == null)
            {
                return;
            }
            item = row.chooserItem;
            if (item == null)
            {
                return;
            }
            this._widget.choose(item.id, item.category);
        }

        private function onSearchChanged(k:WindowEvent):void
        {
            var txt:String;
            if (this._ignoreListeners)
            {
                return;
            }
            txt = this.searchTextInput.text;
            this.clearButton.visible = txt.length > 0;
            this.textPlaceholder.visible = txt.length == 0;
            this.populateWithFilters();
        }

        private function onTypeChanged(k:WindowEvent):void
        {
            if (this._ignoreListeners)
            {
                return;
            }
            this.populateWithFilters();
        }

        private function onClearClicked(k:WindowMouseEvent):void
        {
            if (this._ignoreListeners)
            {
                return;
            }
            this.searchTextInput.text = "";
            this.onSearchChanged(null);
        }

        private function onClose(k:WindowMouseEvent):void
        {
            this.hideWindow();
        }

        private function hideWindow():void
        {
            if (this._window != null)
            {
                if (this._tableView != null)
                {
                    this._tableView.dispose();
                    this._tableView = null;
                }
                this._window.dispose();
                this._window = null;
            }
        }

        private function localize(key:String):String
        {
            return this._widget.localizations.getLocalization(key, key);
        }

        private function get closeButton():IWindow
        {
            return this._window.findChildByTag("close");
        }

        private function get tableViewContainer():IWindowContainer
        {
            return (this._window.findChildByName("table_container") as IWindowContainer);
        }

        private function get textPlaceholder():ITextWindow
        {
            return (this._window.findChildByName("search_placeholder") as ITextWindow);
        }

        private function get searchTextInput():ITextFieldWindow
        {
            return (this._window.findChildByName("text_input") as ITextFieldWindow);
        }

        private function get typeDropdown():IDropMenuWindow
        {
            return (this._window.findChildByName("type_dropdown") as IDropMenuWindow);
        }

        private function get clearButton():IWindowContainer
        {
            return (this._window.findChildByName("clear_button") as IWindowContainer);
        }

        private function get amountIndicator():ITextWindow
        {
            return (this._window.findChildByName("amount_indicator") as ITextWindow);
        }
    }
}
