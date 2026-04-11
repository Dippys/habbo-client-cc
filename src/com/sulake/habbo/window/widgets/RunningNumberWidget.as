package com.sulake.habbo.window.widgets
{
    import com.sulake.core.runtime.IUpdateReceiver;
    import com.sulake.core.window.utils.PropertyStruct;
    import com.sulake.core.window.components.IWidgetWindow;
    import com.sulake.habbo.window.HabboWindowManagerComponent;
    import com.sulake.core.window.IWindowContainer;
    import com.sulake.core.window.enum.WindowParam;
    import com.sulake.core.window.iterators.EmptyIterator;
    import com.sulake.core.window.utils.IIterator;
    import com.sulake.core.window.components.ITextWindow;

    public class RunningNumberWidget implements IRunningNumberWidget, IUpdateReceiver 
    {
        public static const RUNNING_NUMBER:String = "running_number";
        private static const numberPropertyKey:String = (RUNNING_NUMBER + ":number");
        private static const digitsPropertyKey:String = (RUNNING_NUMBER + ":digits");
        private static const colorStylePropertyKey:String = (RUNNING_NUMBER + ":color_style");
        private static const updateFrequencyPropertyKey:String = (RUNNING_NUMBER + ":update_frequency");
        private static const numberProperty:PropertyStruct = new PropertyStruct(numberPropertyKey, 0, PropertyStruct.INT);
        private static const digitsProperty:PropertyStruct = new PropertyStruct(digitsPropertyKey, 8, PropertyStruct.UINT);
        private static const colorStyleProperty:PropertyStruct = new PropertyStruct(colorStylePropertyKey, 0, PropertyStruct.INT);
        private static const _Str_14116:PropertyStruct = new PropertyStruct(updateFrequencyPropertyKey, 50, PropertyStruct.INT);

        private var _disposed:Boolean;
        private var _widgetWindow:IWidgetWindow;
        private var _windowManager:HabboWindowManagerComponent;
        private var _root:IWindowContainer;
        private var _colorStyle:int;
        private var _digits:uint;
        private var _updateFrequency:int;
        private var _newNumber:int;
        private var _displayedNumber:Number = 0;
        private var _millisSinceLastUpdate:uint = 0;

        public function RunningNumberWidget(k:IWidgetWindow, _arg_2:HabboWindowManagerComponent)
        {
            this._colorStyle = int(colorStyleProperty.value);
            this._digits = uint(digitsProperty.value);
            this._updateFrequency = int(_Str_14116.value);
            this._newNumber = int(numberProperty.value);
            super();
            this._widgetWindow = k;
            this._windowManager = _arg_2;
            this._root = (this._windowManager.buildFromXML((this._windowManager.assets.getAssetByName("running_number_xml").content as XML)) as IWindowContainer);
            this._windowManager.registerUpdateReceiver(this, this._updateFrequency);
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

        public function get properties():Array
        {
            var k:Array = [];
            if (this._disposed)
            {
                return k;
            }
            k.push(numberProperty.withValue(this.colorStyle));
            k.push(colorStyleProperty.withValue(this.colorStyle));
            k.push(digitsProperty.withValue(this.digits));
            k.push(_Str_14116.withValue(this.updateFrequency));
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
                    case numberPropertyKey:
                        this.number = int(_local_2.value);
                        break;
                    case digitsPropertyKey:
                        this.digits = uint(_local_2.value);
                        break;
                    case colorStylePropertyKey:
                        this.colorStyle = int(_local_2.value);
                        break;
                    case updateFrequencyPropertyKey:
                        this.updateFrequency = int(_local_2.value);
                        break;
                }
            }
        }

        public function get iterator():IIterator
        {
            return EmptyIterator.INSTANCE;
        }

        public function update(k:uint):void
        {
            if (this._displayedNumber < this.number)
            {
                this._millisSinceLastUpdate = (this._millisSinceLastUpdate + k);
                if (this._millisSinceLastUpdate > this._updateFrequency)
                {
                    this._displayedNumber = Math.min(this._newNumber, (this._displayedNumber + (this._millisSinceLastUpdate / this._updateFrequency)));
                    this._millisSinceLastUpdate = (this._millisSinceLastUpdate - this._updateFrequency);
                }
                this.displayedNumber = this._displayedNumber;
            }
        }

        private function set displayedNumber(k:uint):void
        {
            var _local_2:String = k.toString();
            while (_local_2.length < this._digits)
            {
                _local_2 = ("0" + _local_2);
            }
            var _local_3:ITextWindow = ITextWindow(this._root.findChildByName("number_field"));
            _local_3.text = _local_2;
            _local_3.invalidate();
        }

        public function get digits():uint
        {
            return this._digits;
        }

        public function set digits(k:uint):void
        {
            this._digits = k;
        }

        public function get colorStyle():int
        {
            return this._colorStyle;
        }

        public function set colorStyle(k:int):void
        {
            this._colorStyle = k;
        }

        public function get updateFrequency():int
        {
            return this._updateFrequency;
        }

        public function set updateFrequency(k:int):void
        {
            this._updateFrequency = k;
        }

        public function get number():int
        {
            return this._newNumber;
        }

        public function set number(k:int):void
        {
            this._newNumber = k;
        }

        public function set setNumberImmediately(k:int):void
        {
            this._displayedNumber = k;
            this._newNumber = k;
            this.displayedNumber = this._displayedNumber;
        }
    }
}
