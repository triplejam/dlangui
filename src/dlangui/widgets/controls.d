// Written in the D programming language.

/**


This module contains simple controls widgets implementation.


TextWidget - static text

ImageWidget - image

Button - button with only text

ImageButton - button with only image

ImageTextButton - button with text and image

SwitchButton - switch widget

RadioButton - radio button

CheckBox - button with check mark

UrlImageTextButton - URL link button

CanvasWidget - for drawing arbitrary graphics


Note: ScrollBar and SliderWidget are moved to dlangui.widgets.scrollbar

Synopsis:

----
import dlangui.widgets.controls;

----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.widgets.controls;

import dlangui.widgets.widget;
import dlangui.widgets.layouts;
import dlangui.core.stdaction;

private import std.algorithm;
private import std.conv : to;
private import std.utf : toUTF32;

/// vertical spacer to fill empty space in vertical layouts
class VSpacer : Widget {
    this() {
        styleId = STYLE_VSPACER;
    }
}

/// horizontal spacer to fill empty space in horizontal layouts
class HSpacer : Widget {
    this() {
        styleId = STYLE_HSPACER;
    }
}

/// static text widget
class TextWidget : Widget {
    this(string ID = null, string textResourceId = null) {
        super(ID);
        styleId = STYLE_TEXT;
        _text.id = textResourceId;
        requestMeasureMinContent();
    }
    this(string ID, dstring rawText) {
        super(ID);
        styleId = STYLE_TEXT;
        _text.value = rawText;
        requestMeasureMinContent();
    }
    this(string ID, UIString uitext) {
        super(ID);
        styleId = STYLE_TEXT;
        _text = uitext;
        requestMeasureMinContent();
    }

    /// max lines to show
    @property int maxLines() { return style.maxLines; }
    /// set max lines to show
    @property TextWidget maxLines(int n) {
        ownStyle.maxLines = n;
        requestMeasureMinContent();
        return this;
    }

    protected UIString _text;
    /// get widget text
    override @property dstring text() const { return _text; }
    /// set text to show
    override @property Widget text(dstring s) { 
        _text = s; 
        requestMeasureMinContent();
        requestLayout();
        return this;
    }
    /// set text to show
    override @property Widget text(UIString s) { 
        _text = s;
        requestMeasureMinContent();
        requestLayout();
        return this;
    }
    /// set text resource ID to show
    @property Widget textResource(string s) { 
        _text = s; 
        requestMeasureMinContent();
        requestLayout();
        return this;
    }

    override void measureMinContentWidth() {
        if (maxLines == 1)
            measureMinContentSize();
        else
            _measuredMinContentWidth = _widthForMinContentSize;
    }

    override void measureMinContentHeight(int width) {
        if (maxLines == 1)
            return;

        if (!_needMeasureMinContent)
            return;
        Rect m = margins;
        Rect p = padding;
        int w = width;
        w -= m.left + m.right + p.left + p.right;

        Point sz;
        sz = font.measureMultilineText(text, maxLines, w, 4, 0, textFlags);
        
        _measuredMinContentHeight = sz.y;
        _needMeasureMinContent = false;
    }
    

    private int _widthForMinContentSize = 70;

    @property void widthForMinContentSize(int newWidth) {
        if (_widthForMinContentSize != newWidth) {
            _widthForMinContentSize = newWidth;
            if (maxLines != 1) {
                _needMeasureMinContent = true;
                //requestLayout();
            }
        }
    }
    
    override void measureMinContentSize() {
        if (!_needMeasureMinContent)
            return;

        Point sz;
        if (maxLines == 1) {
            FontRef font = font();

            sz = font.textSize(text, MAX_WIDTH_UNSPECIFIED, 4, 0, textFlags);
            _measuredMinContentWidth = sz.x;
            _measuredMinContentHeight = sz.y;
            _needMeasureMinContent = false;
            return;
        }
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        auto saver = ClipRectSaver(buf, rc, alpha);
        applyPadding(rc);

        FontRef font = font();
        if (maxLines == 1) {
            Point sz = font.textSize(text);
            applyAlign(rc, sz);
            font.drawText(buf, rc.left, rc.top, text, textColor, 4, 0, textFlags);
        } else {
            SimpleTextFormatter fmt;
            Point sz = fmt.format(text, font, maxLines, rc.width, 4, 0, textFlags);
            applyAlign(rc, sz);
            // TODO: apply align to alignment lines
            fmt.draw(buf, rc.left, rc.top, font, textColor);
        }
    }
}

/// static text widget with multiline text
class MultilineTextWidget : TextWidget {
    this(string ID = null, string textResourceId = null) {
        super(ID, textResourceId);
        layoutWidth(FILL_PARENT);
        styleId = STYLE_MULTILINE_TEXT;
    }
    this(string ID, dstring rawText) {
        super(ID, rawText);
        layoutWidth(FILL_PARENT);
        styleId = STYLE_MULTILINE_TEXT;
    }
    this(string ID, UIString uitext) {
        super(ID, uitext);
        layoutWidth(FILL_PARENT);
        styleId = STYLE_MULTILINE_TEXT;
    }
}

/// Switch (on/off) widget
class SwitchButton : Widget {
    this(string ID = null) {
        super(ID);
        styleId = STYLE_SWITCH;
        clickable = true;
        focusable = true;
        trackHover = true;
        requestMeasureMinContent();
    }
    // called to process click and notify listeners
    override protected bool handleClick() {
        checked = !checked;
        return super.handleClick();
    }

    override void measureMinContentWidth() {
        DrawableRef img = backgroundDrawable;
        _measuredMinContentWidth = 0;

        if (!img.isNull) {
            _measuredMinContentWidth = img.width;
        }
    }

    override void measureMinContentHeight(int width) {
        DrawableRef img = backgroundDrawable;
        _measuredMinContentHeight = 0;

        if (!img.isNull) {
            _measuredMinContentHeight = img.height;
        }
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        Rect rc = _pos;
        applyMargins(rc);
        auto saver = ClipRectSaver(buf, rc, alpha);
        DrawableRef img = backgroundDrawable;
        if (!img.isNull) {
            Point sz;
            sz.x = img.width;
            sz.y = img.height;
            applyAlign(rc, sz);
            uint st = state;
            img.drawTo(buf, rc, st);
        }
        _needDraw = false;
    }
}

/// static image widget
class ImageWidget : Widget {

    protected string _drawableId;
    protected DrawableRef _drawable;

    this(string ID = null, string drawableId = null) {
        super(ID);
        _drawableId = drawableId;
        requestMeasureMinContent();
    }

    ~this() {
        _drawable.clear();
    }

    /// get drawable image id
    @property string drawableId() { return _drawableId; }
    /// set drawable image id
    @property ImageWidget drawableId(string id) { 
        _drawableId = id;
        _drawable.clear();
        requestMeasureMinContent();
        requestLayout();
        return this;
    }
    /// get drawable
    @property ref DrawableRef drawable() {
        if (!_drawable.isNull)
            return _drawable;
        if (_drawableId !is null)
            _drawable = drawableCache.get(overrideCustomDrawableId(_drawableId));
        return _drawable;
    }
    /// set custom drawable (not one from resources)
    @property ImageWidget drawable(DrawableRef img) {
        _drawable = img;
        _drawableId = null;
        return this;
    }
    /// set custom drawable (not one from resources)
    @property ImageWidget drawable(string drawableId) {
        if (_drawableId.equal(drawableId))
            return this;
        _drawableId = drawableId; 
        _drawable.clear();
        requestMeasureMinContent();
        requestLayout();
        return this;
    }

    /// set string property value, for ML loaders
    mixin(generatePropertySettersMethodOverride("setStringProperty", "string",
          "drawableId"));

    /// handle theme change: e.g. reload some themed resources
    override void onThemeChanged() {
        super.onThemeChanged();
        if (_drawableId !is null)
            _drawable.clear(); // remove cached drawable
    }

    override void measureMinContentWidth() {
        DrawableRef img = drawable;
        _measuredMinContentWidth = 0;

        if (!img.isNull) {
            _measuredMinContentWidth = img.width;
        }
    }

    override void measureMinContentHeight(int width) {
        DrawableRef img = drawable;
        _measuredMinContentHeight = 0;

        if (!img.isNull) {
            _measuredMinContentHeight = img.height;
        }
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        auto saver = ClipRectSaver(buf, rc, alpha);
        applyPadding(rc);
        DrawableRef img = drawable;
        if (!img.isNull) {
            Point sz;
            sz.x = img.width;
            sz.y = img.height;
            applyAlign(rc, sz);
            uint st = state;
            img.drawTo(buf, rc, st);
        }
    }
}

/// button with image only
class ImageButton : ImageWidget {
    /// constructor by id and icon resource id
    this(string ID = null, string drawableId = null) {
        super(ID, drawableId);
        styleId = STYLE_BUTTON;
        _drawableId = drawableId;
        clickable = true;
        focusable = true;
        trackHover = true;
    }
    /// constructor from action
    this(const Action a) {
        this("imagebutton-action" ~ to!string(a.id), a.iconId);
        action = a;
    }
}

/// button with image working as trigger: check / uncheck occurs when pressing
class ImageCheckButton : ImageButton {
    /// constructor by id and icon resource id
    this(string ID = null, string drawableId = null) {
        super(ID, drawableId);
        styleId = "BUTTON_CHECK_TRANSPARENT";
    }
    /// constructor from action
    this(const Action a) {
        super(a);
        styleId = "BUTTON_CHECK_TRANSPARENT";
    }

    // called to process click and notify listeners
    override protected bool handleClick() {
        checked = !checked;
        return super.handleClick();
    }
}

/// button with image and text
class ImageTextButton : HorizontalLayout {
    protected ImageWidget _icon;
    protected TextWidget _label;

    /// Get label text
    override @property dstring text() const { return _label.text; }
    /// Set label plain unicode string
    override @property Widget text(dstring s) { _label.text = s; requestLayout(); return this; }
    /// Set label string resource Id
    override @property Widget text(UIString s) { _label.text = s; requestLayout(); return this; }
    /// get text color (ARGB 32 bit value)
    override @property uint textColor() const { return _label.textColor; }
    /// set text color for widget - from string like "#5599CC" or "white"
    override @property Widget textColor(string colorString) { _label.textColor(colorString); return this; }
    /// set text color (ARGB 32 bit value)
    override @property Widget textColor(uint value) { _label.textColor(value); return this; }
    /// get text flags (bit set of TextFlag enum values)
    override @property uint textFlags() { return _label.textFlags(); }
    /// set text flags (bit set of TextFlag enum values)
    override @property Widget textFlags(uint value) { _label.textFlags(value); return this; }
    /// returns font face
    override @property string fontFace() const { return _label.fontFace(); }
    /// set font face for widget - override one from style
    override @property Widget fontFace(string face) { _label.fontFace(face); return this; }
    /// returns font style (italic/normal)
    override @property bool fontItalic() const { return _label.fontItalic; }
    /// set font style (italic/normal) for widget - override one from style
    override @property Widget fontItalic(bool italic) { _label.fontItalic(italic); return this; }
    /// returns font weight
    override @property ushort fontWeight() const { return _label.fontWeight; }
    /// set font weight for widget - override one from style
    override @property Widget fontWeight(int weight) { _label.fontWeight(weight); return this; }
    /// returns font size in pixels
    override @property int fontSize() const { return _label.fontSize; }
    /// Set label font size 
    override @property Widget fontSize(int size) { _label.fontSize(size); return this; }
    /// returns font family
    override @property FontFamily fontFamily() const { return _label.fontFamily; }
    /// set font family for widget - override one from style
    override @property Widget fontFamily(FontFamily family) { _label.fontFamily(family); return this; }
    /// returns font set for widget using style or set manually
    override @property FontRef font() const { return _label.font; }

    /// Returns orientation: Vertical - image top, Horizontal - image left"
    override @property Orientation orientation() const {
        return super.orientation();
    }

    /// Sets orientation: Vertical - image top, Horizontal - image left"
    override @property LinearLayout orientation(Orientation value) {
        if (!_icon || !_label)
            return super.orientation(value);
        if (value != orientation) {
            updateOrientation(value);
        }
        return this; 
    }

    protected void updateOrientation(Orientation value) {
        super.orientation(value);

        final switch(value) {
            case Orientation.Horizontal:
                alignment = Align.Left | Align.VCenter;
                if (_label)
                    _label.alignment = Align.Left | Align.VCenter;
                break;
            case Orientation.Vertical:
                alignment = Align.HCenter | Align.VCenter;
                if (_label)
                    _label.alignment = Align.HCenter | Align.VCenter;
                
                break;
        }
    }

    @property bool wordWrap() {
//        if(!_label)
//            return false;

        return (_label.maxLines==0);
    }

    @property void wordWrap(bool newWordWrap) {
        if (wordWrap != newWordWrap) {
            if (newWordWrap) {
                _label.maxLines = 0;
                layoutWidth(FILL_PARENT);
            }
            else {
                _label.maxLines = 1;
            }
        }
        requestLayout();
    }
    
    protected void initialize(string drawableId, UIString caption) {
        styleId = STYLE_BUTTON;
        _icon = new ImageWidget("icon", drawableId);
        _icon.styleId = STYLE_BUTTON_IMAGE;
        _label = new TextWidget("label", caption);
        _label.styleId = STYLE_BUTTON_LABEL;
        _icon.state = State.Parent;
        _label.state = State.Parent;
        _label.layoutWidth(FILL_PARENT);
        addChild(_icon);
        addChild(_label);
        clickable = true;
        focusable = true;
        trackHover = true;
        updateOrientation(_orientation);
        wordWrap = false;
    }

    this(string ID = null, string drawableId = null, string textResourceId = null) {
        super(ID);
        initialize(drawableId, UIString.fromId(textResourceId));
    }

    this(string ID, string drawableId, dstring rawText) {
        super(ID);
        initialize(drawableId, UIString.fromRaw(rawText));
    }

    /// constructor from action
    this(const Action a) {
        super("imagetextbutton-action" ~ to!string(a.id));
        initialize(a.iconId, a.labelValue);
        action = a;
    }

}

/// button - url
class UrlImageTextButton : ImageTextButton {
    this(string ID, dstring labelText, string url, string icon = "applications-internet") {
        super(ID, icon, labelText);
        Action a = ACTION_OPEN_URL.clone();
        a.label = labelText;
        a.stringParam = url;
        _action = a;
        styleId = null;
        //_icon.styleId = STYLE_BUTTON_IMAGE;
        //_label.styleId = STYLE_BUTTON_LABEL;
        //_label.textFlags(TextFlag.Underline);
        _label.styleId = "BUTTON_LABEL_LINK";
        _label.resetStyle();
        updateOrientation(orientation);
        static if (BACKEND_GUI) padding(Rect(3,3,3,3));
    }
}

/// button looking like URL, executing specified action
class LinkButton : ImageTextButton {
    this(Action a) {
        super(a);
        styleId = null;
        _label.styleId = "BUTTON_LABEL_LINK";
        static if (BACKEND_GUI) padding(Rect(3,3,3,3));
    }
}


/// checkbox
class CheckBox : ImageTextButton {
    this(string ID = null, string textResourceId = null) {
        super(ID, "btn_check", textResourceId);
    }
    this(string ID, dstring labelText) {
        super(ID, "btn_check", labelText);
    }
    this(string ID, UIString label) {
        super(ID, "btn_check", label);
    }
    override protected void initialize(string drawableId, UIString caption) {
        super.initialize(drawableId, caption);
        styleId = STYLE_CHECKBOX;
        if (_icon)
            _icon.styleId = STYLE_CHECKBOX_IMAGE;
        if (_label)
            _label.styleId = STYLE_CHECKBOX_LABEL;
        checkable = true;
    }
    // called to process click and notify listeners
    override protected bool handleClick() {
        checked = !checked;
        return super.handleClick();
    }
}

/// radio button
class RadioButton : ImageTextButton {
    this(string ID = null, string textResourceId = null) {
        super(ID, "btn_radio", textResourceId);
    }
    this(string ID, dstring labelText) {
        super(ID, "btn_radio", labelText);
    }
    override protected void initialize(string drawableId, UIString caption) {
        super.initialize(drawableId, caption);
        styleId = STYLE_RADIOBUTTON;
        if (_icon)
            _icon.styleId = STYLE_RADIOBUTTON_IMAGE;
        if (_label)
            _label.styleId = STYLE_RADIOBUTTON_LABEL;
        checkable = true;
    }

    private bool blockUnchecking = false;
    
    void uncheckSiblings() {
        Widget p = parent;
        if (!p)
            return;
        for (int i = 0; i < p.childCount; i++) {
            Widget child = p.child(i);
            if (child is this)
                continue;
            RadioButton rb = cast(RadioButton)child;
            if (rb) {
                rb.blockUnchecking = true;
                scope(exit) rb.blockUnchecking = false;
                rb.checked = false;
            }
        }
    }

    // called to process click and notify listeners
    override protected bool handleClick() {
        uncheckSiblings();
        checked = true;

        return super.handleClick();
    }
    
    override protected void handleCheckChange(bool checked) {
        if (!blockUnchecking)
            uncheckSiblings();
        invalidate();
        checkChange(this, checked);
    }
    
}

/// Text only button
class Button : Widget {
    protected UIString _text;
    override @property dstring text() const { return _text; }
    override @property Widget text(dstring s) { _text = s; requestMeasureMinContent(); requestLayout(); return this; }
    override @property Widget text(UIString s) { _text = s; requestMeasureMinContent(); requestLayout(); return this; }
    @property Widget textResource(string s) { _text = s; requestMeasureMinContent(); requestLayout(); return this; }
    /// empty parameter list constructor - for usage by factory
    this() {
        super(null);
        initialize(UIString());
    }

    private void initialize(UIString label) {
        styleId = STYLE_BUTTON;
        _text = label;
        clickable = true;
        focusable = true;
        trackHover = true;
        requestMeasureMinContent();
    }

    /// create with ID parameter
    this(string ID) {
        super(ID);
        initialize(UIString());
    }
    this(string ID, UIString label) {
        super(ID);
        initialize(label);
    }
    this(string ID, dstring label) {
        super(ID);
        initialize(UIString.fromRaw(label));
    }
    this(string ID, string labelResourceId) {
        super(ID);
        initialize(UIString.fromId(labelResourceId));
    }
    /// constructor from action
    this(const Action a) {
        this("button-action" ~ to!string(a.id), a.labelValue);
        action = a;
    }

    override void measureMinContentSize() {
        if (!_needMeasureMinContent)
            return;
            
        FontRef font = font();
        Point sz = font.textSize(text);

        _measuredMinContentWidth = sz.x;
        _measuredMinContentHeight = sz.y;
        _needMeasureMinContent = false;
    }

    override void measureMinContentWidth() {
        measureMinContentSize();
    }

    override void measureMinContentHeight(int width) {
        measureMinContentSize();
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        //buf.fillRect(_pos, backgroundColor);
        applyPadding(rc);
        auto saver = ClipRectSaver(buf, rc, alpha);
        FontRef font = font();
        Point sz = font.textSize(text);
        applyAlign(rc, sz);
        font.drawText(buf, rc.left, rc.top, text, textColor, 4, 0, textFlags);
    }

}


/// interface - slot for onClick
interface OnDrawHandler {
    void doDraw(CanvasWidget canvas, DrawBuf buf, Rect rc);
}

/// canvas widget - draw on it either by overriding of doDraw() or by assigning of onDrawListener
class CanvasWidget : Widget {
    
    Listener!OnDrawHandler onDrawListener;

    this(string ID = null) {
        super(ID);
    }

    void doDraw(DrawBuf buf, Rect rc) {
        if (onDrawListener.assigned)
            onDrawListener(this, buf, rc);
    }

    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        auto saver = ClipRectSaver(buf, rc, alpha);
        applyPadding(rc);
        doDraw(buf, rc);
    }
}

//import dlangui.widgets.metadata;
//mixin(registerWidgets!(Widget, TextWidget, MultilineTextWidget, Button, ImageWidget, ImageButton, ImageCheckButton, ImageTextButton, RadioButton, CheckBox, ScrollBar, HSpacer, VSpacer, CanvasWidget)());
