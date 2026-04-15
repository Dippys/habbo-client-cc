package com.sulake.habbo.communication.messages.parser.catalog
{
    import com.sulake.core.communication.messages.IMessageParser;
    import com.sulake.core.communication.messages.IMessageDataWrapper;

    public class BCPlacementWarningMessageParser implements IMessageParser
    {
        public static const TYPE_FLOOR:int = 0;
        public static const TYPE_WALL:int  = 1;

        private var _typeCode:int;
        private var _pageId:int;
        private var _offerId:int;
        private var _extraParam:String;
        private var _x:int;
        private var _y:int;
        private var _direction:int;
        private var _wallLocation:String;

        public function flush():Boolean
        {
            return true;
        }

        public function parse(k:IMessageDataWrapper):Boolean
        {
            _typeCode   = k.readInteger();
            _pageId     = k.readInteger();
            _offerId    = k.readInteger();
            _extraParam = k.readString();
            if (_typeCode == TYPE_FLOOR)
            {
                _x         = k.readInteger();
                _y         = k.readInteger();
                _direction = k.readInteger();
            }
            else
            {
                _wallLocation = k.readString();
            }
            return true;
        }

        public function get typeCode():int         { return _typeCode; }
        public function get pageId():int           { return _pageId; }
        public function get offerId():int          { return _offerId; }
        public function get extraParam():String    { return _extraParam; }
        public function get x():int               { return _x; }
        public function get y():int               { return _y; }
        public function get direction():int        { return _direction; }
        public function get wallLocation():String  { return _wallLocation; }
    }
}
