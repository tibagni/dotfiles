// Native keyboard Copy Mode for Herdr terminals (tmux prefix+[ style).
// Supports Arrow keys (including Shift+Arrows), Vim motions (hjkl, w/b/e, 0/^/$, gg/G, Ctrl+u/d),
// visual character/line selection (Space, v, V), search (/ + n/N), and yanking (y / Enter).

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input, Scrollbar, v_virtual_list, VirtualListScrollHandle } from "gpui-base";
import { focused, hc, props, closeOverlay, theme, settings, notify } from "herdr";

const ROW_HEIGHT = 20;

function isWordChar(ch) {
  return Boolean(ch && /[A-Za-z0-9_]/.test(ch));
}

export default class CopyMode extends View {
  init(_props, cx) {
    this.lines = [""];
    this.row = 0;
    this.col = 0;
    this.preferredCol = 0;
    this.mode = null; // null | "char" | "line"
    this.anchor = null; // { row, col }
    this.pendingKey = null; // "g" | "y"
    this.loading = true;
    this.searching = false;
    this.query = "";
    this.matches = []; // [{ row, col }]
    this.matchIndex = -1;
    this.maxWidth = 600;

    this.handle = cx.focus_handle();
    this.scroll = VirtualListScrollHandle.new();
    this.searchInput = InputState.new({ placeholder: "Search scrollback… (Enter to jump, Esc to cancel)" });

    this.searchInput.on("change", (_e, cx) => {
      this.query = this.searchInput.value();
      this.updateMatches(true);
      cx.notify();
    });
    this.searchInput.on("submit", (_e, cx) => {
      this.searching = false;
      this.handle.focus();
      cx.notify();
    });

    if (props()?.overlay) {
      this.loadBuffer(cx);
      this.handle.focus();
      cx.timer.after(40, () => this.handle.focus());
    } else {
      this.loading = false;
    }
  }

  loadBuffer(cx) {
    const f = focused();
    const term = props()?.terminal || f?.shown || f?.terminal;
    if (!term) {
      this.lines = ["(No active terminal focused)"];
      this.loading = false;
      return;
    }
    this.terminal = term;
    cx.spawn(async (cx) => {
      try {
        const r = await hc(["read", term, "--lines", "3000"]);
        const raw = (r.stdout || "").replace(/\r\n/g, "\n");
        let lines = raw.split("\n");
        while (lines.length > 1 && lines[lines.length - 1].trim() === "") {
          lines.pop();
        }
        if (!lines.length) lines = [""];
        this.lines = lines;
        this.maxWidth = Math.max(600, ...lines.map((l) => l.length * 8 + 80));
        this.row = Math.max(0, lines.length - 1);
        const lastLine = lines[this.row] || "";
        this.col = 0;
        this.preferredCol = 0;
        this.loading = false;
        this.scroll.scroll_to_item(this.row, "center");
      } catch (e) {
        this.lines = [`Failed to read terminal ${term}: ${e}`];
        this.loading = false;
      }
      this.handle.focus();
      cx.notify();
    });
  }

  close() {
    this.scroll?.release();
    this.searchInput?.release();
  }

  dismissOverlay() {
    const ov = props()?.overlay;
    if (ov) closeOverlay(ov);
  }

  clampCol(row, col) {
    const line = this.lines[row] ?? "";
    const maxCol = Math.max(0, line.length - 1);
    return Math.max(0, Math.min(col, maxCol));
  }

  moveTo(row, col, keepPreferred = false) {
    const nextRow = Math.max(0, Math.min(row, this.lines.length - 1));
    const nextCol = this.clampCol(nextRow, col);
    this.row = nextRow;
    this.col = nextCol;
    if (!keepPreferred) this.preferredCol = nextCol;
    this.scroll.scroll_to_item(this.row, "center");
  }

  moveRow(delta) {
    const nextRow = Math.max(0, Math.min(this.row + delta, this.lines.length - 1));
    this.moveTo(nextRow, this.preferredCol, true);
  }

  moveCol(delta) {
    const line = this.lines[this.row] ?? "";
    const nextCol = Math.max(0, Math.min(this.col + delta, Math.max(0, line.length - 1)));
    this.moveTo(this.row, nextCol, false);
  }

