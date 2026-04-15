package com.sulake.core.localization
{
    import com.sulake.core.runtime.Component;
    import com.sulake.core.runtime.IDisposable;
    import flash.utils.Dictionary;
    import com.sulake.core.utils.Map;
    import com.sulake.core.runtime.IContext;
    import com.sulake.core.assets.IAssetLibrary;
    import flash.net.URLRequest;
    import com.sulake.core.assets.AssetLoaderStruct;
    import com.sulake.core.assets.loaders.AssetLoaderEvent;
    import com.sulake.core.assets.IAsset;
    import flash.events.Event;
    import com.sulake.core.localization.enum.LocalizationEvent;
    import com.sulake.core.utils.ErrorReportStorage;
    import com.sulake.core.Core;

    public class CoreLocalizationManager extends Component implements IDisposable, ICoreLocalizationManager 
    {
        private var _localizations:Dictionary;
        private var _localizationDefinitions:Map;
        private var _activeLocalizationDefinition:String;
        private var _nonExistingKeysTable:Array;

        public function CoreLocalizationManager(k:IContext, _arg_2:uint=0, _arg_3:IAssetLibrary=null)
        {
            this._nonExistingKeysTable = [];
            super(k, _arg_2, _arg_3);
        }

        override protected function initComponent():void
        {
            this._localizations = new Dictionary();
            this._localizationDefinitions = new Map();
        }

        override public function dispose():void
        {
            this._localizations = null;
            if (this._localizationDefinitions != null)
            {
                this._localizationDefinitions.dispose();
            }
            this._localizationDefinitions = null;
            this._nonExistingKeysTable = null;
            super.dispose();
        }

        public function registerLocalizationDefinition(k:String, _arg_2:String, _arg_3:String, _arg_4:String):void
        {
            var _local_5:LocalizationDefinition = this._localizationDefinitions[k];
            if (_local_5 == null)
            {
                _local_5 = new LocalizationDefinition(_arg_4, _arg_2, _arg_3);
                this._localizationDefinitions[k] = _local_5;
            }
        }

        public function activateLocalizationDefinition(k:String):Boolean
        {
            var _local_2:LocalizationDefinition = this._localizationDefinitions[k];
            if (_local_2 != null)
            {
                this._activeLocalizationDefinition = k;
                this.loadLocalizationFromURL(_local_2.url);
                return true;
            }
            return false;
        }

        public function getLocalizationDefinitions():Map
        {
            return this._localizationDefinitions;
        }

        public function getLocalizationDefinition(k:String):ILocalizationDefinition
        {
            return this._localizationDefinitions[k] as ILocalizationDefinition;
        }

        public function getActiveLocalizationDefinition():ILocalizationDefinition
        {
            return this.getLocalizationDefinition(this._activeLocalizationDefinition);
        }

        public function loadLocalizationFromURL(k:String):void
        {
            var _local_2:String = k;
            var _local_3:URLRequest = new URLRequest(k);
            var _local_4:AssetLoaderStruct = assets.loadAssetFromFile(_local_2, _local_3, "text/plain");
            _local_4.addEventListener(AssetLoaderEvent.ASSETLOADEREVENTCOMPLETE, this.onLocalizationReady);
            _local_4.addEventListener(AssetLoaderEvent.ASSETLOADEREVENTERROR, this.onLocalizationFailed);
        }

        private function onLocalizationReady(k:AssetLoaderEvent):void
        {
            var _local_3:String;
            var _local_4:IAsset;
            var _local_2:AssetLoaderStruct = (k.target as AssetLoaderStruct);
            if (_local_2 != null)
            {
                _local_3 = _local_2.assetName;
                this.parseLocalizationData((_local_2.assetLoader.content as String));
                this.events.dispatchEvent(new Event(LocalizationEvent.LOCALIZATION_EVENT_LOCALIZATION_LOADED));
                _local_4 = assets.getAssetByName(_local_3);
                if (_local_4)
                {
                    assets.removeAsset(_local_4).dispose();
                }
            }
        }

        protected function onLocalizationFailed(k:AssetLoaderEvent):void
        {
            var _local_2:AssetLoaderStruct = (k.target as AssetLoaderStruct);
            var _local_3:URLRequest = new URLRequest(_local_2.assetLoader.url);
            var _local_4:AssetLoaderStruct = assets.loadAssetFromFile(_local_2.assetLoader.url, _local_3, "text/plain");
            _local_4.addEventListener(AssetLoaderEvent.ASSETLOADEREVENTCOMPLETE, this.onLocalizationReady);
            _local_4.addEventListener(AssetLoaderEvent.ASSETLOADEREVENTERROR, this._Str_23319);
        }

        private function _Str_23319(k:AssetLoaderEvent):void
        {
            var _local_2:AssetLoaderStruct = (k.target as AssetLoaderStruct);
            ErrorReportStorage.addDebugData("Localization name", _local_2.assetName);
            ErrorReportStorage.addDebugData("Localization url", _local_2.assetLoader.url);
            ErrorReportStorage.addDebugData("Localization error", ("Code: " + _local_2.assetLoader.errorCode));
            Core.error("Failed to download localization", true, Core.ERROR_CATEGORY_DOWNLOAD_LOCALIZATION);
        }

        public function hasLocalization(k:String):Boolean
        {
            var _local_2:Localization = (this._localizations[k] as Localization);
            return !(_local_2 == null);
        }

        public function getLocalization(k:String, _arg_2:String=""):String
        {
            var _local_3:Localization = (this._localizations[k] as Localization);
            if (_local_3 == null)
            {
                this._nonExistingKeysTable.push(k);
                return _arg_2;
            }
            return _local_3.value;
        }

        private function getRawValue(k:String, _arg_2:String=""):String
        {
            var _local_3:Localization = (this._localizations[k] as Localization);
            if (_local_3 == null)
            {
                this._nonExistingKeysTable.push(k);
                return _arg_2;
            }
            return _local_3.raw;
        }

        public function updateLocalization(k:String, _arg_2:String):void
        {
            var _local_3:Localization = this._localizations[k];
            if (_local_3 == null)
            {
                _local_3 = new Localization(this, k, _arg_2);
                this._localizations[k] = _local_3;
            }
            else
            {
                _local_3.setValue(_arg_2);
            }
        }

        private function updateAllListeners():void
        {
            var k:Localization;
            for each (k in this._localizations)
            {
                k.updateListeners();
            }
        }

        public function registerListener(k:String, _arg_2:ILocalizable):Boolean
        {
            var _local_3:Localization = this._localizations[k];
            if (_local_3 == null)
            {
                this._nonExistingKeysTable.push(k);
                _local_3 = new Localization(this, k, k);
                this._localizations[k] = _local_3;
            }
            _local_3.registerListener(_arg_2);
            return true;
        }

        public function removeListener(k:String, _arg_2:ILocalizable):Boolean
        {
            var _local_3:Localization = this._localizations[k];
            if (_local_3 != null)
            {
                _local_3.removeListener(_arg_2);
            }
            return true;
        }

        public function registerParameter(k:String, _arg_2:String, _arg_3:String, _arg_4:String="%"):String
        {
            var _local_5:Localization = this._localizations[k];
            if (_local_5 == null)
            {
                _local_5 = new Localization(this, k, k);
                this._localizations[k] = _local_5;
            }
            _local_5.registerParameter(_arg_2, _arg_3, _arg_4);
            return _local_5.value;
        }

        public function getLocalizationRaw(k:String):ILocalization
        {
            return this._localizations[k] as ILocalization;
        }

        public function getKeys():Array
        {
            var _local_2:String;
            var k:Array = new Array();
            for (_local_2 in this._localizations)
            {
                k.push(_local_2);
            }
            return k;
        }

        public function printNonExistingKeys():void
        {
            var _local_2:String;
            var k:String = "";
            for each (_local_2 in this._nonExistingKeysTable)
            {
                k = (k + (_local_2 + "\n"));
            }
            Logger.log(k);
        }

        protected function parseLocalizationData(k:String):void
        {
            if (k == null)
            {
                return;
            }
            var _local_first:String = this.stripLeading(k);
            if (_local_first.length > 0 && _local_first.charAt(0) == "{")
            {
                this.parseLocalizationJSON(_local_first);
            }
            else
            {
                this.parseLocalizationFlat(k);
            }
            this.updateAllListeners();
        }

        private function stripLeading(k:String):String
        {
            var _local_2:int = 0;
            if (k.length > 0 && k.charCodeAt(0) == 0xFEFF)
            {
                _local_2 = 1;
            }
            while (_local_2 < k.length)
            {
                var _local_3:String = k.charAt(_local_2);
                if (_local_3 == " " || _local_3 == "\t" || _local_3 == "\n" || _local_3 == "\r")
                {
                    _local_2++;
                    continue;
                }
                break;
            }
            return k.substr(_local_2);
        }

        private function stripJSONComments(k:String):String
        {
            var _local_2:String = k.replace(/\/\*[\s\S]*?\*\//g, "");
            _local_2 = _local_2.replace(/^\s*\/\/.*$/gm, "");
            return _local_2;
        }

        private function parseLocalizationJSON(k:String):void
        {
            var _local_2:Object;
            try
            {
                _local_2 = JSON.parse(this.stripJSONComments(k));
            }
            catch (e:Error)
            {
                ErrorReportStorage.addDebugData("Localization parse error", e.message);
                return;
            }
            this.flattenAndApplyLocalization(_local_2, "");
        }

        private function flattenAndApplyLocalization(k:Object, _arg_2:String):void
        {
            var _local_3:String;
            var _local_4:*;
            var _local_5:String;
            var _local_6:int;
            var _local_7:Boolean;
            if (k == null)
            {
                return;
            }
            if (k is Array)
            {
                _local_6 = 0;
                while (_local_6 < (k as Array).length)
                {
                    _local_5 = (_arg_2.length > 0) ? (_arg_2 + "." + _local_6) : ("" + _local_6);
                    this.flattenAndApplyLocalization((k as Array)[_local_6], _local_5);
                    _local_6++;
                }
                return;
            }
            _local_7 = false;
            for (_local_3 in k)
            {
                if (_local_3 == "$")
                {
                    _local_7 = true;
                    continue;
                }
                _local_4 = k[_local_3];
                _local_5 = (_arg_2.length > 0) ? (_arg_2 + "." + _local_3) : _local_3;
                this.applyLocalizationValue(_local_4, _local_5);
            }
            if (_local_7 && _arg_2.length > 0)
            {
                this.applyLocalizationValue(k["$"], _arg_2);
            }
        }

        private function applyLocalizationValue(k:*, _arg_2:String):void
        {
            if (k == null)
            {
                return;
            }
            if (k is String)
            {
                if ((k as String).length > 0)
                {
                    this.updateLocalization(_arg_2, (k as String));
                }
            }
            else if (k is Number || k is int || k is uint || k is Boolean)
            {
                this.updateLocalization(_arg_2, String(k));
            }
            else
            {
                this.flattenAndApplyLocalization(k, _arg_2);
            }
        }

        private function parseLocalizationFlat(k:String):void
        {
            var _local_6:String;
            var _local_7:Array;
            var _local_8:String;
            var _local_9:String;
            var _local_2:RegExp = /\n\r{1,}|\n{1,}|\r{1,}/mg;
            var _local_3:RegExp = /^\s+|\s+$/g;
            var _local_4:Array = k.split(_local_2);
            var _local_5:RegExp = /\\n/mg;
            for each (_local_6 in _local_4)
            {
                if (_local_6.charAt(0) == "#")
                {
                }
                else
                {
                    _local_7 = _local_6.split("=");
                    if (_local_7[0].length > 0)
                    {
                        if (_local_7.length > 1)
                        {
                            _local_8 = _local_7.shift();
                            _local_9 = _local_7.join("=");
                            _local_8 = _local_8.replace(_local_3, "");
                            _local_9 = _local_9.replace(_local_3, "");
                            _local_9 = _local_9.replace(_local_5, "\n");
                            if (_local_9.length > 0)
                            {
                                this.updateLocalization(_local_8, _local_9);
                            }
                        }
                    }
                }
            }
        }
    }
}
