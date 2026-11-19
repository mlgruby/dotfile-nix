import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import {
  agents,
  checking,
  closeOverlay,
  exec,
  focused,
  hc,
  layout,
  nextCommand,
  openOverlay,
  panes,
  props,
  run,
  spaces,
  theme,
} from "herdr";

const REPEAT_MS = 500;
const SHIFT_SPACE_KEYS = ["!", "@", "#", "$", "%", "^", "&", "*"];
const SHIFT_SPACE_MAP = [...SHIFT_SPACE_KEYS.map((ch, idx) => [ch, idx + 1]), ["(", 9]];

function findNode(node, id) {
  if (!node || typeof node !== "object") return null;
  if (node.id === id) return node;
  if (!Array.isArray(node.children)) return null;
  for (const child of node.children) {
    const found = findNode(child, id);
    if (found) return found;
  }
  return null;
}

function toggleChangesPanel() {
  const root = layout();
  const panel = findNode(root, "panel");
  const body = findNode(root, "panel-body");
  if (panel && !panel.hidden && body?.active === "changes") {
    run("layout.hide", { id: "panel" });
    return;
  }
  run("layout.select", { stack: "panel-body", child: "changes" });
  run("layout.show", { id: "panel" });
}

function cyclePane(step) {
  const f = focused();
  const tabId = f?.tab;
  if (!tabId) return;
  const tabPanes = panes().filter((p) => p.tab === tabId);
  if (tabPanes.length <= 1) return;
  let idx = tabPanes.findIndex((p) => p.focused || p.pane === f?.pane);
  if (idx < 0) idx = 0;
  const next = tabPanes[(idx + step + tabPanes.length) % tabPanes.length];
  if (next?.pane) run("pane.focus", { pane: next.pane });
}

// The PR of the focused folder's branch, in the browser.
function openBranchPr() {
  const cwd = focused()?.cwd;
  if (cwd) exec("gh", ["pr", "view", "--web"], { cwd }).catch(() => {});
}

// The oldest blocked agent, else the oldest done one: the order of the
// needs-me drawer.
function nextWaiting() {
  const rank = { blocked: 0, done: 1 };
  const next = agents().filter((a) => a.status in rank).sort((x, y) => rank[x.status] - rank[y.status] || x.seq - y.seq)[0];
  if (next) run("agent.focus", { terminal: next.address });
}

// A tool in a floating window. The tool-popup
// mod starts it: this popup closes before the terminal exists.
function openToolPopup(title, argv) {
  const space = spaces().find((s) => s.active);
  const cwd = focused()?.cwd || space?.folder;
  const on = space?.machine;
  openOverlay({ mod: "tool-popup", kind: "popup", frame: "none", width: 2, height: 2,
    props: { title, argv, ...(cwd ? { cwd } : {}), ...(on ? { on } : {}) } });
}

const BINDINGS = [
  // Spaces & Tabs (plain = Space, Shift = Tab; migrated from ~/.config/herdr/config.toml)
  { key: "n", label: "New space", run: () => run("space.new") },
  { key: "N", label: "New tab", run: () => run("tab.new") },
  { key: "w", label: "Close space", run: () => run("space.close") },
  { key: "W", label: "Close tab", run: () => run("tab.close") },
  { key: "r", label: "Rename space", run: () => run("space.rename") },
  { key: "R", label: "Rename tab", run: () => run("tab.rename") },

  // Splits & Panes
  { key: "v", label: "Split right", run: () => run("pane.split", { direction: "right" }) },
  { key: "h", label: "Split down", run: () => run("pane.split", { direction: "down" }) },
  { key: "x", label: "Close pane", run: () => run("pane.close") },
  { key: "z", label: "Zoom pane", run: () => run("pane.zoom") },
  { key: "left", label: "Focus left", run: () => run("pane.go", { direction: "left" }), repeat: true, compactHide: true },
  { key: "right", label: "Focus right", run: () => run("pane.go", { direction: "right" }), repeat: true, compactHide: true },
  { key: "up", label: "Focus up", run: () => run("pane.go", { direction: "up" }), repeat: true, compactHide: true },
  { key: "down", label: "Focus down", run: () => run("pane.go", { direction: "down" }), repeat: true, compactHide: true },
  { key: "tab", label: "Cycle pane next", run: () => cyclePane(1), repeat: true },
  { key: "shift-tab", label: "Cycle pane prev", run: () => cyclePane(-1), repeat: true },

  // Agents
  { key: "a", label: "Start agent on a task", run: () => openOverlay({ mod: "agent-launch", kind: "dialog", width: 560 }) },
  { key: "o", label: "Open project as a space", run: () => openOverlay({ mod: "project-open", kind: "dialog", width: 620 }) },
  { key: "j", label: "Jump to agent waiting for you", run: () => nextWaiting() },

  // Git / Workflow / System
  { key: "g", label: "Changes panel", run: () => toggleChangesPanel() },
  { key: "G", label: "Changes tab", run: () => run("tab.new", { name: "Changes", mod: "dev-changes" }) },
  { key: "p", label: "PR of this branch (browser)", run: () => openBranchPr() },
  { key: "P", label: "PR/MR review (Redline)", run: () => run("mod.open", { name: "redline" }) },
  { key: "l", label: "Lazygit (herdr-review)", run: () => openToolPopup("Lazygit", ["herdr-review"]) },
  { key: "d", label: "Diff (herdr-review)", run: () => openToolPopup("Diff", ["herdr-review", "diff"]) },
  { key: "i", label: "PR Inbox (hinbox)", run: () => openToolPopup("Inbox", ["hinbox"]) },
  { key: "f", label: "Find file (hfind)", run: () => openToolPopup("Find", ["hfind"]) },
  { key: "s", label: "Space / tab picker", run: () => run("mod.open", { name: "picker" }) },
  { key: ",", label: "Settings", run: () => run("app.settings") },

  // Indexed Tab & Space jumps (1..9 = tabs, Shift+1..9 = spaces)
  ...Array.from({ length: 9 }, (_, i) => ({
    key: String(i + 1),
    label: `Tab ${i + 1}`,
    run: () => run("tab.select", { index: i + 1 }),
    compactHide: true,
  })),
  ...SHIFT_SPACE_MAP.map(([ch, idx]) => ({
    key: ch,
    label: `Space ${idx}`,
    run: () => run("space.select", { index: idx }),
    compactHide: true,
  })),
];

