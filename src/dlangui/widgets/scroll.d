// Written in the D programming language.

/**

This module contains base implementation of scrolling capabilities for widgets


ScrollWidgetBase - abstract scrollable widget (used as a base for other widgets with scrolling)

ScrollWidget - widget which can scroll its content (directly usable class)


Synopsis:

----
import dlangui.widgets.scroll;

// Scroll view example
ScrollWidget scroll = new ScrollWidget("SCROLL1");
scroll.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
WidgetGroup scrollContent = new VerticalLayout("CONTENT");
scrollContent.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);

TableLayout table2 = new TableLayout("TABLE2");
table2.colCount = 2;
// headers
table2.addChild((new TextWidget(null, "Parameter Name"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new TextWidget(null, "Edit Box to edit parameter"d)).alignment(Align.Left | Align.VCenter));
// row 1
table2.addChild((new TextWidget(null, "Parameter 1 name"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit1", "Text 1"d)).layoutWidth(FILL_PARENT));
// row 2
table2.addChild((new TextWidget(null, "Parameter 2 name bla bla"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit2", "Some text for parameter 2 blah blah blah"d)).layoutWidth(FILL_PARENT));
// row 3
table2.addChild((new TextWidget(null, "Param 3"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 3 value"d)).layoutWidth(FILL_PARENT));
// row 4
table2.addChild((new TextWidget(null, "Param 4"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 4 value shdjksdfh hsjdfas hdjkf hdjsfk ah"d)).layoutWidth(FILL_PARENT));
// row 5
table2.addChild((new TextWidget(null, "Param 5 - edit text here - blah blah blah"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 5 value"d)).layoutWidth(FILL_PARENT));
// row 6
table2.addChild((new TextWidget(null, "Param 6 - just to fill content widget"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 5 value"d)).layoutWidth(FILL_PARENT));
// row 7
table2.addChild((new TextWidget(null, "Param 7 - just to fill content widget"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 5 value"d)).layoutWidth(FILL_PARENT));
// row 8
table2.addChild((new TextWidget(null, "Param 8 - just to fill content widget"d)).alignment(Align.Right | Align.VCenter));
table2.addChild((new EditLine("edit3", "Parameter 5 value"d)).layoutWidth(FILL_PARENT));
table2.margins(Rect(10,10,10,10)).layoutWidth(FILL_PARENT);
scrollContent.addChild(table2);

scrollContent.addChild(new TextWidget(null, "Now - some buttons"d));
scrollContent.addChild(new ImageTextButton("btn1", "fileclose", "Close"d));
scrollContent.addChild(new ImageTextButton("btn2", "fileopen", "Open"d));
scrollContent.addChild(new TextWidget(null, "And checkboxes"d));
scrollContent.addChild(new CheckBox("btn1", "CheckBox 1"d));
scrollContent.addChild(new CheckBox("btn2", "CheckBox 2"d));

scroll.contentWidget = scrollContent;

----

Copyright: Vadim Lopatin, 2014
License:   Boost License 1.0
Authors:   Vadim Lopatin, coolreader.org@gmail.com
*/
module dlangui.widgets.scroll;

import dlangui.widgets.widget;
import dlangui.widgets.controls;
import dlangui.widgets.scrollbar;
import std.conv;

/** Scroll bar visibility mode. */
enum ScrollBarMode {
    /** always invisible */
    Invisible,
    /** always visible */
    Visible,
    /** automatically show/hide scrollbar depending on content size */
    Auto,
    /** Scrollbar is provided by external control outside this widget */
    External,
}

/**
    Abstract scrollable widget

    Provides scroll bars and basic scrolling functionality.

 */
class ScrollWidgetBase :  WidgetGroup, OnScrollHandler {
    protected ScrollBarMode _vscrollbarMode;
    protected ScrollBarMode _hscrollbarMode;
    /// vertical scrollbar control
    protected ScrollBar _vscrollbar;
    /// horizontal scrollbar control
    protected ScrollBar _hscrollbar;
    /// inner area, excluding additional controls like scrollbars
    protected Rect _clientRect;

