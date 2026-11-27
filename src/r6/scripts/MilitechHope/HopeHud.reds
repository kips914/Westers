// Militech "Hope" Sandevistan — on-screen widgets (Codeware ink API):
//   * heat gauge in degrees Celsius (left side of the HUD)
//   * broker menu (opened with the call hotkey once the broker's number is known)
module MilitechHope

public class HopeHud {
    private let m_gauge: ref<inkCanvas>;
    private let m_title: ref<inkText>;
    private let m_temp: ref<inkText>;
    private let m_barBack: ref<inkRectangle>;
    private let m_barFill: ref<inkRectangle>;
    private let m_state: ref<inkText>;
    private let m_info: ref<inkText>;

    private let m_menu: ref<inkCanvas>;
    private let m_menuBack: ref<inkRectangle>;
    private let m_menuTitle: ref<inkText>;
    private let m_menuRows: array<ref<inkText>>;
    private let m_menuFooter: ref<inkText>;
    private let m_menuHint: ref<inkText>;

    public static func Font() -> String {
        return "base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily";
    }

    public static func Rgb(r: Float, g: Float, b: Float, a: Float) -> HDRColor {
        let c: HDRColor;
        c.Red = r;
        c.Green = g;
        c.Blue = b;
        c.Alpha = a;
        return c;
    }

    public static func ColorNormal() -> HDRColor { return HopeHud.Rgb(0.37, 0.96, 1.0, 1.0); }
    public static func ColorWarm() -> HDRColor { return HopeHud.Rgb(1.0, 0.82, 0.25, 1.0); }
    public static func ColorHot() -> HDRColor { return HopeHud.Rgb(1.0, 0.3, 0.25, 1.0); }
    public static func ColorDim() -> HDRColor { return HopeHud.Rgb(0.75, 0.75, 0.75, 1.0); }
    public static func ColorSelected() -> HDRColor { return HopeHud.Rgb(1.0, 0.82, 0.25, 1.0); }

    // Forget every widget (the HUD layer is rebuilt on each game session).
    public func Reset() -> Void {
        this.m_gauge = null;
        this.m_title = null;
        this.m_temp = null;
        this.m_barBack = null;
        this.m_barFill = null;
        this.m_state = null;
        this.m_info = null;
        this.m_menu = null;
        this.m_menuBack = null;
        this.m_menuTitle = null;
        ArrayClear(this.m_menuRows);
        this.m_menuFooter = null;
        this.m_menuHint = null;
    }

    private func GetHudRoot() -> wref<inkCompoundWidget> {
        let ink = GameInstance.GetInkSystem();
        if !IsDefined(ink) {
            return null;
        }
        let layer = ink.GetLayer(n"inkHUDLayer");
        if !IsDefined(layer) {
            return null;
        }
        return layer.GetVirtualWindow();
    }

    private func MakeText(parent: ref<inkCanvas>, size: Int32, x: Float, y: Float) -> ref<inkText> {
        let text = new inkText();
        text.SetFontFamily(HopeHud.Font());
        text.SetFontStyle(n"Medium");
        text.SetFontSize(size);
        text.SetLetterCase(textLetterCase.OriginalCase);
        text.SetTintColor(HopeHud.ColorNormal());
        text.SetAnchor(inkEAnchor.TopLeft);
        text.SetAnchorPoint(0.0, 0.0);
        text.SetTranslation(x, y);
        text.SetFitToContent(true);
        text.SetText("");
        text.Reparent(parent);
        return text;
    }

    private func MakeRect(parent: ref<inkCanvas>, x: Float, y: Float, w: Float, h: Float, color: HDRColor) -> ref<inkRectangle> {
        let rect = new inkRectangle();
        rect.SetAnchor(inkEAnchor.TopLeft);
        rect.SetAnchorPoint(0.0, 0.0);
        rect.SetSize(w, h);
        rect.SetTranslation(x, y);
        rect.SetTintColor(color);
        rect.Reparent(parent);
        return rect;
    }

