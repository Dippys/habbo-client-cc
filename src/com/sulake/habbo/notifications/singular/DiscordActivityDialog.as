package com.sulake.habbo.notifications.singular
{
    import com.sulake.core.runtime.IDisposable;
    import com.sulake.core.window.IWindow;
    import com.sulake.core.window.IWindowContainer;
    import com.sulake.core.window.components.ICheckBoxWindow;
    import com.sulake.core.assets.IAsset;
    import com.sulake.core.window.events.WindowMouseEvent;
    import com.sulake.core.window.events.WindowEvent;
    import com.sulake.habbo.notifications.HabboNotifications;

    public class DiscordActivityDialog implements IDisposable 
    {
        private var _habboNotifications:HabboNotifications;
        private var _window:IWindowContainer;

        public function DiscordActivityDialog(notifications:HabboNotifications)
        {
            super();
            this._habboNotifications = notifications;

            var layoutAsset:IAsset = this._habboNotifications.assets.getAssetByName("discord_activity_dialog_xml");
            if (layoutAsset == null) {
                Logger.log("ERROR: Could not find asset discord_activity_dialog_xml");
                return;
            }
            this._window = (this._habboNotifications.windowManager.buildFromXML((layoutAsset.content as XML)) as IWindowContainer);
            if (this._window == null)
            {
                Logger.log("ERROR: Could not build discord activity window from XML");
                return;
            }
            this._window.procedure = this.windowProcedure;

            this.initCheckboxes();
            this._window.center();
        }

        private function initCheckboxes():void
        {
            this.setCheckboxSelected("show_habbo_cbx", true);
            this.setCheckboxSelected("share_activity_cbx", true);
            this.setCheckboxSelected("hide_in_hidden_cbx", true);
            this.setCheckboxSelected("allow_joining_cbx", true);
        }

        private function setCheckboxSelected(name:String, selected:Boolean):void
        {
            var checkbox:IWindow = this._window.findChildByName(name);
            if (checkbox != null && checkbox is ICheckBoxWindow)
            {
                if (selected)
                {
                    ICheckBoxWindow(checkbox).select();
                }
            }
        }

        private function windowProcedure(event:WindowEvent, target:IWindow):void
        {
            if (this.disposed)
            {
                return;
            }
            switch (event.type)
            {
                case WindowMouseEvent.CLICK:
                    switch (target.name)
                    {
                        case "header_button_close":
                        case "funny_button":
                            this.dispose();
                            break;
                    }
                    return;
            }
        }

        public function dispose():void
        {
            if (this.disposed)
            {
                return;
            }
            this._window.dispose();
            this._window = null;
            this._habboNotifications = null;
        }

        public function get disposed():Boolean
        {
            return this._window == null;
        }
    }
}
