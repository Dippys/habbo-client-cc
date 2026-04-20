package com.sulake.habbo.freeflowchat
{
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;

    public class Scale9BitmapSprite extends Sprite
    {
        private var _source:BitmapData;
        private var _grid:Rectangle;
        private var _targetWidth:Number;
        private var _targetHeight:Number;

        public function Scale9BitmapSprite(k:Rectangle, _arg_2:BitmapData)
        {
            this._source = _arg_2;
            this._grid = k.clone();
            this._targetWidth = _arg_2.width;
            this._targetHeight = _arg_2.height;
            this.redraw();
        }

        override public function get width():Number
        {
            return this._targetWidth;
        }

        override public function set width(k:Number):void
        {
            k = Math.max(0, k);
            if (this._targetWidth == k)
            {
                return;
            }
            this._targetWidth = k;
            this.redraw();
        }

        override public function get height():Number
        {
            return this._targetHeight;
        }

        override public function set height(k:Number):void
        {
            k = Math.max(0, k);
            if (this._targetHeight == k)
            {
                return;
            }
            this._targetHeight = k;
            this.redraw();
        }

        private function redraw():void
        {
            var _local_1:Number = Math.max(0, this._targetWidth);
            var _local_2:Number = Math.max(0, this._targetHeight);
            var _local_3:Number = Math.max(0, this._grid.left);
            var _local_4:Number = Math.max(0, this._source.width - this._grid.right);
            var _local_5:Number = Math.max(0, this._grid.top);
            var _local_6:Number = Math.max(0, this._source.height - this._grid.bottom);
            var _local_7:Number = Math.max(0, this._source.width - (_local_3 + _local_4));
            var _local_8:Number = Math.max(0, this._source.height - (_local_5 + _local_6));
            var _local_9:Number;
            var _local_10:Number;
            var _local_11:Number;
            var _local_12:Number;
            var _local_13:Number;
            var _local_14:Number;
            var _local_15:Number;
            var _local_16:Number;
            if (_local_1 >= (_local_3 + _local_4))
            {
                _local_9 = _local_3;
                _local_10 = _local_4;
                _local_11 = (_local_1 - _local_3) - _local_4;
            }
            else
            {
                _local_12 = ((_local_3 + _local_4) == 0) ? 0 : (_local_1 / (_local_3 + _local_4));
                _local_9 = (_local_3 * _local_12);
                _local_10 = (_local_4 * _local_12);
                _local_11 = 0;
            }
            if (_local_2 >= (_local_5 + _local_6))
            {
                _local_13 = _local_5;
                _local_14 = _local_6;
                _local_15 = (_local_2 - _local_5) - _local_6;
            }
            else
            {
                _local_16 = ((_local_5 + _local_6) == 0) ? 0 : (_local_2 / (_local_5 + _local_6));
                _local_13 = (_local_5 * _local_16);
                _local_14 = (_local_6 * _local_16);
                _local_15 = 0;
            }
            var _local_17:Array = [0, _local_3, (_local_3 + _local_7), this._source.width];
            var _local_18:Array = [0, _local_5, (_local_5 + _local_8), this._source.height];
            var _local_19:Array = [0, _local_9, (_local_9 + _local_11), _local_1];
            var _local_20:Array = [0, _local_13, (_local_13 + _local_15), _local_2];
            var _local_21:int;
            var _local_22:int;
            var _local_23:Number;
            var _local_24:Number;
            var _local_25:Number;
            var _local_26:Number;
            var _local_27:Number;
            var _local_28:Number;
            var _local_29:Matrix;
            this.graphics.clear();
            while (_local_21 < 3)
            {
                _local_22 = 0;
                while (_local_22 < 3)
                {
                    _local_23 = (_local_17[_local_21 + 1] - _local_17[_local_21]);
                    _local_24 = (_local_18[_local_22 + 1] - _local_18[_local_22]);
                    _local_25 = (_local_19[_local_21 + 1] - _local_19[_local_21]);
                    _local_26 = (_local_20[_local_22 + 1] - _local_20[_local_22]);
                    if (((((_local_23 > 0) && (_local_24 > 0)) && (_local_25 > 0)) && (_local_26 > 0)))
                    {
                        _local_27 = (_local_25 / _local_23);
                        _local_28 = (_local_26 / _local_24);
                        _local_29 = new Matrix();
                        _local_29.scale(_local_27, _local_28);
                        _local_29.translate((_local_19[_local_21] - (_local_17[_local_21] * _local_27)), (_local_20[_local_22] - (_local_18[_local_22] * _local_28)));
                        this.graphics.beginBitmapFill(this._source, _local_29, false, true);
                        this.graphics.drawRect(_local_19[_local_21], _local_20[_local_22], _local_25, _local_26);
                        this.graphics.endFill();
                    }
                    _local_22++;
                }
                _local_21++;
            }
        }
    }
}