    protected Rect _fullScrollableArea;
    protected Rect _visibleScrollableArea;

    this(string ID = null, ScrollBarMode hscrollbarMode = ScrollBarMode.Visible, ScrollBarMode vscrollbarMode = ScrollBarMode.Visible) {
        super(ID);
        _hscrollbarMode = hscrollbarMode;
        _vscrollbarMode = vscrollbarMode;
        if (_vscrollbarMode != ScrollBarMode.Invisible) {
            _vscrollbar = new ScrollBar("vscrollbar", Orientation.Vertical);
            _vscrollbar.scrollEvent = this;
            addChild(_vscrollbar);
        }
        if (_hscrollbarMode != ScrollBarMode.Invisible) {
            _hscrollbar = new ScrollBar("hscrollbar", Orientation.Horizontal);
            _hscrollbar.scrollEvent = this;
            addChild(_hscrollbar);
        }
    }

    /// vertical scrollbar mode
    @property ScrollBarMode vscrollbarMode() { return _vscrollbarMode; }
    @property void vscrollbarMode(ScrollBarMode m) { _vscrollbarMode = m; }
    /// horizontal scrollbar mode
    @property ScrollBarMode hscrollbarMode() { return _hscrollbarMode; }
    @property void hscrollbarMode(ScrollBarMode m) { _hscrollbarMode = m; }

    /// returns client area rectangle
    @property Rect clientRect() { return _clientRect; }

    /// process horizontal scrollbar event
    bool onHScroll(ScrollEvent event) {
        return true;
    }

    /// process vertical scrollbar event
    bool onVScroll(ScrollEvent event) {
        return true;
    }

    /// process mouse event; return true if event is processed by widget.
    override bool onMouseEvent(MouseEvent event) {
        if (event.action == MouseAction.Wheel) {
            if (event.flags == MouseFlag.Shift) {
                if (_hscrollbar) {
                    _hscrollbar.sendScrollEvent(event.wheelDelta > 0 ? ScrollAction.LineUp : ScrollAction.LineDown);
                    return true;
                }
            } else if (event.flags == 0) {
                if (_vscrollbar) {
                    _vscrollbar.sendScrollEvent(event.wheelDelta > 0 ? ScrollAction.LineUp : ScrollAction.LineDown);
                    return true;
                }
            }
        }
        return super.onMouseEvent(event);
    }

    /// handle scroll event
    override bool onScrollEvent(AbstractSlider source, ScrollEvent event) {
        if (source.orientation == Orientation.Horizontal) {
            return onHScroll(event);
        } else {
            return onVScroll(event);
        }
    }

    protected bool _insideChangeScrollbarVisibility;
    protected void checkIfNeededToChangeScrollbarVisibility() {
        if (_insideChangeScrollbarVisibility)
            return;
        bool needHScroll = false;
        bool needVScroll = false;
        checkIfScrollbarsNeeded(needHScroll, needVScroll);
        bool hscrollVisible = _hscrollbar && _hscrollbar.visibility == Visibility.Visible;
        bool vscrollVisible = _vscrollbar && _vscrollbar.visibility == Visibility.Visible;
        bool needChange = false;
        if (_hscrollbar && hscrollVisible != needHScroll)
            needChange = true;
        if (_vscrollbar && vscrollVisible != needVScroll)
            needChange = true;
        if (needChange) {
            _insideChangeScrollbarVisibility = true;
            layout(_pos);
            _insideChangeScrollbarVisibility = false;
        }
    }

    /// update scrollbar positions
    protected void updateScrollBars() {
        if (_hscrollbar) {
            updateHScrollBar();
        }
        if (_vscrollbar) {
            updateVScrollBar();
        }
        checkIfNeededToChangeScrollbarVisibility();
    }

    public @property ScrollBar hscrollbar() { return _hscrollbar; }
    public @property ScrollBar vscrollbar() { return _vscrollbar; }

