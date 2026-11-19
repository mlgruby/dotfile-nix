// Open a project as a space: one dialog, from the Ctrl+A prefix (o) or Cmd+O.
// The list is `herdr-workflow project --list`: ~/dotfile and the git repos
// under ~/Documents/Work and ~/Documents/Personal, in groups. A project that
// has a space already shows "open"; Enter goes to that space. Otherwise
// Enter makes a new space there, and dev-status adds its agent tabs.
// Type to filter. Up/Down (Ctrl+P/N): move. Enter: open. Esc: cancel.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, props, closeOverlay, theme, spaces, panes, exec, home } from "herdr";

const LIST = "herdr-workflow project --list";
const GROUPS = [["work", "Work"], ["personal", "Personal"], ["dotfile", "dotfile"]];
const ROWS = 14; // rows shown; the window follows the selection

// Every character of the query, in order, in the name or path (case-insensitive).
// Lower score is better: a name match first, then the earlier the start.
export function score(project, query) {
  const q = query.toLowerCase().replace(/\s+/g, "");
  if (!q) return 0;
  const fit = (s) => {
    let i = 0, first = -1;
    for (let j = 0; j < s.length && i < q.length; j++) if (s[j] === q[i]) { if (first < 0) first = j; i++; }
    return i === q.length ? first : -1;
  };
  const n = fit(project.name.toLowerCase());
  if (n >= 0) return n;
  const p = fit(project.path.toLowerCase());
  return p >= 0 ? 1000 + p : null;
}

// The local space whose folder or a terminal folder is the project (or inside it).
function spaceFor(path, list, ps) {
  const inside = (dir) => dir && (dir === path || dir.startsWith(path + "/"));
  return list.find((s) => !s.machine && (inside(s.folder)
    || ps.some((p) => s.tabs?.some((t) => t.id === p.tab) && inside(p.cwd))));
}

export default class ProjectOpen extends View {
  init(_props, cx) {
    this.projects = null;
    this.error = null;
    this.query = "";
    this.sel = 0;
    this.input = InputState.new({ placeholder: "Project name" });
    this.input.on("change", (_e, cx) => { this.query = this.input.value(); this.sel = 0; cx.notify(); });
    this.input.on("submit", (_e, cx) => this.open(cx));
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      try {
        const r = await exec("/bin/zsh", ["-lc", LIST], { timeout: 15000 });
        if (r.code !== 0) throw new Error((r.stderr || "project --list failed").trim().split("\n").pop());
        this.projects = JSON.parse(r.stdout);
      } catch (e) {
        this.error = String(e?.message ?? e);
      }
      cx.notify();
    });
  }

  close() { closeOverlay(props().overlay); }

  // Filtered, in group order; with a query, best match first.
  shown() {
    const order = Object.fromEntries(GROUPS.map(([g], i) => [g, i]));
    return (this.projects ?? [])
      .map((p) => ({ ...p, s: score(p, this.query) }))
      .filter((p) => p.s !== null)
      .sort((a, b) => (this.query ? a.s - b.s : 0) || order[a.group] - order[b.group] || a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
  }

  open(cx, pick) {
    const p = pick ?? this.shown()[this.sel];
    if (!p) return;
    const space = spaceFor(p.path, spaces(), panes());
    if (space) run("space.select", { id: space.id });
    else run("space.new", { folder: p.path });
    this.close();
  }

  key(e, cx) {
    const n = this.shown().length;
    const ctrl = e.modifiers.control;
    if (e.key === "escape") { this.close(); cx.stop_propagation(); return; }
    if (e.key === "down" || (ctrl && e.key === "n")) this.sel = Math.min(this.sel + 1, Math.max(n - 1, 0));
    else if (e.key === "up" || (ctrl && e.key === "p")) this.sel = Math.max(this.sel - 1, 0);
    else return;
    cx.stop_propagation(); cx.notify();
  }

  row(p, i, t, open) {
    const on = i === this.sel;
    const tilde = p.path.startsWith(home()) ? "~" + p.path.slice(home().length) : p.path;
    return h_flex().id(`po-${i}`).h(28).px(10).gap(10).items_center().rounded(6).cursor_pointer()
      .when(on, (el) => el.bg(t.selected))
      .on_click((_e, cx) => this.open(cx, p))
      .child(div().flex_none().w(150).truncate().text_color(on ? t.foreground : t.text ?? t.foreground).child(p.name))
      .child(div().flex_1().min_w(0).truncate().text_size(11).text_color(t.dim).child(tilde))
      .when(Boolean(open), (el) => el.child(div().flex_none().text_size(11).text_color(t.done).child("\u25cf open")));
  }

  render() {
    const t = theme();
    const list = this.shown();
    const live = spaces(), ps = panes();
    this.sel = Math.min(this.sel, Math.max(list.length - 1, 0));
    const start = Math.max(0, Math.min(this.sel - Math.floor(ROWS / 2), list.length - ROWS));
    const rows = [];
    let group = null;
    list.slice(start, start + ROWS).forEach((p, k) => {
      if (!this.query && p.group !== group) {
        group = p.group;
        rows.push(div().id(`po-g-${group}`).pt(6).px(10).text_size(10.5).font_semibold().text_color(t.muted)
          .child(GROUPS.find(([g]) => g === group)?.[1] ?? group));
      }
      rows.push(this.row(p, start + k, t, spaceFor(p.path, live, ps)));
    });
    const status = this.error ?? (this.projects === null ? "Loading projects…" : list.length ? null : "No project matches");
    return v_flex().id("project-open").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .w_full().p(18).gap(10).bg(t.popover).text_color(t.foreground).text_size(12.5)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child("Open project"))
        .child(div().text_size(11).text_color(t.dim).child(`${list.length} · ↑↓ · Enter · Esc`)))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(v_flex().gap(1).children(rows))
      .when(Boolean(status), (el) => el.child(div().px(10).text_size(11.5).text_color(this.error ? t.ansi1 : t.dim).child(status)));
  }
}
