package com.sulake.habbo.window.utils.tableview
{
    import com.sulake.core.window.IWindow;
    import com.sulake.core.window.IWindowContainer;
    import com.sulake.core.window.components.IBorderWindow;
    import com.sulake.core.window.components.IRegionWindow;
    import com.sulake.core.window.components.ITextFieldWindow;
    import com.sulake.core.window.components.ITextWindow;

    public class CellTemplate
    {
        private var _template:IRegionWindow;
        private var _highlightBorderTemplate:IBorderWindow;
        private var _textTemplate:ITextWindow;
        private var _inputTemplate:ITextFieldWindow;
        private var _linkTemplate:IRegionWindow;
        private var _extraButtonTemplate:IRegionWindow;

        public function CellTemplate(template:IRegionWindow)
        {
            this._template = template;
            this._highlightBorderTemplate = (template.findChildByName("highlight_border") as IBorderWindow);
            this._textTemplate = (template.findChildByName("element_text") as ITextWindow);
            this._inputTemplate = (template.findChildByName("element_input") as ITextFieldWindow);
            this._linkTemplate = (template.findChildByName("link_container") as IRegionWindow);
            this._extraButtonTemplate = (template.findChildByName("extra_button") as IRegionWindow);

            if (this._extraButtonTemplate != null)
            {
                this._template.removeChild(this._extraButtonTemplate);
            }
            if (this._linkTemplate != null)
            {
                this._template.removeChild(this._linkTemplate);
            }
            if (this._inputTemplate != null)
            {
                this._template.removeChild(this._inputTemplate);
            }
            if (this._textTemplate != null)
            {
                this._template.removeChild(this._textTemplate);
            }
            if (this._highlightBorderTemplate != null)
            {
                this._template.removeChild(this._highlightBorderTemplate);
            }
        }

        public function clone():IRegionWindow
        {
            return (this._template.clone() as IRegionWindow);
        }

        public function createHighlightBorder(parent:IWindowContainer):IBorderWindow
        {
            return (this.cloneAndAdd(this._highlightBorderTemplate, parent) as IBorderWindow);
        }

        public function createElementText(parent:IWindowContainer):ITextWindow
        {
            return (this.cloneAndAdd(this._textTemplate, parent) as ITextWindow);
        }

        public function createElementInput(parent:IWindowContainer):ITextFieldWindow
        {
            return (this.cloneAndAdd(this._inputTemplate, parent) as ITextFieldWindow);
        }

        public function createLinkContainer(parent:IWindowContainer):IRegionWindow
        {
            return (this.cloneAndAdd(this._linkTemplate, parent) as IRegionWindow);
        }

        public function createExtraButton(parent:IWindowContainer):IRegionWindow
        {
            return (this.cloneAndAdd(this._extraButtonTemplate, parent) as IRegionWindow);
        }

        private function cloneAndAdd(template:IWindow, parent:IWindowContainer):IWindow
        {
            var clone:IWindow;
            if (template == null)
            {
                return null;
            }
            clone = template.clone();
            if (clone != null)
            {
                parent.addChild(clone);
            }
            return clone;
        }
    }
}