    public @property void hscrollbar(ScrollBar hscroll) {
        if (_hscrollbar) {
            removeChild(_hscrollbar);
            destroy(_hscrollbar);
            _hscrollbar = null;
            _hscrollbarMode = ScrollBarMode.Invisible;
        }
        if (hscroll) {
            _hscrollbar = hscroll;
            _hscrollbarMode = ScrollBarMode.External;
        }
    }

    public @property void vscrollbar(ScrollBar vscroll) {
        if (_vscrollbar) {
            removeChild(_vscrollbar);
            destroy(_vscrollbar);
            _vscrollbar = null;
            _vscrollbarMode = ScrollBarMode.Invisible;
        }
        if (vscroll) {
            _vscrollbar = vscroll;
            _vscrollbarMode = ScrollBarMode.External;
        }
    }

    /// update horizontal scrollbar widget position
    protected void updateHScrollBar() {
        // default implementation: use _fullScrollableArea, _visibleScrollableArea: override it if necessary
        _hscrollbar.setRange(0, _fullScrollableArea.width);
        _hscrollbar.pageSize(_visibleScrollableArea.width);
        _hscrollbar.position(_visibleScrollableArea.left - _fullScrollableArea.left);
    }

    /// update verticat scrollbar widget position
    protected void updateVScrollBar() {
        // default implementation: use _fullScrollableArea, _visibleScrollableArea: override it if necessary
        _vscrollbar.setRange(0, _fullScrollableArea.height);
        _vscrollbar.pageSize(_visibleScrollableArea.height);
        _vscrollbar.position(_visibleScrollableArea.top - _fullScrollableArea.top);
    }

    protected void drawClient(DrawBuf buf) {
        // override it
    }

    protected void drawExtendedArea(DrawBuf buf) {
    }

    /// Draw widget at its position to buffer
    override void onDraw(DrawBuf buf) {
        if (visibility != Visibility.Visible)
            return;
        super.onDraw(buf);
        Rect rc = _pos;
        applyMargins(rc);
        {
            auto saver = ClipRectSaver(buf, rc, alpha);
            DrawableRef bg = backgroundDrawable;
            if (!bg.isNull) {
                bg.drawTo(buf, rc, state);
            }
            applyPadding(rc);
            if (_hscrollbar)
                _hscrollbar.onDraw(buf);
            if (_vscrollbar)
                _vscrollbar.onDraw(buf);
            // apply clipping
            {
                auto saver2 = ClipRectSaver(buf, _clientRect, alpha);
                drawClient(buf);
            }
            {
                // no clipping for drawing of extended area
                Rect clipr = rc;
                clipr.bottom = _clientRect.bottom;
                auto saver3 = ClipRectSaver(buf, clipr, alpha);
                drawExtendedArea(buf);
            }
        }

        _needDraw = false;
    }

    /// calculate full content size in pixels
    Point fullContentSize() {
        // override it
        Point sz;
        return sz;
    }

    /// calculate full content size in pixels including widget borders / margins
    Point fullContentSizeWithBorders() {
        Point sz = fullContentSize;
        Rect paddingrc = padding;
        Rect marginsrc = margins;
        sz.x += paddingrc.left + paddingrc.right + marginsrc.left + marginsrc.right;
        sz.y += paddingrc.top + paddingrc.bottom + marginsrc.top + marginsrc.bottom;
        return sz;
    }

    override void measureMinSize() {
        adjustMeasuredMinSize(100, 100);
    }

