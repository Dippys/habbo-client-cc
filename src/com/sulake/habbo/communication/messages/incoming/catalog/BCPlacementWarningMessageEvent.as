package com.sulake.habbo.communication.messages.incoming.catalog
{
    import com.sulake.core.communication.messages.MessageEvent;
    import com.sulake.core.communication.messages.IMessageEvent;
    import com.sulake.habbo.communication.messages.parser.catalog.BCPlacementWarningMessageParser;

    public class BCPlacementWarningMessageEvent extends MessageEvent implements IMessageEvent
    {
        public function BCPlacementWarningMessageEvent(k:Function)
        {
            super(k, BCPlacementWarningMessageParser);
        }

        public function getParser():BCPlacementWarningMessageParser
        {
            return this._parser as BCPlacementWarningMessageParser;
        }
    }
}