  moveWordForward() {
    let r = this.row;
    let c = this.col;
    let line = this.lines[r] ?? "";
    const startType = isWordChar(line[c]);
    if (c < line.length && line[c] && !/\s/.test(line[c])) {
      while (c < line.length && !/\s/.test(line[c]) && isWordChar(line[c]) === startType) c++;
    }
    while (r < this.lines.length) {
      line = this.lines[r] ?? "";
      while (c < line.length && /\s/.test(line[c])) c++;
      if (c < line.length) {
        this.moveTo(r, c, false);
        return;
      }
      r++;
      c = 0;
    }
    this.moveTo(this.lines.length - 1, (this.lines[this.lines.length - 1] ?? "").length, false);
  }

  moveWordBackward() {
    let r = this.row;
    let c = this.col - 1;
    while (r >= 0) {
      const line = this.lines[r] ?? "";
      if (c >= line.length) c = line.length - 1;
      while (c >= 0 && /\s/.test(line[c])) c--;
      if (c >= 0) {
        const targetType = isWordChar(line[c]);
        while (c > 0 && !/\s/.test(line[c - 1]) && isWordChar(line[c - 1]) === targetType) c--;
        this.moveTo(r, c, false);
        return;
      }
      r--;
      if (r >= 0) c = (this.lines[r] ?? "").length - 1;
    }
    this.moveTo(0, 0, false);
  }

  moveWordEnd() {
    let r = this.row;
    let c = this.col + 1;
    while (r < this.lines.length) {
      const line = this.lines[r] ?? "";
      while (c < line.length && /\s/.test(line[c])) c++;
      if (c < line.length) {
        const targetType = isWordChar(line[c]);
        while (c + 1 < line.length && !/\s/.test(line[c + 1]) && isWordChar(line[c + 1]) === targetType) c++;
        this.moveTo(r, c, false);
        return;
      }
      r++;
      c = 0;
    }
  }

  selectionBounds() {
    if (!this.mode || !this.anchor) return null;
    const a = this.anchor;
    const b = { row: this.row, col: this.col };
    const forward = a.row < b.row || (a.row === b.row && a.col <= b.col);
    return forward ? { start: a, end: b } : { start: b, end: a };
  }

  selectedText() {
    const bounds = this.selectionBounds();
    if (!bounds) return this.lines[this.row] ?? "";
    const { start, end } = bounds;
    if (this.mode === "line") {
      return this.lines.slice(start.row, end.row + 1).join("\n");
    }
    if (start.row === end.row) {
      return (this.lines[start.row] ?? "").slice(start.col, end.col + 1);
    }
    const out = [];
    out.push((this.lines[start.row] ?? "").slice(start.col));
    for (let r = start.row + 1; r < end.row; r++) {
      out.push(this.lines[r] ?? "");
    }
    out.push((this.lines[end.row] ?? "").slice(0, end.col + 1));
    return out.join("\n");
  }

  yankAndClose(text, cx) {
    cx.write_to_clipboard(text);
    const preview = text.length > 60 ? text.slice(0, 60).replace(/\n/g, " ↵ ") + "…" : text.replace(/\n/g, " ↵ ");
    notify({ title: "Copied to clipboard", body: preview || "(empty)", level: "info", timeout: 1600 });
    this.dismissOverlay();
  }

  updateMatches(jumpToNearest = false) {
    const q = this.query.toLowerCase();
    this.matches = [];
    this.matchIndex = -1;
    if (!q) return;
    for (let r = 0; r < this.lines.length; r++) {
      const line = (this.lines[r] ?? "").toLowerCase();
      let idx = 0;
      while ((idx = line.indexOf(q, idx)) !== -1) {
        this.matches.push({ row: r, col: idx });
        idx += Math.max(1, q.length);
      }
    }
    if (jumpToNearest && this.matches.length > 0) {
      // Find nearest match at or above current row (terminal scrollback search feel)
      let best = this.matches.length - 1;
      for (let i = this.matches.length - 1; i >= 0; i--) {
        if (this.matches[i].row <= this.row) {
          best = i;
          break;
        }
      }
      this.matchIndex = best;
      const m = this.matches[best];
      this.moveTo(m.row, m.col, false);
    }
  }

  jumpMatch(delta) {
    if (!this.matches.length) return;
    this.matchIndex = (this.matchIndex + delta + this.matches.length) % this.matches.length;
    const m = this.matches[this.matchIndex];
    this.moveTo(m.row, m.col, false);
  }

