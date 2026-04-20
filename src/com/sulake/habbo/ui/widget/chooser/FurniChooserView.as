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
    import com.sulake.habbo.utils.BuildersClubTools;
    import com.sulake.habbo.window.utils.tableview.ITableObject;
    import com.sulake.habbo.window.utils.tableview.TableColumn;
    import com.sulake.habbo.window.utils.tableview.TableView;

    public class FurniChooserView
    {
        public static const COLUMN_FURNI_NAME:String = "name";
        public static const COLUMN_FURNI_OWNER:String = "owner";
        public static const COLUMN_ID:String = "id";
        private static const BUILDERS_CLUB_OWNER:String = "Builders Club";

        private var _widget:FurniChooserWidget;
        private var _window:IFrameWindow;
        private var _tableView:TableView;
        private var _ignoreListeners:Boolean;
        private var _owners:Array;

        public function FurniChooserView(widget:FurniChooserWidget)
        {
            this._widget = widget;
            this._owners = [];
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
            this.constructOwners();
            this.populateWithFilters();
        }

        private function createWindow():void
        {
            var asset:XmlAsset = (XmlAsset(this._widget.assets.getAssetByName("new_furni_chooser_view")));
            if (asset == null)
            {
                return;
            }
            this._window = (this._widget.windowManager.buildFromXML((asset.content as XML)) as IFrameWindow);
            if (this._window == null)
            {
                return;
            }
            this._window.caption = "${widget.chooser.furni.title}";
            this.createTable();
            this.closeButton.addEventListener(WindowMouseEvent.CLICK, this.onClose);
            this.searchTextInput.addEventListener(WindowEvent.WINDOW_EVENT_CHANGE, this.onSearchChanged);
            this.usernameDropDown.addEventListener(WindowEvent.WINDOW_EVENT_SELECTED, this.onUsernameChanged);
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
                new TableColumn(COLUMN_FURNI_NAME, this.localize("new_furni_chooser.col.name"), 0.5, "left"),
                new TableColumn(COLUMN_FURNI_OWNER, this.localize("new_furni_chooser.col.owner"), 0.25, "left"),
                new TableColumn(COLUMN_ID, this.localize("new_furni_chooser.col.id"), 0.25, "left")
            ];
            this._tableView.initialize(Vector.<TableColumn>(cols), true, true);
            this._tableView.onRowClickedCallback = this.onListItemClicked;
        }

        private function constructOwners():void
        {
            var owners:Array = [];
            var seen:Object = {};
            var item:_Str_3405;

            this._ignoreListeners = true;
            this._owners = [];
            owners.push(this.localize("new_furni_chooser.owner_selector.default"));
            if (this._widget.items != null)
            {
                for each (item in this._widget.items)
                {
                    var ownerKey:String = this.resolveOwnerKey(item);
                    if ((ownerKey == null) || (ownerKey.length == 0))
                    {
                        continue;
                    }
                    if (seen[ownerKey])
                    {
                        continue;
                    }
                    this._owners.push(ownerKey);
                    owners.push(ownerKey);
                    seen[ownerKey] = true;
                }
            }

            this.usernameDropDown.populate(owners);
            this.usernameDropDown.selection = 0;
            if (owners.length <= 1)
            {
                this.usernameDropDown.disable();
                this.usernameDropDown.blend = 0.5;
            }
            else
            {
                this.usernameDropDown.enable();
                this.usernameDropDown.blend = 1;
            }
            this._ignoreListeners = false;
        }

        private function populateWithFilters():void
        {
            var terms:Array;
            var selectedOwner:String;
            var filtered:Array;
            var item:_Str_3405;
            var term:String;
            var objects:Vector.<ITableObject>;

            if (this._window == null)
            {
                return;
            }
            terms = this.searchTextInput.text.toLowerCase().split(" ");
            if (this.usernameDropDown.selection > 0)
            {
                selectedOwner = this._owners[(this.usernameDropDown.selection - 1)];
            }
            else
            {
                selectedOwner = null;
            }
            filtered = [];

            loop0:
            for each (item in this._widget.items)
            {
                for each (term in terms)
                {
                    if (item.lowerCaseName.indexOf(term) != -1)
                    {
                        continue;
                    }
                    continue loop0;
                }
                if (((selectedOwner != null) && (!(this.resolveOwnerKey(item) == selectedOwner))))
                {
                    continue;
                }
                filtered.push(item);
            }

            objects = new Vector.<ITableObject>();
            for each (item in filtered)
            {
                objects.push(new FurniChooserTableObject(item));
            }
            this._tableView.setObjects(objects);
            this.amountIndicator.text = this._widget.localizations.getLocalizationWithParams("new_furni_chooser.amount_indicator", "", "amount", filtered.length);
        }

        private function onListItemClicked(row:FurniChooserTableObject):void
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

        private function onUsernameChanged(k:WindowEvent):void
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

        private function resolveOwnerKey(item:_Str_3405):String
        {
            if (item == null)
            {
                return "";
            }
            if (BuildersClubTools.isBuildersClubFurniture(item.id))
            {
                return BUILDERS_CLUB_OWNER;
            }
            return ((item.owner != null) ? item.owner : "");
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

        private function get usernameDropDown():IDropMenuWindow
        {
            return (this._window.findChildByName("username_dropdown") as IDropMenuWindow);
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
