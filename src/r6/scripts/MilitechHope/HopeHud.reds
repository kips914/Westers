// Militech "Hope" Sandevistan — on-screen widgets (Codeware ink API):
//   * heat gauge in degrees Celsius (left side of the HUD), pulses when hot
//   * warning banner (top centre): overheat warnings, burnout, mastery level-ups
//   * broker menu (opened with the call hotkey once the broker's number is known)
// Every widget is re-created when the HUD layer is rebuilt (loading a save,
// leaving a menu), so the gauge never stays attached to a dead window.
module MilitechHope

public class HopeHud {
    private let m_gauge: ref<inkCanvas>;
    private let m_title: ref<inkText>;
    private let m_temp: ref<inkText>;
    private let m_barBack: ref<inkRectangle>;
    private let m_barFill: ref<inkRectangle>;
    private let m_state: ref<inkText>;
    private let m_info: ref<inkText>;
    private let m_pulse: ref<inkAnimProxy>;
    private let m_pulsing: Bool;

    private let m_banner: ref<inkCanvas>;
    private let m_bannerBack: ref<inkRectangle>;
    private let m_bannerEdge: ref<inkRectangle>;
    private let m_bannerText: ref<inkText>;
    private let m_bannerSub: ref<inkText>;
    private let m_bannerPulse: ref<inkAnimProxy>;
    private let m_bannerTime: Float;
    private let m_bannerGlitch: Bool;

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

    public static func Vec2(x: Float, y: Float) -> Vector2 {
        let v: Vector2;
        v.X = x;
        v.Y = y;
        return v;
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
        this.m_pulse = null;
        this.m_pulsing = false;
        this.m_banner = null;
        this.m_bannerBack = null;
        this.m_bannerEdge = null;
        this.m_bannerText = null;
        this.m_bannerSub = null;
        this.m_bannerPulse = null;
        this.m_bannerTime = 0.0;
        this.m_bannerGlitch = false;
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

    // True when `widget` is still a child of the current HUD window.
    private func IsAttached(root: wref<inkCompoundWidget>, widget: ref<inkWidget>, name: CName) -> Bool {
        if !IsDefined(widget) || !IsDefined(root) {
            return false;
        }
        return IsDefined(root.GetWidgetByPathName(name));
    }

    // Looping fade (PingPong) used for the hot gauge and the banner.
    private func Pulse(widget: ref<inkWidget>, low: Float, seconds: Float) -> ref<inkAnimProxy> {
        let anim = new inkAnimDef();
        let fade = new inkAnimTransparency();
        fade.SetStartTransparency(1.0);
        fade.SetEndTransparency(low);
        fade.SetDuration(seconds);
        fade.SetType(inkanimInterpolationType.Sinusoidal);
        fade.SetMode(inkanimInterpolationMode.EasyInOut);
        anim.AddInterpolator(fade);
        let options: inkAnimOptions;
        options.loopType = inkanimLoopType.PingPong;
        options.loopInfinite = true;
        return widget.PlayAnimationWithOptions(anim, options);
    }

    // One-shot slide + fade in.
    private func SlideIn(widget: ref<inkWidget>, fromX: Float, fromY: Float, toX: Float, toY: Float) -> Void {
        let anim = new inkAnimDef();
        let move = new inkAnimTranslation();
        move.SetStartTranslation(HopeHud.Vec2(fromX, fromY));
        move.SetEndTranslation(HopeHud.Vec2(toX, toY));
        move.SetDuration(0.25);
        move.SetType(inkanimInterpolationType.Quadratic);
        move.SetMode(inkanimInterpolationMode.EasyOut);
        anim.AddInterpolator(move);
        let fade = new inkAnimTransparency();
        fade.SetStartTransparency(0.0);
        fade.SetEndTransparency(1.0);
        fade.SetDuration(0.25);
        fade.SetType(inkanimInterpolationType.Linear);
        fade.SetMode(inkanimInterpolationMode.EasyOut);
        anim.AddInterpolator(fade);
        widget.PlayAnimation(anim);
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
        let root = this.GetHudRoot();
        if !IsDefined(root) {
            return false;
        }
        if this.IsAttached(root, this.m_gauge, n"MilitechHopeGauge") {
            return true;
        }
        this.m_pulse = null;
        this.m_pulsing = false;
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
            this.SetGaugePulse(false);
            this.m_gauge.SetVisible(false);
        }
    }

    private func SetGaugePulse(on: Bool) -> Void {
        if on == this.m_pulsing {
            return;
        }
        this.m_pulsing = on;
        if IsDefined(this.m_pulse) {
            this.m_pulse.Stop(true);
            this.m_pulse = null;
        }
        if on {
            this.m_pulse = this.Pulse(this.m_temp, 0.25, 0.35);
        } else {
            this.m_temp.SetOpacity(1.0);
        }
    }