  handleKey(e, cx) {
    const key = e.key;
    const ks = e.keystroke;
    const shift = Boolean(e.modifiers?.shift);
    const ctrl = Boolean(e.modifiers?.control);

    if (this.searching) {
      if (key === "escape") {
        this.searching = false;
        this.handle.focus();
        cx.stop_propagation();
        cx.notify();
      }
      return;
    }

    cx.stop_propagation();

    // Pending two-key sequences (gg, yy, yw)
    if (this.pendingKey === "g") {
      this.pendingKey = null;
      if (key === "g" && !shift) {
        this.moveTo(0, this.preferredCol, true);
        cx.notify();
        return;
      }
    } else if (this.pendingKey === "y") {
      this.pendingKey = null;
      if (key === "y") {
        this.yankAndClose(this.lines[this.row] ?? "", cx);
        return;
      }
      if (key === "w") {
        const line = this.lines[this.row] ?? "";
        let end = this.col;
        while (end < line.length && !/\s/.test(line[end])) end++;
        this.yankAndClose(line.slice(this.col, end), cx);
        return;
      }
    }

    // Escape / q
    if (key === "escape") {
      if (this.mode) {
        this.mode = null;
        this.anchor = null;
        cx.notify();
        return;
      }
      this.dismissOverlay();
      return;
    }
    if (key === "q" && !ctrl && !shift) {
      this.dismissOverlay();
      return;
    }

    // Search
    if (key === "/" || ks === "ctrl-f") {
      this.searching = true;
      this.searchInput.focus();
      cx.notify();
      return;
    }
    if (key === "n" && !ctrl && !shift) {
      this.jumpMatch(1);
      cx.notify();
      return;
    }
    if ((key === "n" && shift) || key === "N") {
      this.jumpMatch(-1);
      cx.notify();
      return;
    }

    // Shift + Arrow keys automatically enter/extend character selection
    if (shift && (key === "up" || key === "down" || key === "left" || key === "right")) {
      if (!this.mode) {
        this.mode = "char";
        this.anchor = { row: this.row, col: this.col };
      }
      if (key === "up") this.moveRow(-1);
      else if (key === "down") this.moveRow(1);
      else if (key === "left") this.moveCol(-1);
      else if (key === "right") this.moveCol(1);
      cx.notify();
      return;
    }

    // Basic directional movement (Arrows + hjkl)
    if (key === "up" || (key === "k" && !ctrl && !shift)) {
      this.moveRow(-1);
      cx.notify();
      return;
    }
    if (key === "down" || (key === "j" && !ctrl && !shift)) {
      this.moveRow(1);
      cx.notify();
      return;
    }
    if (key === "left" || key === "backspace" || (key === "h" && !ctrl && !shift)) {
      this.moveCol(-1);
      cx.notify();
      return;
    }
    if (key === "right" || (key === "l" && !ctrl && !shift)) {
      this.moveCol(1);
      cx.notify();
      return;
    }

    // Page / Half-page movement
    if (key === "pageup" || ks === "ctrl-u" || ks === "ctrl-b") {
      this.moveRow(ks === "ctrl-b" ? -30 : -15);
      cx.notify();
      return;
    }
    if (key === "pagedown" || ks === "ctrl-d") {
      this.moveRow(15);
      cx.notify();
      return;
    }

    // Line start / end
    if (key === "0" || key === "home") {
      this.moveTo(this.row, 0, false);
      cx.notify();
      return;
    }
    if (key === "^" || key === "_") {
      const line = this.lines[this.row] ?? "";
      const firstNonBlank = Math.max(0, line.search(/\S/));
      this.moveTo(this.row, firstNonBlank, false);
      cx.notify();
      return;
    }
    if (key === "$" || key === "end") {
      const line = this.lines[this.row] ?? "";
      this.moveTo(this.row, Math.max(0, line.length - 1), false);
      cx.notify();
      return;
    }

    // Word motions
    if ((key === "w" || key === "W") && !ctrl) {
      this.moveWordForward();
      cx.notify();
      return;
    }
    if ((key === "b" || key === "B") && !ctrl) {
      this.moveWordBackward();
      cx.notify();
      return;
    }
    if ((key === "e" || key === "E") && !ctrl) {
      this.moveWordEnd();
      cx.notify();
      return;
    }

    // Top / Bottom of buffer
    if ((key === "G" || (key === "g" && shift)) && !ctrl) {
      this.moveTo(this.lines.length - 1, this.preferredCol, true);
      cx.notify();
      return;
    }
    if (key === "g" && !shift && !ctrl) {
      this.pendingKey = "g";
      cx.notify();
      return;
    }

    // Selection toggles (Space, v, V, o)
    if (key === "space" || (key === "v" && !shift && !ctrl)) {
      if (this.mode === "char") {
        this.mode = null;
        this.anchor = null;
      } else {
        this.mode = "char";
        if (!this.anchor) this.anchor = { row: this.row, col: this.col };
      }
      cx.notify();
      return;
    }
    if ((key === "v" && shift) || key === "V") {
      if (this.mode === "line") {
        this.mode = null;
        this.anchor = null;
      } else {
        this.mode = "line";
        if (!this.anchor) this.anchor = { row: this.row, col: this.col };
      }
      cx.notify();
      return;
    }
    if (key === "o" && this.mode && this.anchor) {
      const prev = { row: this.row, col: this.col };
      this.moveTo(this.anchor.row, this.anchor.col, false);
      this.anchor = prev;
      cx.notify();
      return;
    }

    // Yank / Copy (Enter, y, Y)
    if (key === "enter") {
      this.yankAndClose(this.selectedText(), cx);
      return;
    }
    if ((key === "y" && shift) || key === "Y") {
      this.yankAndClose(this.selectedText(), cx);
      return;
    }
    if (key === "y" && !shift && !ctrl) {
      if (this.mode) {
        this.yankAndClose(this.selectedText(), cx);
        return;
      }
      this.pendingKey = "y";
      cx.notify();
      return;
    }
  }

