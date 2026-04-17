package com.sulake.habbo.utils
{
    import com.sulake.habbo.avatar.IAvatarImage;
    import flash.display.BitmapData;
    import flash.display.Shape;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class HabboFaceFocuser
    {
        private static const ICON_HEIGHT_NORMAL:int = 50;
        private static const ICON_WIDTH_NORMAL:int = 50;

        private static const X_OFFSETS:Array = [-100, -100, 21, 21, -100, -100, -100, -100, -100];
        private static const Y_OFFSETS:Array = [-100, -100, 28, 30, -100, -100, -100, -100, -100];

        public function HabboFaceFocuser()
        {
            super();
        }

        public static function focusUserFace(k:IAvatarImage, _arg_2:String, _arg_3:int, _arg_4:Number, _arg_5:Number=-1, _arg_6:Number=-1):BitmapData
        {
            if (k == null)
            {
                return null;
            }
            var _local_7:int = (ICON_WIDTH_NORMAL * _arg_4);
            var _local_8:int = (ICON_HEIGHT_NORMAL * _arg_4);
            if (_arg_5 == -1)
            {
                _arg_5 = _local_7;
            }
            if (_arg_6 == -1)
            {
                _arg_6 = _local_8;
            }
            k.setDirection(_arg_2, _arg_3);
            var _local_9:BitmapData = k.getImage(_arg_2, true, _arg_4);
            if (_local_9 == null)
            {
                return null;
            }
            var _local_10:Number = ((_arg_6 - _local_8) / 2);
            var _local_11:BitmapData = new BitmapData(_arg_5, _arg_6, true, 0);
            var _local_12:Rectangle = new Rectangle((X_OFFSETS[_arg_3] * _arg_4), (Y_OFFSETS[_arg_3] * _arg_4), _local_7, _local_8);
            _local_11.copyPixels(_local_9, _local_12, new Point(0, _local_10));
            return _local_11;
        }

        public static function cutCircleFromBitmap(k:BitmapData, _arg_2:Number):BitmapData
        {
            if (k == null)
            {
                return null;
            }
            var _local_3:int = k.width;
            var _local_4:int = k.height;
            var _local_5:BitmapData = new BitmapData(_local_3, _local_4, true, 0);
            var _local_6:Shape = new Shape();
            _local_6.graphics.beginFill(0xFFFFFF);
            _local_6.graphics.drawCircle((_local_3 / 2), (_local_4 / 2), _arg_2);
            _local_6.graphics.endFill();
            var _local_7:BitmapData = new BitmapData(_local_3, _local_4, true, 0);
            _local_7.draw(_local_6);
            _local_5.copyPixels(k, new Rectangle(0, 0, _local_3, _local_4), new Point(0, 0), _local_7, new Point(0, 0), true);
            return _local_5;
        }
    }
}