    /// Measure widget according to desired width and height constraints. (Step 1 of two phase layout).
    override void measureSize(int parentWidth, int parentHeight) {
        if (visibility == Visibility.Gone) {
            return;
        }
        Rect m = margins;
        Rect p = padding;

        // calc size constraints for children
        int pwidth = parentWidth;
        int pheight = parentHeight;
        if (parentWidth != SIZE_UNSPECIFIED)
            pwidth -= m.left + m.right + p.left + p.right;
        if (parentHeight != SIZE_UNSPECIFIED)
            pheight -= m.top + m.bottom + p.top + p.bottom;
        int vsbw = 0;
        int hsbh = 0;
        if (_hscrollbar && (_hscrollbarMode == ScrollBarMode.Visible || _hscrollbarMode == ScrollBarMode.Auto)) {
            Visibility oldVisibility = _hscrollbar.visibility;
            _hscrollbar.visibility = Visibility.Visible;
            _hscrollbar.measureSize(pwidth, pheight);
            hsbh = _hscrollbar.measuredHeight;
            _hscrollbar.visibility = oldVisibility;
        }
        if (_vscrollbar && (_vscrollbarMode == ScrollBarMode.Visible || _vscrollbarMode == ScrollBarMode.Auto)) {
            Visibility oldVisibility = _vscrollbar.visibility;
            _vscrollbar.visibility = Visibility.Visible;
            _vscrollbar.measureSize(pwidth, pheight);
            vsbw = _vscrollbar.measuredWidth;
            _vscrollbar.visibility = oldVisibility;
        }
        adjustMeasuredSize(parentWidth, parentHeight, _measuredMinWidth + vsbw, _measuredMinHeight + hsbh);
    }

    /// override to support modification of client rect after change, e.g. apply offset
    protected void handleClientRectLayout(ref Rect rc) {
    }

    /// override to determine if scrollbars are needed or not
    protected void checkIfScrollbarsNeeded(ref bool needHScroll, ref bool needVScroll) {
        needHScroll = _hscrollbar && (_hscrollbarMode == ScrollBarMode.Visible || _hscrollbarMode == ScrollBarMode.Auto);
        needVScroll = _vscrollbar && (_vscrollbarMode == ScrollBarMode.Visible || _vscrollbarMode == ScrollBarMode.Auto);
        if (!needHScroll && !needVScroll)
            return; // not needed
        if (_hscrollbarMode != ScrollBarMode.Auto && _vscrollbarMode != ScrollBarMode.Auto)
            return; // no auto scrollbars
        // either h or v scrollbar is in auto mode
        Point contentSize = fullContentSize();
        int contentWidth = contentSize.x;
        int contentHeight = contentSize.y;
        int clientWidth = _clientRect.width;
        int clientHeight = _clientRect.height;

        int hsbHeight = _hscrollbar.measuredHeight;
        int vsbWidth = _hscrollbar.measuredWidth;

        int clientWidthWithScrollbar = clientWidth - vsbWidth;
        int clientHeightWithScrollbar = clientHeight - hsbHeight;

        if (_hscrollbarMode == ScrollBarMode.Auto && _vscrollbarMode == ScrollBarMode.Auto) {
            // both scrollbars in auto mode
            bool xFits = contentWidth <= clientWidth;
            bool yFits = contentHeight <= clientHeight;
            if (!xFits && !yFits) {
                // none fits, need both scrollbars
            } else if (xFits && yFits) {
                // everything fits!
                needHScroll = false;
                needVScroll = false;
            } else if (xFits) {
                // only X fits
                if (contentWidth <= clientWidthWithScrollbar)
                    needHScroll = false; // disable hscroll
            } else { // yFits
                // only Y fits
                if (contentHeight <= clientHeightWithScrollbar)
                    needVScroll = false; // disable vscroll
            }
        } else if (_hscrollbarMode == ScrollBarMode.Auto) {
            // only hscroll is in auto mode
            if (needVScroll)
                clientWidth = clientWidthWithScrollbar;
            needHScroll = contentWidth > clientWidth;
        } else {
            // only vscroll is in auto mode
            if (needHScroll)
                clientHeight = clientHeightWithScrollbar;
            needVScroll = contentHeight > clientHeight;
        }
    }

