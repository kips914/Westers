using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace MilitechHopeInstaller
{
    public sealed class MainForm : Form
    {
        private static readonly Color Bg = Color.FromArgb(18, 20, 28);
        private static readonly Color Panel = Color.FromArgb(28, 31, 42);
        private static readonly Color Accent = Color.FromArgb(70, 160, 255);
        private static readonly Color Fg = Color.FromArgb(225, 230, 240);
        private static readonly Color Muted = Color.FromArgb(140, 150, 170);

        private readonly TextBox _path = new TextBox();
        private readonly Label _gameInfo = new Label();
        private readonly CheckedListBox _list = new CheckedListBox();
        private readonly Label _desc = new Label();
        private readonly ProgressBar _progress = new ProgressBar();
        private readonly TextBox _log = new TextBox();
        private readonly Button _install = new Button();
        private readonly Button _remove = new Button();
        private readonly Button _update = new Button();
        private readonly Label _updateInfo = new Label();
        private readonly Button _open = new Button();
        private readonly Button _browse = new Button();
        private readonly Button _detect = new Button();
        private bool _busy;

        public MainForm(string initialGameDir)
        {
            Text = "Militech «Надежда» — установщик мода для Cyberpunk 2077";
            try { Icon = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location); } catch { }
            AutoScaleMode = AutoScaleMode.Dpi;
            AutoScaleDimensions = new SizeF(96F, 96F);
            ClientSize = new Size(720, 640);
            MinimumSize = new Size(640, 560);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Bg;
            ForeColor = Fg;
            Font = new Font("Segoe UI", 9.5F);

            BuildLayout();

            var dir = GameLocator.IsGameDir(initialGameDir) ? initialGameDir : GameLocator.Find();
            _path.Text = dir ?? "";
            RefreshGameInfo();

            if (!InstallerEngine.HasEmbeddedMod())
                AppendLog("Пакет мода не встроен — он будет скачан из релизов GitHub.");

            Shown += async (s, e) => await CheckUpdatesAsync();
        }

        // Quietly asks GitHub for the latest mod release and tells the user when it is newer.
        private async Task CheckUpdatesAsync()
        {
            var dir = _path.Text.Trim();
            try
            {
                var release = await Task.Run(() => InstallerEngine.GetLatestRelease(Catalog.MainMod));
                var latest = InstallerEngine.ParseVersion(release.Tag);
                var own = Assembly.GetExecutingAssembly().GetName().Version;
                var installedText = GameLocator.IsGameDir(dir) ? InstallerEngine.GetInstalledModVersion(dir) : null;
                var installed = InstallerEngine.ParseVersion(installedText);

                if (installedText != null && (installed == null || (latest != null && latest > installed)))
                {
                    _updateInfo.Text = $"⬆ Доступно обновление мода: {release.Tag} (установлено: {installedText}). Нажмите «Обновить мод».";
                    _updateInfo.ForeColor = Color.FromArgb(255, 205, 90);
                }
                else if (installedText != null)
                {
                    _updateInfo.Text = $"✓ Установлена последняя версия мода ({installedText}).";
                    _updateInfo.ForeColor = Color.FromArgb(120, 220, 140);
                }
                else
                {
                    _updateInfo.Text = $"Последняя версия мода на GitHub: {release.Tag}.";
                    _updateInfo.ForeColor = Muted;
                }
                if (latest != null && own != null && latest > new Version(own.Major, own.Minor, Math.Max(0, own.Build)))
                    AppendLog($"Вышел новый установщик ({release.Tag}): github.com/{Catalog.ModRepo}/releases/latest");
            }
            catch (Exception ex)
            {
                _updateInfo.Text = "Не удалось проверить обновления: " + ex.Message;
                _updateInfo.ForeColor = Muted;
            }
        }

        // ------------------------------------------------------------------ layout

        private void BuildLayout()
        {
            var root = new TableLayoutPanel
            {
                Dock = DockStyle.Fill, Padding = new Padding(16), ColumnCount = 1, RowCount = 8, BackColor = Bg,
            };
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // title
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // path row
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // game info
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 45));    // components
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // description
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // progress
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 55));    // log
            root.RowStyles.Add(new RowStyle(SizeType.AutoSize));       // buttons
            Controls.Add(root);

            var title = new Label
            {
                Text = "Сандевистан Militech «Надежда»",
                Font = new Font("Segoe UI Semibold", 16F), ForeColor = Accent, AutoSize = true,
                Margin = new Padding(0, 0, 0, 2),
            };
            var subtitle = new Label
            {
                Text = "Установка мода и необходимых модов (RED4ext, redscript, TweakXL, Codeware, CET) для Cyberpunk 2077 2.5",
                ForeColor = Muted, AutoSize = true, MaximumSize = new Size(680, 0), Margin = new Padding(0, 0, 0, 10),
            };
            var titleBox = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, AutoSize = true, Dock = DockStyle.Fill, WrapContents = false };
            titleBox.Controls.Add(title);
            titleBox.Controls.Add(subtitle);
            root.Controls.Add(titleBox);

            // path row
            var pathRow = new TableLayoutPanel { ColumnCount = 4, Dock = DockStyle.Fill, AutoSize = true, Margin = new Padding(0) };
            pathRow.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            pathRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            pathRow.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            pathRow.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
            pathRow.Controls.Add(new Label { Text = "Папка игры:", AutoSize = true, Anchor = AnchorStyles.Left, Margin = new Padding(0, 6, 8, 0) });
            _path.Dock = DockStyle.Fill;
            _path.BackColor = Panel;
            _path.ForeColor = Fg;
            _path.BorderStyle = BorderStyle.FixedSingle;
            _path.TextChanged += (s, e) => RefreshGameInfo();
            pathRow.Controls.Add(_path);
            StyleButton(_browse, "Обзор…", false);
            _browse.Click += (s, e) => Browse();
            pathRow.Controls.Add(_browse);
            StyleButton(_detect, "Найти", false);
            _detect.Click += (s, e) =>
            {
                var found = GameLocator.Find();
                if (found != null) _path.Text = found;
                else MessageBox.Show(this, "Игра не найдена автоматически. Укажите папку вручную (в ней есть bin\\x64\\Cyberpunk2077.exe).",
                    Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            };
            pathRow.Controls.Add(_detect);
            root.Controls.Add(pathRow);

            _gameInfo.AutoSize = true;
            _gameInfo.Margin = new Padding(0, 6, 0, 2);
            _updateInfo.AutoSize = true;
            _updateInfo.ForeColor = Muted;
            _updateInfo.Margin = new Padding(0, 2, 0, 10);
            _updateInfo.MaximumSize = new Size(680, 0);
            _updateInfo.Text = "Проверка обновлений…";
            var infoBox = new FlowLayoutPanel { FlowDirection = FlowDirection.TopDown, AutoSize = true, Dock = DockStyle.Fill, WrapContents = false, Margin = new Padding(0) };
            infoBox.Controls.Add(_gameInfo);
            infoBox.Controls.Add(_updateInfo);
            root.Controls.Add(infoBox);

            // components
            _list.Dock = DockStyle.Fill;
            _list.CheckOnClick = true;
            _list.BackColor = Panel;
            _list.ForeColor = Fg;
            _list.BorderStyle = BorderStyle.None;
            _list.IntegralHeight = false;
            _list.SelectedIndexChanged += (s, e) =>
            {
                var c = Selected(_list.SelectedIndex);
                _desc.Text = c == null ? "" : c.Description + (c.Required ? "  (обязательно)" : "  (по желанию)");
            };
            root.Controls.Add(_list);

            _desc.AutoSize = true;
            _desc.ForeColor = Muted;
            _desc.Margin = new Padding(0, 6, 0, 8);
            _desc.Text = "Отмечены компоненты, которых ещё нет в игре. Отметьте установленные, чтобы обновить их до последней версии.";
            _desc.MaximumSize = new Size(680, 0);
            root.Controls.Add(_desc);

            _progress.Dock = DockStyle.Fill;
            _progress.Height = 14;
            _progress.Margin = new Padding(0, 0, 0, 8);
            root.Controls.Add(_progress);

            _log.Dock = DockStyle.Fill;
            _log.Multiline = true;
            _log.ReadOnly = true;
            _log.ScrollBars = ScrollBars.Vertical;
            _log.BackColor = Color.FromArgb(12, 14, 20);
            _log.ForeColor = Color.FromArgb(170, 220, 255);
            _log.BorderStyle = BorderStyle.None;
            _log.Font = new Font("Consolas", 9F);
            root.Controls.Add(_log);

            // buttons
            var buttons = new FlowLayoutPanel { FlowDirection = FlowDirection.RightToLeft, Dock = DockStyle.Fill, AutoSize = true, Margin = new Padding(0, 10, 0, 0) };
            StyleButton(_install, "Установить", true);
            _install.Click += async (s, e) => await InstallAsync();
            StyleButton(_update, "Обновить мод", false);
            _update.Click += async (s, e) => await UpdateAsync();
            StyleButton(_remove, "Удалить мод", false);
            _remove.Click += async (s, e) => await RemoveAsync();
            StyleButton(_open, "Открыть папку игры", false);
            _open.Click += (s, e) => { if (GameLocator.IsGameDir(_path.Text)) Process.Start("explorer.exe", "\"" + _path.Text + "\""); };
            buttons.Controls.Add(_install);
            buttons.Controls.Add(_update);
            buttons.Controls.Add(_remove);
            buttons.Controls.Add(_open);
            root.Controls.Add(buttons);
        }

        private static void StyleButton(Button b, string text, bool primary)
        {
            b.Text = text;
            b.AutoSize = true;
            b.FlatStyle = FlatStyle.Flat;
            b.FlatAppearance.BorderColor = primary ? Accent : Color.FromArgb(60, 66, 85);
            b.BackColor = primary ? Accent : Panel;
            b.ForeColor = primary ? Color.White : Fg;
            b.Padding = new Padding(10, 3, 10, 3);
            b.Margin = new Padding(6, 0, 0, 0);
            b.Cursor = Cursors.Hand;
            if (primary) b.Font = new Font("Segoe UI Semibold", 10F);
        }

        // ------------------------------------------------------------------ state

        private ModComponent Selected(int index) =>
            index >= 0 && index < _list.Items.Count ? ((Item)_list.Items[index]).Component : null;

        private sealed class Item
        {
            public ModComponent Component;
            public string Label;
            public override string ToString() => Label;
        }

        private void RefreshGameInfo()
        {
            var dir = _path.Text.Trim();
            var valid = GameLocator.IsGameDir(dir);
            if (valid)
            {
                var ver = GameLocator.GetGameVersion(dir);
                _gameInfo.Text = "✓ Cyberpunk 2077 найден" + (string.IsNullOrEmpty(ver) ? "" : $"  (версия exe {ver})");
                _gameInfo.ForeColor = Color.FromArgb(120, 220, 140);
            }
            else
            {
                _gameInfo.Text = "✗ В этой папке нет bin\\x64\\Cyberpunk2077.exe — укажите корневую папку игры.";
                _gameInfo.ForeColor = Color.FromArgb(255, 120, 110);
            }

            _list.Items.Clear();
            foreach (var c in Catalog.All)
            {
                var installed = valid && c.IsInstalled(dir);
                var label = c.Name + (installed ? "   — уже установлен" : "") + (c.Required ? "" : "   [по желанию]");
                var check = c.IsMainMod || (!installed && (c.Required || c.Id == "cet"));
                _list.Items.Add(new Item { Component = c, Label = label }, check);
            }
            UpdateButtons();
        }

        private void UpdateButtons()
        {
            var valid = GameLocator.IsGameDir(_path.Text.Trim());
            _install.Enabled = valid && !_busy;
            _remove.Enabled = valid && !_busy;
            _update.Enabled = valid && !_busy;
            _open.Enabled = valid;
            _browse.Enabled = _detect.Enabled = _path.Enabled = _list.Enabled = !_busy;
        }

        private void Browse()
        {
            using (var dlg = new FolderBrowserDialog { Description = "Выберите корневую папку Cyberpunk 2077 (в ней папки bin, archive, r6)" })
            {
                if (GameLocator.IsGameDir(_path.Text)) dlg.SelectedPath = _path.Text;
                if (dlg.ShowDialog(this) == DialogResult.OK) _path.Text = dlg.SelectedPath;
            }
        }

        private void AppendLog(string line)
        {
            if (InvokeRequired) { BeginInvoke(new Action<string>(AppendLog), line); return; }
            _log.AppendText(line + Environment.NewLine);
        }

        private void SetProgress(int value)
        {
            if (InvokeRequired) { BeginInvoke(new Action<int>(SetProgress), value); return; }
            _progress.Value = Math.Max(0, Math.Min(100, value));
        }

        // ------------------------------------------------------------------ actions

        private bool PrepareFolder(string dir)
        {
            if (InstallerEngine.IsGameRunning())
            {
                MessageBox.Show(this, "Закройте Cyberpunk 2077 перед установкой.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return false;
            }
            if (InstallerEngine.CanWrite(dir)) return true;

            var answer = MessageBox.Show(this,
                "Нет прав на запись в папку игры. Перезапустить установщик от имени администратора?",
                Text, MessageBoxButtons.YesNo, MessageBoxIcon.Question);
            if (answer == DialogResult.Yes)
            {
                try
                {
                    Process.Start(new ProcessStartInfo
                    {
                        FileName = Assembly.GetExecutingAssembly().Location,
                        Arguments = "--game \"" + dir.TrimEnd('\\') + "\"",
                        Verb = "runas",
                        UseShellExecute = true,
                    });
                    Close();
                }
                catch (Exception ex) { AppendLog("Не удалось перезапуститься: " + ex.Message); }
            }
            return false;
        }

        private async Task InstallAsync()
        {
            var dir = _path.Text.Trim();
            var selected = _list.CheckedItems.Cast<Item>().Select(i => i.Component).ToList();
            if (selected.Count == 0) { AppendLog("Ничего не выбрано."); return; }
            if (!PrepareFolder(dir)) return;

            var missingRequired = Catalog.All.Where(c => c.Required && !c.IsInstalled(dir) && !selected.Contains(c)).ToList();
            if (missingRequired.Count > 0)
            {
                var names = string.Join(", ", missingRequired.Select(c => c.Name));
                if (MessageBox.Show(this, $"Без этих компонентов мод не заработает: {names}.\nПродолжить без них?", Text,
                        MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes) return;
            }

            _busy = true;
            UpdateButtons();
            _log.Clear();
            AppendLog($"Папка игры: {dir}");

            var engine = new InstallerEngine();
            engine.Log += AppendLog;
            engine.Progress += SetProgress;
            var ok = await Task.Run(() => engine.Install(dir, selected));

            AppendLog("");
            AppendLog(ok
                ? "Готово! Запустите игру. Имплант: консоль CET → GetMod(\"MilitechHope\").give(), или задание на набережной Арасаки (40+ уровень)."
                : "Установка завершилась с ошибками — см. сообщения выше. Можно нажать «Установить» ещё раз.");
            _busy = false;
            RefreshGameInfo();
            MessageBox.Show(this, ok ? "Установка завершена." : "Установка завершилась с ошибками. Подробности в журнале.",
                Text, MessageBoxButtons.OK, ok ? MessageBoxIcon.Information : MessageBoxIcon.Warning);
        }

        private async Task UpdateAsync()
        {
            var dir = _path.Text.Trim();
            if (!PrepareFolder(dir)) return;

            _busy = true;
            UpdateButtons();
            _log.Clear();
            AppendLog($"Папка игры: {dir}");
            var engine = new InstallerEngine();
            engine.Log += AppendLog;
            engine.Progress += SetProgress;
            var force = (ModifierKeys & Keys.Shift) == Keys.Shift; // Shift+click: reinstall even when up to date
            var ok = await Task.Run(() => engine.UpdateMainMod(dir, force));

            var missing = Catalog.All.Where(c => c.Required && !c.IsMainMod && !c.IsInstalled(dir)).Select(c => c.Name).ToList();
            if (missing.Count > 0)
                AppendLog("Внимание: не установлены " + string.Join(", ", missing) + " — отметьте их и нажмите «Установить».");
            AppendLog(ok ? "Готово. Сохранения переносятся, имплант и модули остаются." : "Обновить не удалось — проверьте интернет и попробуйте ещё раз.");
            _busy = false;
            RefreshGameInfo();
            await CheckUpdatesAsync();
        }

        private async Task RemoveAsync()
        {
            var dir = _path.Text.Trim();
            if (MessageBox.Show(this, "Удалить файлы мода «Надежда» из игры?\nRED4ext, redscript, TweakXL, Codeware и CET останутся.\nПеред удалением снимите имплант в игре.",
                    Text, MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
            if (!PrepareFolder(dir)) return;

            _busy = true;
            UpdateButtons();
            _log.Clear();
            var engine = new InstallerEngine();
            engine.Log += AppendLog;
            AppendLog("── Удаление мода «Надежда»");
            var ok = await Task.Run(() => engine.RemoveMainMod(dir));
            AppendLog(ok ? "Мод удалён." : "Часть файлов удалить не удалось.");
            _busy = false;
            RefreshGameInfo();
        }
    }
}