  renderRow(r, t, bounds) {
    const rawLine = this.lines[r] ?? "";
    const isCursorRow = r === this.row;
    let selStart = -1;
    let selEnd = -1;

    if (bounds && r >= bounds.start.row && r <= bounds.end.row) {
      if (this.mode === "line") {
        selStart = 0;
        selEnd = Math.max(1, rawLine.length);
      } else if (bounds.start.row === bounds.end.row) {
        selStart = bounds.start.col;
        selEnd = bounds.end.col + 1;
      } else if (r === bounds.start.row) {
        selStart = bounds.start.col;
        selEnd = Math.max(selStart + 1, rawLine.length);
      } else if (r === bounds.end.row) {
        selStart = 0;
        selEnd = bounds.end.col + 1;
      } else {
        selStart = 0;
        selEnd = Math.max(1, rawLine.length);
      }
    }

    const numCol = div()
      .w(46)
      .flex_none()
      .pr(10)
      .text_right()
      .text_color(isCursorRow ? t.accent : t.dim)
      .child(String(r + 1));

    if (!isCursorRow && selStart === -1) {
      return h_flex()
        .w_full()
        .h(ROW_HEIGHT)
        .flex_none()
        .items_center()
        .px(8)
        .child(numCol)
        .child(div().flex_1().min_w(0).text_color(t.foreground).child(rawLine || " "));
    }

    const targetLen = Math.max(
      rawLine.length,
      isCursorRow ? this.col + 1 : 0,
      selEnd > 0 ? selEnd : 0,
      1,
    );
    const padded = rawLine.padEnd(targetLen, " ");

    // Group contiguous characters by highlight state: 0=normal, 1=selected, 2=cursor
    const runs = [];
    let curState = -1;
    let curText = "";
    for (let c = 0; c < padded.length; c++) {
      const state = isCursorRow && c === this.col ? 2 : c >= selStart && c < selEnd ? 1 : 0;
      if (state !== curState) {
        if (curText) runs.push({ state: curState, text: curText });
        curState = state;
        curText = padded[c];
      } else {
        curText += padded[c];
      }
    }
    if (curText) runs.push({ state: curState, text: curText });

    const selBg = t.selection || t.accent + "44";
    const spans = runs.map((run) => {
      if (run.state === 2) {
        return div()
          .bg(t.accent)
          .text_color(t.accent_foreground || t.background)
          .font_semibold()
          .child(run.text);
      }
      if (run.state === 1) {
        return div()
          .bg(selBg)
          .text_color(t.foreground)
          .child(run.text);
      }
      return div().text_color(t.foreground).child(run.text);
    });

    return h_flex()
      .w_full()
      .h(ROW_HEIGHT)
      .flex_none()
      .items_center()
      .px(8)
      .when(isCursorRow, (el) => el.bg(t.raised + "88"))
      .child(numCol)
      .child(h_flex().items_center().children(spans));
  }