    // fill: 0..1 heat between idle and critical; level: 0 normal, 1 warm, 2 hot
    // idle: dimmed gauge (implant equipped, nothing happening)
    public func ShowGauge(title: String, temp: String, fill: Float, level: Int32, state: String, info: String, idle: Bool) -> Void {
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
        if idle {
            this.m_gauge.SetOpacity(HopeConfig.HudIdleOpacity());
        } else {
            this.m_gauge.SetOpacity(1.0);
        }
        this.SetGaugePulse(level >= 2);
        this.m_gauge.SetVisible(true);
    }

    // =====================================================================
    //  Warning banner
    // =====================================================================
    private func EnsureBanner() -> Bool {
        let root = this.GetHudRoot();
        if !IsDefined(root) {
            return false;
        }
        if this.IsAttached(root, this.m_banner, n"MilitechHopeBanner") {
            return true;
        }
        this.m_bannerPulse = null;
        root.RemoveChildByName(n"MilitechHopeBanner");

        let banner = new inkCanvas();
        banner.SetName(n"MilitechHopeBanner");
        banner.SetAnchor(inkEAnchor.TopCenter);
        banner.SetAnchorPoint(0.5, 0.0);
        banner.SetSize(1400.0, 150.0);
        banner.SetTranslation(0.0, 180.0);
        banner.SetVisible(false);
        banner.Reparent(root);
        this.m_banner = banner;

        this.m_bannerBack = this.MakeRect(banner, 0.0, 0.0, 1400.0, 150.0, HopeHud.Rgb(0.03, 0.02, 0.03, 0.78));
        this.m_bannerEdge = this.MakeRect(banner, 0.0, 0.0, 1400.0, 6.0, HopeHud.ColorHot());
        this.m_bannerText = this.MakeText(banner, 54, 40.0, 22.0);
        this.m_bannerSub = this.MakeText(banner, 30, 40.0, 92.0);
        this.m_bannerSub.SetTintColor(HopeHud.ColorDim());
        return true;
    }

    // level: 0 info (blue), 1 warning (amber), 2 danger (red, pulsing)
    // glitch: jitter the banner every tick (burnout error storm)
    public func ShowBanner(text: String, sub: String, level: Int32, seconds: Float, glitch: Bool) -> Void {
        if !this.EnsureBanner() {
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
        let wasVisible = this.m_banner.IsVisible();
        this.m_bannerText.SetText(text);
        this.m_bannerText.SetTintColor(color);
        this.m_bannerSub.SetText(sub);
        this.m_bannerEdge.SetTintColor(color);
        this.m_bannerTime = seconds;
        this.m_bannerGlitch = glitch;
        if IsDefined(this.m_bannerPulse) {
            this.m_bannerPulse.Stop(true);
            this.m_bannerPulse = null;
        }
        this.m_bannerText.SetOpacity(1.0);
        if level >= 2 {
            this.m_bannerPulse = this.Pulse(this.m_bannerText, 0.35, 0.25);
        }
        this.m_banner.SetVisible(true);
        if !wasVisible {
            this.SlideIn(this.m_banner, 0.0, 120.0, 0.0, 180.0);
        }
    }

    // Updates only the texts of a visible banner (countdowns).
    public func UpdateBanner(text: String, sub: String) -> Void {
        if IsDefined(this.m_banner) && this.m_banner.IsVisible() {
            this.m_bannerText.SetText(text);
            this.m_bannerSub.SetText(sub);
        }
    }

    public func HideBanner() -> Void {
        this.m_bannerTime = 0.0;
        if IsDefined(this.m_bannerPulse) {
            this.m_bannerPulse.Stop(true);
            this.m_bannerPulse = null;
        }
        if IsDefined(this.m_banner) {
            this.m_banner.SetVisible(false);
            this.m_banner.SetTranslation(0.0, 180.0);
        }
    }

    // Called by the system 5 times per second (real time).
    public func Tick(dt: Float) -> Void {
        if !IsDefined(this.m_banner) || !this.m_banner.IsVisible() {
            return;
        }
        if this.m_bannerGlitch {
            this.m_banner.SetTranslation(RandRangeF(-24.0, 24.0), 180.0 + RandRangeF(-10.0, 10.0));
            this.m_bannerBack.SetOpacity(RandRangeF(0.55, 1.0));
        }
        this.m_bannerTime -= dt;
        if this.m_bannerTime <= 0.0 {
            this.HideBanner();
        }
    }

    // =====================================================================
    //  Broker menu
    // =====================================================================
    private func EnsureMenu(rows: Int32) -> Bool {
        let root = this.GetHudRoot();
        if !IsDefined(root) {
            return false;
        }
        if this.IsAttached(root, this.m_menu, n"MilitechHopeBroker") && ArraySize(this.m_menuRows) >= rows {
            return true;
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