    /// Set widget rectangle to specified value and layout widget contents. (Step 2 of two phase layout).
    override void layout(Rect rc) {
        if (visibility == Visibility.Gone) {
            return;
        }
        _pos = rc;
        _needLayout = false;
        applyMargins(rc);
        applyPadding(rc);

        // client area - initial setup w/o scrollbars
        _clientRect = rc;
        handleClientRectLayout(_clientRect);

        bool needHscroll;
        bool needVscroll;

        checkIfScrollbarsNeeded(needHscroll, needVscroll);

        // scrollbars
        Rect vsbrc = rc;
        vsbrc.left = vsbrc.right - (needVscroll ? _vscrollbar.measuredWidth : 0);
        vsbrc.bottom = vsbrc.bottom - (needHscroll ? _hscrollbar.measuredHeight : 0);
        Rect hsbrc = rc;
        hsbrc.right = hsbrc.right - (needVscroll ? _vscrollbar.measuredWidth : 0);
        hsbrc.top = hsbrc.bottom - (needHscroll ? _hscrollbar.measuredHeight : 0);
        if (_vscrollbar && _vscrollbarMode != ScrollBarMode.External) {
            _vscrollbar.visibility = needVscroll ? Visibility.Visible : Visibility.Gone;
            _vscrollbar.layout(vsbrc);
        }
        if (_hscrollbar && _hscrollbarMode != ScrollBarMode.External) {
            _hscrollbar.visibility = needHscroll ? Visibility.Visible : Visibility.Gone;
            _hscrollbar.layout(hsbrc);
        }

        _clientRect = rc;
        if (needVscroll)
            _clientRect.right = vsbrc.left;
        if (needHscroll)
            _clientRect.bottom = hsbrc.top;
        handleClientRectLayout(_clientRect);
        updateScrollBars();
    }

    void makeRectVisible(Rect rc, bool alignHorizontally = true, bool alignVertically = true) {
        if (rc.isInsideOf(_visibleScrollableArea))
            return;
        Rect oldRect = _visibleScrollableArea;
        if (alignHorizontally && rc.right > _visibleScrollableArea.right)
            _visibleScrollableArea.offset(rc.right - _visibleScrollableArea.right, 0);
        if (alignVertically && rc.bottom > _visibleScrollableArea.bottom)
            _visibleScrollableArea.offset(0, rc.bottom - _visibleScrollableArea.bottom);
        if (alignHorizontally && rc.left < _visibleScrollableArea.left)
            _visibleScrollableArea.offset(rc.left - _visibleScrollableArea.left, 0);
        if (alignVertically && rc.top < _visibleScrollableArea.top)
            _visibleScrollableArea.offset(0, rc.top - _visibleScrollableArea.top);
        if (_visibleScrollableArea != oldRect)
            requestLayout();
    }
}

/**
    Widget which can show content of widget group with optional scrolling

    If size of content widget exceeds available space, allows to scroll it.
 */
class ScrollWidget :  ScrollWidgetBase {
    protected Widget _contentWidget;
    @property Widget contentWidget() { return _contentWidget; }
    @property ScrollWidget contentWidget(Widget newContent) {
        if (_contentWidget) {
            removeChild(childIndex(_contentWidget));
            destroy(_contentWidget);
        }
        _contentWidget = newContent;
        addChild(_contentWidget);
        requestLayout();
        return this;
    }
    /// empty parameter list constructor - for usage by factory
    this() {
        this(null);
    }
    /// create with ID parameter
    this(string ID, ScrollBarMode hscrollbarMode = ScrollBarMode.Visible, ScrollBarMode vscrollbarMode = ScrollBarMode.Visible) {
        super(ID, hscrollbarMode, vscrollbarMode);
    }

    /// calculate full content size in pixels
    override Point fullContentSize() {
        // override it
        Point sz;
        if (_contentWidget) {
            _contentWidget.measureMinSize();
            _contentWidget.measureSize(_contentWidget.measuredMinWidth, _contentWidget.measuredMinHeight);
            //sz.x = _contentWidget.measuredMinWidth;
            //sz.y = _contentWidget.measuredMinHeight;
            sz.x = _contentWidget.measuredWidth;
            sz.y = _contentWidget.measuredHeight;
            
        }
        _fullScrollableArea.right = sz.x;
        _fullScrollableArea.bottom = sz.y;
        return sz;
    }

