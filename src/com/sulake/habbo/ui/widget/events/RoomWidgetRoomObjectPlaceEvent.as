package com.sulake.habbo.ui.widget.events
{
    public class RoomWidgetRoomObjectPlaceEvent extends RoomWidgetRoomObjectUpdateEvent 
    {
        public static const OBJECT_PLACED:String = "RWROUE_OBJECT_PLACED";

        private var _wallLocation:String;
        private var _x:Number;
        private var _y:Number;
        private var _z:Number;
        private var _direction:int;
        private var _placedInRoom:Boolean;
        private var _placedOnFloor:Boolean;
        private var _placedOnWall:Boolean;
        private var _instanceData:String;
        private var _placementSource:String;

        public function RoomWidgetRoomObjectPlaceEvent(k:String, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:String, _arg_6:Number, _arg_7:Number, _arg_8:Number, _arg_9:int, _arg_10:Boolean, _arg_11:Boolean, _arg_12:Boolean, _arg_13:String, _arg_14:String, _arg_15:Boolean=false, _arg_16:Boolean=false)
        {
            super(k, _arg_2, _arg_3, _arg_4, _arg_15, _arg_16);
            this._wallLocation = _arg_5;
            this._x = _arg_6;
            this._y = _arg_7;
            this._z = _arg_8;
            this._direction = _arg_9;
            this._placedInRoom = _arg_10;
            this._placedOnFloor = _arg_11;
            this._placedOnWall = _arg_12;
            this._instanceData = _arg_13;
            this._placementSource = _arg_14;
        }

        public function get wallLocation():String
        {
            return this._wallLocation;
        }

        public function get x():Number
        {
            return this._x;
        }

        public function get y():Number
        {
            return this._y;
        }

        public function get z():Number
        {
            return this._z;
        }

        public function get direction():int
        {
            return this._direction;
        }

        public function get placedInRoom():Boolean
        {
            return this._placedInRoom;
        }

        public function get placedOnFloor():Boolean
        {
            return this._placedOnFloor;
        }

        public function get placedOnWall():Boolean
        {
            return this._placedOnWall;
        }

        public function get instanceData():String
        {
            return this._instanceData;
        }

        public function get placementSource():String
        {
            return this._placementSource;
        }
    }
}