  render(cx) {
    const t = theme();
    const bounds = this.selectionBounds();
    const modeLabel =
      this.mode === "line"
        ? "VISUAL LINE"
        : this.mode === "char"
          ? "VISUAL"
          : this.pendingKey
            ? `NORMAL (${this.pendingKey}…)`
            : "COPY MODE";
    const modeColor = this.mode ? t.working || t.accent : t.accent;

    return v_flex()
      .id("copy-mode-root")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.handleKey(e, cx))
      .size_full()
      .min_h(0)
      .bg(t.background)
      .text_color(t.foreground)
      .rounded(10)
      .overflow_hidden()
      .border_1()
      .border_color(t.accent)
      .child(
        // Top header bar
        h_flex()
          .h(34)
          .flex_none()
          .px(12)
          .gap(10)
          .items_center()
          .bg(t.surface)
          .border_b(1)
          .border_color(t.border)
          .text_size(12)
          .child(
            div()
              .px(7)
              .py(2)
              .rounded(4)
              .bg(modeColor)
              .text_color(t.accent_foreground || t.background)
              .font_semibold()
              .text_size(11)
              .child(modeLabel),
          )
          .child(
            div()
              .text_color(t.muted)
              .child(this.terminal ? `Terminal ${this.terminal}` : "Terminal buffer"),
          )
          .child(
            div()
              .text_color(t.dim)
              .child(`Ln ${this.row + 1}/${this.lines.length}, Col ${this.col + 1}`),
          )
          .when(this.matches.length > 0, (el) =>
            el.child(
              div()
                .text_color(t.ansi3)
                .child(`Match ${this.matchIndex + 1}/${this.matches.length}`),
            ),
          )
          .child(div().flex_1())
          .child(
            div()
              .text_size(11)
              .text_color(t.dim)
              .child("Arrows/hjkl: move • Space/v/V/Shift+Arrows: select • y/Enter: copy • /: search • q/Esc: close"),
          ),
      )
      .child(
        // Buffer viewport
        div()
          .flex_1()
          .min_h(0)
          .relative()
          .font_family(settings().font_family ?? "JetBrains Mono")
          .text_size(Number(settings().font_size) || 13)
          .child(
            div()
              .id("copy-mode-x")
              .size_full()
              .overflow_x_scrollbar()
              .child(
                div()
                  .w_full()
                  .min_w(this.maxWidth)
                  .h_full()
                  .child(
                    v_virtual_list(
                      "copy-mode-list",
                      this.lines.length,
                      ROW_HEIGHT,
                      (i) => String(i),
                      (range) => {
                        const out = [];
                        for (let r = range.start; r < range.end; r++) {
                          out.push(this.renderRow(r, t, bounds));
                        }
                        return out;
                      },
                    )
                      .track_scroll(this.scroll)
                      .on_item_click((key, cx) => {
                        const clickedRow = Number(key);
                        if (!Number.isNaN(clickedRow)) {
                          this.moveTo(clickedRow, this.col, true);
                          this.handle.focus();
                          cx.notify();
                        }
                      })
                      .size_full(),
                  ),
              ),
          )
          .child(Scrollbar.vertical("copy-mode-list").viewport_from_layout().absolute().inset_0()),
      )
      .when(this.searching, (el) =>
        el.child(
          h_flex()
            .h(38)
            .flex_none()
            .px(12)
            .gap(8)
            .items_center()
            .bg(t.surface)
            .border_t(1)
            .border_color(t.border)
            .child(div().text_color(t.accent).font_semibold().child("/"))
            .child(
              Input.new(this.searchInput)
                .flex_1()
                .h(28)
                .px(8)
                .rounded(6)
                .border_1()
                .border_color(t.accent)
                .bg(t.background)
                .text_size(12)
                .text_color(t.foreground),
            ),
        ),
      );
  }
}