    // =====================================================================
    //  Heat gauge
    // =====================================================================
    private func EnsureGauge() -> Bool {
        if IsDefined(this.m_gauge) {
            return true;
        }
        let root = this.GetHudRoot();
        if !IsDefined(root) {
            return false;
        }
        root.RemoveChildByName(n"MilitechHopeGauge");

        let gauge = new inkCanvas();
        gauge.SetName(n"MilitechHopeGauge");
        gauge.SetAnchor(inkEAnchor.CenterLeft);
        gauge.SetAnchorPoint(0.0, 0.5);
        gauge.SetSize(620.0, 230.0);
        gauge.SetTranslation(HopeConfig.HudX(), HopeConfig.HudY());
        gauge.SetVisible(false);
        gauge.Reparent(root);
        this.m_gauge = gauge;

        this.m_title = this.MakeText(gauge, 30, 0.0, 0.0);
        this.m_temp = this.MakeText(gauge, 64, 0.0, 34.0);
        this.m_barBack = this.MakeRect(gauge, 0.0, 112.0, 420.0, 12.0, HopeHud.Rgb(0.2, 0.2, 0.2, 0.7));
        this.m_barFill = this.MakeRect(gauge, 0.0, 112.0, 0.0, 12.0, HopeHud.ColorNormal());
        this.m_state = this.MakeText(gauge, 30, 0.0, 134.0);
        this.m_info = this.MakeText(gauge, 24, 0.0, 172.0);
        this.m_info.SetTintColor(HopeHud.ColorDim());
        return true;
    }

    public func HideGauge() -> Void {
        if IsDefined(this.m_gauge) {
            this.m_gauge.SetVisible(false);
        }
    }

    // fill: 0..1 heat between idle and critical; level: 0 normal, 1 warm, 2 hot
    public func ShowGauge(title: String, temp: String, fill: Float, level: Int32, state: String, info: String) -> Void {
        if !this.EnsureGauge() {
            return;
        }
        let color = HopeHud.ColorNormal();
        if level == 1 {
            color = HopeHud.ColorWarm();
        } else {
            if level >= 2 {
                color = HopeHud.ColorHot();
            }
        }
        this.m_title.SetText(title);
        this.m_temp.SetText(temp);
        this.m_temp.SetTintColor(color);
        this.m_barFill.SetSize(420.0 * ClampF(fill, 0.0, 1.0), 12.0);
        this.m_barFill.SetTintColor(color);
        this.m_state.SetText(state);
        this.m_state.SetTintColor(color);
        this.m_info.SetText(info);
        this.m_gauge.SetVisible(true);
    }

    // =====================================================================
    //  Broker menu
    // =====================================================================
    private func EnsureMenu(rows: Int32) -> Bool {
        if IsDefined(this.m_menu) && ArraySize(this.m_menuRows) >= rows {
            return true;
        }
        let root = this.GetHudRoot();
        if !IsDefined(root) {
            return false;
        }
        root.RemoveChildByName(n"MilitechHopeBroker");

        let height = 200.0 + 52.0 * Cast<Float>(rows);
        let menu = new inkCanvas();
        menu.SetName(n"MilitechHopeBroker");
        menu.SetAnchor(inkEAnchor.CenterRight);
        menu.SetAnchorPoint(1.0, 0.5);
        menu.SetSize(1180.0, height);
        menu.SetTranslation(-120.0, 0.0);
        menu.SetVisible(false);
        menu.Reparent(root);
        this.m_menu = menu;

        this.m_menuBack = this.MakeRect(menu, 0.0, 0.0, 1180.0, height, HopeHud.Rgb(0.02, 0.03, 0.05, 0.82));
        this.MakeRect(menu, 0.0, 0.0, 8.0, height, HopeHud.ColorHot());
        this.m_menuTitle = this.MakeText(menu, 40, 40.0, 24.0);
        this.m_menuTitle.SetTintColor(HopeHud.ColorHot());

        ArrayClear(this.m_menuRows);
        let i = 0;
        while i < rows {
            let row = this.MakeText(menu, 32, 40.0, 90.0 + 52.0 * Cast<Float>(i));
            ArrayPush(this.m_menuRows, row);
            i += 1;
        }
        this.m_menuFooter = this.MakeText(menu, 28, 40.0, height - 100.0);
        this.m_menuHint = this.MakeText(menu, 24, 40.0, height - 52.0);
        this.m_menuHint.SetTintColor(HopeHud.ColorDim());
        return true;
    }

    public func ShowMenu(title: String, rows: array<String>, selected: Int32, footer: String, hint: String) -> Void {
        if !this.EnsureMenu(ArraySize(rows)) {
            return;
        }
        this.m_menuTitle.SetText(title);
        let i = 0;
        while i < ArraySize(this.m_menuRows) {
            let row = this.m_menuRows[i];
            if i < ArraySize(rows) {
                if i == selected {
                    row.SetText("> " + rows[i]);
                    row.SetTintColor(HopeHud.ColorSelected());
                } else {
                    row.SetText("   " + rows[i]);
                    row.SetTintColor(HopeHud.ColorNormal());
                }
                row.SetVisible(true);
            } else {
                row.SetVisible(false);
            }
            i += 1;
        }
        this.m_menuFooter.SetText(footer);
        this.m_menuHint.SetText(hint);
        this.m_menu.SetVisible(true);
    }

    public func HideMenu() -> Void {
        if IsDefined(this.m_menu) {
            this.m_menu.SetVisible(false);
        }
    }
}