    /// update scrollbar positions
    override protected void updateScrollBars() {
        Point sz = fullContentSize();
        _visibleScrollableArea.right = _visibleScrollableArea.left + _clientRect.width;
        _visibleScrollableArea.bottom = _visibleScrollableArea.top + _clientRect.height;
        // move back if scroll is too big after window resize
        int extrax = _visibleScrollableArea.right - _fullScrollableArea.right;
        int extray = _visibleScrollableArea.bottom - _fullScrollableArea.bottom;
        if (extrax > _visibleScrollableArea.left)
            extrax = _visibleScrollableArea.left;
        if (extray > _visibleScrollableArea.top)
            extray = _visibleScrollableArea.top;
        if (extrax < 0)
            extrax = 0;
        if (extray < 0)
            extray = 0;
        _visibleScrollableArea.offset(-extrax, -extray);
        super.updateScrollBars();
    }

    override protected void drawClient(DrawBuf buf) {
        if (_contentWidget) {
            Point sz = fullContentSize();
            Point p = scrollPos;
            _contentWidget.layout(Rect(_clientRect.left - p.x, _clientRect.top - p.y, _clientRect.left + sz.x - p.x, _clientRect.top + sz.y - p.y));
            _contentWidget.onDraw(buf);
        }
    }


    @property Point scrollPos() {
        return Point(_visibleScrollableArea.left - _fullScrollableArea.left, _visibleScrollableArea.top - _fullScrollableArea.top);
    }

    protected void scrollTo(int x, int y) {
        if (x > _fullScrollableArea.right - _visibleScrollableArea.width)
            x = _fullScrollableArea.right - _visibleScrollableArea.width;
        if (y > _fullScrollableArea.bottom - _visibleScrollableArea.height)
            y = _fullScrollableArea.bottom - _visibleScrollableArea.height;
        if (x < 0)
            x = 0;
        if (y < 0)
            y = 0;
        _visibleScrollableArea.left = x;
        _visibleScrollableArea.top = y;
        updateScrollBars();
        invalidate();
    }

    /// process horizontal scrollbar event
    override bool onHScroll(ScrollEvent event) {
        if (event.action == ScrollAction.SliderMoved || event.action == ScrollAction.SliderReleased) {
            scrollTo(event.position, scrollPos.y);
        } else if (event.action == ScrollAction.PageUp) {
            scrollTo(scrollPos.x - _clientRect.width * 3 / 4, scrollPos.y);
        } else if (event.action == ScrollAction.PageDown) {
            scrollTo(scrollPos.x + _clientRect.width * 3 / 4, scrollPos.y);
        } else if (event.action == ScrollAction.LineUp) {
            scrollTo(scrollPos.x - _clientRect.width / 10, scrollPos.y);
        } else if (event.action == ScrollAction.LineDown) {
            scrollTo(scrollPos.x + _clientRect.width / 10, scrollPos.y);
        }
        return true;
    }

    /// process vertical scrollbar event
    override bool onVScroll(ScrollEvent event) {
        if (event.action == ScrollAction.SliderMoved || event.action == ScrollAction.SliderReleased) {
            scrollTo(scrollPos.x, event.position);
        } else if (event.action == ScrollAction.PageUp) {
            scrollTo(scrollPos.x, scrollPos.y - _clientRect.height * 3 / 4);
        } else if (event.action == ScrollAction.PageDown) {
            scrollTo(scrollPos.x, scrollPos.y + _clientRect.height * 3 / 4);
        } else if (event.action == ScrollAction.LineUp) {
            scrollTo(scrollPos.x, scrollPos.y - _clientRect.height / 10);
        } else if (event.action == ScrollAction.LineDown) {
            scrollTo(scrollPos.x, scrollPos.y + _clientRect.height / 10);        }
        return true;
    }

    void makeWidgetVisible(Widget widget, bool alignHorizontally = true, bool alignVertically = true) {
        if (!widget || !widget.visibility == Visibility.Gone)
            return;
        if (!_contentWidget || !_contentWidget.isChild(widget))
            return;
        Rect wpos = widget.pos;
        Rect cpos = _contentWidget.pos;
        wpos.offset(-cpos.left, -cpos.top);
        makeRectVisible(wpos, alignHorizontally, alignVertically);
    }
}
