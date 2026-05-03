package com.sulake.habbo.ui.handler
{
    import com.sulake.habbo.ui.IRoomWidgetHandler;
    import com.sulake.core.runtime.IDisposable;
    import com.sulake.habbo.ui.IRoomWidgetHandlerContainer;
    import com.sulake.habbo.ui.RoomDesktop;
    import com.sulake.habbo.ui.widget.camera.RoomThumbnailCameraWidget;
    import com.sulake.habbo.communication.messages.incoming.camera.ThumbnailStatusMessageEvent;
    import com.sulake.habbo.ui.widget.messages.RoomWidgetMessage;
    import com.sulake.habbo.ui.widget.events.RoomWidgetUpdateEvent;
    import flash.events.Event;
    import com.sulake.habbo.ui.widget.enums.RoomWidgetEnum;
    import com.sulake.habbo.communication.messages.outgoing.camera.RenderRoomThumbnailMessageComposer;
    import com.sulake.habbo.window.enum.HabboAlertDialogFlag;
    import com.sulake.habbo.navigator.IHabboTransitionalNavigator;
    import com.sulake.core.runtime.Component;
    import flash.utils.getTimer;

    public class RoomThumbnailCameraWidgetHandler implements IRoomWidgetHandler, IDisposable 
    {
        private var _container:IRoomWidgetHandlerContainer = null;
        private var _roomDesktop:RoomDesktop;
        private var _widget:RoomThumbnailCameraWidget;
        private var _thumbnailStatusMessageEvent:ThumbnailStatusMessageEvent;

        public function RoomThumbnailCameraWidgetHandler(k:RoomDesktop)
        {
            this._roomDesktop = k;
        }

        public function get _Str_6647():RoomDesktop
        {
            return this._roomDesktop;
        }

        public function getProcessedEvents():Array
        {
            return [];
        }

        public function getWidgetMessages():Array
        {
            return null;
        }

        public function processWidgetMessage(k:RoomWidgetMessage):RoomWidgetUpdateEvent
        {
            return null;
        }

        public function set widget(k:RoomThumbnailCameraWidget):void
        {
            this._widget = k;
        }

        public function set container(k:IRoomWidgetHandlerContainer):void
        {
            this._container = k;
            this._thumbnailStatusMessageEvent = new ThumbnailStatusMessageEvent(this._Str_23638);
            this._container.connection.addMessageEvent(this._thumbnailStatusMessageEvent);
        }

        public function dispose():void
        {
            if ((((this._container) && (this._container.connection)) && (this._thumbnailStatusMessageEvent)))
            {
                this._container.connection.removeMessageEvent(this._thumbnailStatusMessageEvent);
            }
        }

        public function get disposed():Boolean
        {
            return false;
        }

        public function processEvent(k:Event):void
        {
        }

        public function update():void
        {
        }

        public function get type():String
        {
            return RoomWidgetEnum.ROOM_THUMBNAIL_CAMERA;
        }

        public function get container():IRoomWidgetHandlerContainer
        {
            return this._container;
        }

        public function collectPhotoData():RenderRoomThumbnailMessageComposer
        {
            return RenderRoomThumbnailMessageComposer(this._roomDesktop.roomEngine.getRenderRoomMessage(this._widget.viewPort, this._roomDesktop.roomBackgroundColor, true));
        }

        public function sendPhotoData(k:RenderRoomThumbnailMessageComposer):void
        {
            this._container.connection.send(k);
        }

        private function _Str_23638(k:ThumbnailStatusMessageEvent):void
        {
            var _local_2:IHabboTransitionalNavigator;
            var _local_3:String;
            var _local_4:Component;
            this._widget.destroy();
            if (k.getParser().isOk())
            {
                _local_2 = (this._container.navigator as IHabboTransitionalNavigator);
                if (((!(_local_2 == null)) && (!(_local_2.data.enteredGuestRoom == null))))
                {
                    _local_2.data.setRoomThumbnailRefreshKey(_local_2.data.enteredGuestRoom.flatId, ("" + getTimer()));
                    _local_3 = ((_local_2.getProperty("navigator.thumbnail.url_base") + _local_2.data.enteredGuestRoom.flatId) + ".png");
                    this._container.windowManager.resourceManager.removeAsset(_local_3);
                    if (_local_2.roomInfoViewCtrl != null)
                    {
                        _local_2.roomInfoViewCtrl.reload();
                    }
                    if (_local_2.mainViewCtrl != null)
                    {
                        if (((_local_2.data.guestRoomSearchResults == null) || (!(_local_2.mainViewCtrl.reloadRoomList(_local_2.data.guestRoomSearchResults.searchType)))))
                        {
                            _local_2.mainViewCtrl.refresh();
                        }
                    }
                }
                _local_4 = (this._container.windowManager as Component);
                if (_local_4 != null)
                {
                    _local_4.context.createLinkEvent("navigator/refresh");
                }
                this._container.windowManager.alert("${navigator.thumbnail.camera.title}", "${navigator.thumbnail.camera.success}", HabboAlertDialogFlag.BUTTON_OK, null);
            }
            else
            {
                if (k.getParser().isRenderLimitHit())
                {
                    this._container.windowManager.alert("${generic.alert.title}", "${camera.render.count.info}", 0, null);
                }
            }
        }
    }
}
