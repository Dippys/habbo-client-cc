package com.sulake.habbo.communication.messages.parser.catalog
{
    import com.sulake.core.communication.messages.IMessageParser;
    import com.sulake.core.communication.messages.IMessageDataWrapper;

    public class BuildersClubSubscriptionStatusMessageParser implements IMessageParser
    {
        private var _secondsRemaining:int;
        private var _furniLimit:int;
        private var _maxFurniLimit:int;
        private var _secondsRemainingWithGrace:int;


        public function flush():Boolean
        {
            return true;
        }

        public function parse(k:IMessageDataWrapper):Boolean
        {
            this._secondsRemaining = k.readInteger();
            this._furniLimit = k.readInteger();
            this._maxFurniLimit = k.readInteger();
            if (k.bytesAvailable)
            {
                this._secondsRemainingWithGrace = k.readInteger();
            }
            else
            {
                this._secondsRemainingWithGrace = this._secondsRemaining;
            }
            return true;
        }

        public function get secondsRemaining():int
        {
            return this._secondsRemaining;
        }

        public function get furniLimit():int
        {
            return this._furniLimit;
        }

        public function get maxFurniLimit():int
        {
            return this._maxFurniLimit;
        }

        public function get secondsRemainingWithGrace():int
        {
            return this._secondsRemainingWithGrace;
        }
    }
}
