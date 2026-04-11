package com.sulake.habbo.window.widgets
{
    import com.sulake.core.runtime.IUpdateReceiver;
    import com.sulake.core.window.utils.PropertyStruct;
    import com.sulake.core.window.components.IWidgetWindow;
    import com.sulake.habbo.window.HabboWindowManagerComponent;
    import com.sulake.core.window.components.IItemListWindow;
    import com.sulake.core.window.IWindowContainer;
    import com.sulake.core.window.components.ITextWindow;
    import flash.utils.getTimer;
    import com.sulake.core.window.enum.WindowParam;
    import com.sulake.core.window.iterators.EmptyIterator;
    import com.sulake.core.window.utils.IIterator;

    public class CountdownWidget implements ICountdownWidget, IUpdateReceiver 
    {
        public static const COUNTDOWN:String = "countdown";
        private static const runningPropertyKey:String = (COUNTDOWN + ":running");
        private static const digitsPropertyKey:String = (COUNTDOWN + ":digits");
        private static const secondsPropertyKey:String = (COUNTDOWN + ":seconds");
        private static const colorStylePropertyKey:String = (COUNTDOWN + ":color_style");
        private static const runningProperty:PropertyStruct = new PropertyStruct(runningPropertyKey, false, PropertyStruct.BOOLEAN);
        private static const digitsProperty:PropertyStruct = new PropertyStruct(digitsPropertyKey, 3, PropertyStruct.UINT);
        private static const secondsProperty:PropertyStruct = new PropertyStruct(secondsPropertyKey, 0, PropertyStruct.INT);
        private static const colorStyleProperty:PropertyStruct = new PropertyStruct(colorStylePropertyKey, 0, PropertyStruct.INT);
        private static const COUNTDOWN_CLOCK_UNIT_:String = "countdown_clock_unit_";
        private static const _Str_16025:Array = ["weeks", "days", "hours", "minutes", "seconds"];
        private static const _Str_9932:Array = [604800, 86400, 3600, 60, 1];
        private static const _Str_16425:Array = [100, 7, 24, 60, 60];
        private static const _Str_14826:Array = [0, 0xFFFFFF];
        private static const _Str_17827:Array = [3003121663, 0];

        private var _disposed:Boolean;
        private var _widgetWindow:IWidgetWindow;
        private var _windowManager:HabboWindowManagerComponent;
        private var _root:IItemListWindow;
        private var _digitWindow:IWindowContainer;
        private var _separatorWindow:ITextWindow;
        private var _running:Boolean;
        private var _startSeconds:int;
        private var _startTime:int;
        private var _colorStyle:int;
        private var _displayedTime:int = -1;

        public function CountdownWidget(k:IWidgetWindow, _arg_2:HabboWindowManagerComponent)
        {
            this._running = Boolean(runningProperty.value);
            this._startSeconds = int(secondsProperty.value);
            this._startTime = getTimer();
            this._colorStyle = int(colorStyleProperty.value);
            super();
            this._widgetWindow = k;
            this._windowManager = _arg_2;
            this._root = (this._windowManager.buildFromXML((this._windowManager.assets.getAssetByName("clock_base_xml").content as XML)) as IItemListWindow);
            this._digitWindow = (this._root.getListItemByName("counter") as IWindowContainer);
            this._separatorWindow = (this._root.getListItemByName("separator") as ITextWindow);
            this.digits = uint(digitsProperty.value);
            this._windowManager.registerUpdateReceiver(this, 10);
            this._widgetWindow.setParamFlag(WindowParam.WINDOW_PARAM_RESIZE_TO_ACCOMMODATE_CHILDREN);
            this._widgetWindow.rootWindow = this._root;
        }

        public function dispose():void
        {
            if (!this._disposed)
            {
                if (this._root != null)
                {
                    this._root.dispose();
                    this._root = null;
                }
                if (this._digitWindow != null)
                {
                    this._digitWindow.dispose();
                    this._digitWindow = null;
                }
                if (this._separatorWindow != null)
                {
                    this._separatorWindow.dispose();
                    this._separatorWindow = null;
                }
                if (this._widgetWindow != null)
                {
                    this._widgetWindow.rootWindow = null;
                    this._widgetWindow = null;
                }
                this._windowManager.removeUpdateReceiver(this);
                this._windowManager = null;
                this._disposed = true;
            }
        }

        public function get disposed():Boolean
        {
            return this._disposed;
        }

        public function get iterator():IIterator
        {
            return EmptyIterator.INSTANCE;
        }

        public function update(k:uint):void
        {
            this.refreshDisplay();
        }

        public function get properties():Array
        {
            var k:Array = [];
            if (this._disposed)
            {
                return k;
            }
            k.push(runningProperty.withValue(this._running));
            k.push(digitsProperty.withValue(this.digits));
            k.push(secondsProperty.withValue(this.seconds));
            return k;
        }

        public function set properties(k:Array):void
        {
            var _local_2:PropertyStruct;
            if (this._disposed)
            {
                return;
            }
            for each (_local_2 in k)
            {
                switch (_local_2.key)
                {
                    case runningPropertyKey:
                        this.running = Boolean(_local_2.value);
                        break;
                    case digitsPropertyKey:
                        this.digits = uint(_local_2.value);
                        break;
                    case secondsPropertyKey:
                        this.seconds = int(_local_2.value);
                        break;
                    case colorStylePropertyKey:
                        this.colorStyle = int(_local_2.value);
                        break;
                }
            }
        }

        public function get colorStyle():int
        {
            return this._colorStyle;
        }

        public function set colorStyle(k:int):void
        {
            var _local_4:IWindowContainer;
            var _local_5:ITextWindow;
            var _local_6:uint;
            var _local_7:uint;
            this._colorStyle = k;
            var _local_2:int = this._root.numListItems;
            var _local_3:int;
            while (_local_3 < _local_2)
            {
                _local_4 = (this._root.getListItemAt(_local_3) as IWindowContainer);
                if (_local_4 != null)
                {
                    _local_5 = (_local_4.getChildByName("unit") as ITextWindow);
                    if (_local_5 != null)
                    {
                        _local_6 = _local_5.textColor;
                        _local_7 = _local_5.etchingColor;
                        if (((this._colorStyle >= 0) && (this._colorStyle < _Str_14826.length)))
                        {
                            _local_6 = _Str_14826[this._colorStyle];
                            _local_7 = _Str_17827[this._colorStyle];
                        }
                        _local_5.textColor = _local_6;
                        _local_5.etchingColor = _local_7;
                    }
                }
                _local_3++;
            }
        }

        public function get running():Boolean
        {
            return this._running;
        }

        public function set running(k:Boolean):void
        {
            if (((this._running) && (!(k))))
            {
                this._startSeconds = this.seconds;
            }
            if (((!(this._running)) && (k)))
            {
                this._startTime = getTimer();
            }
            this._running = k;
        }

        public function get digits():uint
        {
            return (this._root.numListItems + 1) / 2;
        }

        public function set digits(k:uint):void
        {
            var _local_2:int;
            k = Math.max(2, Math.min(4, k));
            if (k != this.digits)
            {
                this._root.removeListItems();
                _local_2 = 0;
                while (_local_2 < k)
                {
                    if (_local_2 != 0)
                    {
                        this._root.addListItem(this._separatorWindow.clone());
                    }
                    this._root.addListItem(this._digitWindow.clone());
                    _local_2++;
                }
                this.refreshDisplay(true);
            }
        }

        public function get seconds():int
        {
            return (this._running) ? Math.max(0, (this._startSeconds - ((getTimer() - this._startTime) / 1000))) : this._startSeconds;
        }

        public function set seconds(k:int):void
        {
            this._startSeconds = k;
            this._startTime = getTimer();
            this.refreshDisplay();
        }

        private function refreshDisplay(k:Boolean=false):void
        {
            var _local_4:int;
            var _local_6:int;
            var _local_7:IWindowContainer;
            var _local_8:int;
            var _local_2:int = this.seconds;
            if (((_local_2 == this._displayedTime) && (!(k))))
            {
                return;
            }
            var _local_3:int = this.digits;
            _local_4 = 0;
            while (_local_4 < (_Str_9932.length - _local_3))
            {
                if (_local_2 >= _Str_9932[_local_4])
                {
                    break;
                }
                _local_4++;
            }
            var _local_5:int;
            while (_local_5 < _local_3)
            {
                _local_6 = (_local_4 + _local_5);
                _local_7 = (this._root.getListItemAt((_local_5 * 2)) as IWindowContainer);
                _local_8 = ((_local_2 / _Str_9932[_local_6]) % _Str_16425[_local_6]);
                _local_7.getChildByName("value").caption = (((_local_8 < 10) ? "0" : "") + _local_8.toString());
                _local_7.getChildByName("unit").caption = ((("${" + COUNTDOWN_CLOCK_UNIT_) + _Str_16025[_local_6]) + "}");
                _local_5++;
            }
            this._displayedTime = _local_2;
        }
    }
}