function forwardKey(e, key) {
  if (["enter", "tab", "backspace", "left", "right", "up", "down", "space"].includes(e.key)) return e.key;
  if (key === " ") return "space";
  if (/^[A-Z]$/.test(key)) return `shift+${key.toLowerCase()}`;
  if (key.length === 1 && "abcdefghijklmnopqrstuvwxyz0123456789`\\[],=-.';/".includes(key)) {
    return key === "\\" ? "backslash" : key;
  }
  return null;
}

export default class TmuxPrefix extends View {
  init(_props, cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    this.repeat = false;
    this.generation = 0;
    this.all = false;
    if (checking()) return;
    cx.spawn(async (cx) => {
      for (;;) {
        await nextCommand();
        this.sendPrefix(cx);
      }
    });
  }

  dismiss() {
    closeOverlay(props().overlay);
  }

  send(key, cx) {
    this.generation++;
    const terminal = focused()?.terminal;
    if (!terminal) return this.dismiss();
    const pending = hc(["keys", terminal, key]);
    cx.spawn(async () => {
      const result = await pending;
      if (result.code !== 0) console.log(`tmux-prefix: ${result.stderr}`);
    });
    this.dismiss();
  }

  sendPrefix(cx) {
    this.send("ctrl+a", cx);
  }

  key(e, cx) {
    cx.stop_propagation();
    const m = e.modifiers;
    if (e.key === "escape") return this.dismiss();
    if (m.control && !m.alt && !m.platform && e.key === "a") return this.sendPrefix(cx);

    const plain = !m.control && !m.alt && !m.platform;
    const key = !plain
      ? e.key
      : m.shift && e.key === "tab"
        ? "shift-tab"
        : e.key_char ?? (m.shift && e.key.length === 1 ? e.key.toUpperCase() : e.key);

    if (plain && key === "?") {
      this.all = !this.all;
      this.repeat = false;
      this.generation++;
      cx.notify();
      return;
    }

    const binding = plain && BINDINGS.find((b) => b.key === key);
    if (!binding) {
      const forwarded = this.repeat && plain && forwardKey(e, key);
      if (forwarded) return this.send(forwarded, cx);
      return this.dismiss();
    }

    // Run first: a popup that closes drops the overlays it opens after.
    binding.run();
    if (!binding.repeat) this.dismiss();
    if (binding.repeat) {
      this.repeat = true;
      const generation = ++this.generation;
      cx.timer.after(REPEAT_MS, () => {
        if (this.generation === generation) this.dismiss();
      });
      cx.notify();
    }
  }

  render() {
    const t = theme();
    const rows = this.all ? BINDINGS : BINDINGS.filter((b) => !b.compactHide);
    return v_flex()
      .id("tmux-prefix")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.key(e, cx))
      .p(14)
      .gap(8)
      .bg(t.popover)
      .text_color(t.foreground)
      .text_size(12)
      .child(
        h_flex()
          .justify_between()
          .child(div().font_semibold().child(this.repeat ? `Repeat · ${REPEAT_MS} ms` : "Ctrl+A · waiting for a key"))
          .child(div().text_color(t.muted).child("Esc cancel · ^A send prefix")),
      )
      .child(
        v_flex()
          .h(320)
          .min_h(0)
          .overflow_y_scrollbar()
          .children(
            rows.map((b) =>
              h_flex()
                .h(20)
                .flex_none()
                .items_center()
                .gap(12)
                .child(div().w(72).text_color(t.accent).child(b.key))
                .child(div().flex_1().child(b.label))
                .child(div().text_color(t.dim).child(b.repeat ? "repeat" : "")),
            ),
          ),
      )
      .child(div().text_color(t.muted).child("1–9 tabs · Shift+1–9 spaces · arrows focus · ? all bindings"));
  }
}
