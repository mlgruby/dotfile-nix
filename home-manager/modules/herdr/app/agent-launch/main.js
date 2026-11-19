// Start an agent on a task: one dialog, from the Ctrl+A prefix (a).
// With "worktree" on and the focused folder in a git repo, the agent gets its
// own checkout (<worktrees.directory>/<repo>/<branch>, the same place the
// shipped worktree dialog uses) on a new agent/<task> branch, in a new space.
// Otherwise it starts in a new tab in the focused folder.
// Tab: next agent. Shift+Tab: worktree on/off. Enter: start. Esc: cancel.

import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, props, closeOverlay, theme, spaces, panes, focused, exec, home, appHome, readTextFile } from "herdr";

const AGENTS = [
  { name: "claude", argv: ["claude"] },
  { name: "codex", argv: ["codex"] },
];

// The task's first words, as a branch and folder name.
export function branchFor(task) {
  const words = task.toLowerCase().normalize("NFKD").replace(/[^a-z0-9]+/g, " ").trim().split(" ").filter(Boolean);
  return `agent/${words.slice(0, 5).join("-") || "task"}`;
}
export const folderFor = (branch) => branch.replace(/\//g, "-");

function where() {
  const f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const space = spaces().find((s) => s.active);
  return { cwd: pane?.cwd || f?.cwd || space?.folder || null, on: space?.machine ?? null };
}

async function worktreeRoot(on) {
  const raw = await readTextFile(`${appHome()}/settings.json`).catch(() => null);
  let dir = (raw ? JSON.parse(raw) : {})?.worktrees?.directory ?? "~/.herdr/worktrees";
  if (dir === "~" || dir.startsWith("~/")) {
    const h = on ? (await exec("sh", ["-c", 'printf %s "$HOME"'], { on })).stdout.trim() : home();
    dir = h.replace(/\/$/, "") + dir.slice(1);
  }
  return dir.replace(/\/+$/, "");
}

export default class AgentLaunch extends View {
  init(_props, cx) {
    this.text = "";
    this.agent = 0;
    this.worktree = true;
    this.error = null;
    this.busy = false;
    this.repo = null;
    this.input = InputState.new({ placeholder: "What should the agent do?" });
    this.input.on("change", (_e, cx) => { this.text = this.input.value(); cx.notify(); });
    this.input.on("submit", (_e, cx) => this.start(cx));
    this.input.focus();
    cx.timer.after(300, () => this.input.focus());
    this.handle = cx.focus_handle();
    const { cwd, on } = where();
    this.cwd = cwd; this.on = on;
    if (!cwd) return;
    cx.spawn(async (cx) => {
      const r = await exec("git", ["rev-parse", "--show-toplevel"], { cwd, on }).catch(() => null);
      this.repo = r?.code === 0 ? r.stdout.trim() : null;
      cx.notify();
    });
  }

  // Not close(): that name is the host cleanup hook, called when the view goes.
  dismiss() { closeOverlay(props().overlay); }

  start(cx) {
    const task = this.text.trim();
    if (!task || this.busy) return;
    const agent = AGENTS[this.agent];
    if (!(this.worktree && this.repo)) {
      run("tab.new", { name: agent.name, argv: agent.argv, task, ...(this.cwd ? { folder: this.cwd } : {}) });
      return this.dismiss();
    }
    this.busy = true; this.error = null; cx.notify();
    cx.spawn(async (cx) => {
      try {
        const on = this.on, base = branchFor(task);
        // A branch that exists already gets -2, -3, ... instead.
        let branch = base;
        for (let n = 2; (await exec("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], { cwd: this.repo, on })).code === 0; n++) branch = `${base}-${n}`;
        const path = `${await worktreeRoot(on)}/${this.repo.split("/").pop()}/${folderFor(branch)}`;
        const r = await exec("git", ["worktree", "add", "-b", branch, path, "HEAD"], { cwd: this.repo, on, timeout: 600000 });
        if (r.code !== 0) throw new Error((r.stderr || r.stdout).trim() || "git worktree add failed");
        run("space.new", { folder: path, machine: on ?? "", argv: agent.argv, task });
        this.dismiss();
      } catch (e) {
        this.error = String(e?.message ?? e);
      } finally {
        this.busy = false; cx.notify();
      }
    });
  }

  key(e, cx) {
    if (e.key === "escape") { this.dismiss(); cx.stop_propagation(); return; }
    if (e.key === "tab") {
      if (e.modifiers.shift) this.worktree = !this.worktree;
      else this.agent = (this.agent + 1) % AGENTS.length;
      cx.stop_propagation(); cx.notify();
    }
  }

  render() {
    const t = theme();
    const chip = (id, label, on, click) => div().id(id).px(10).py(4).rounded(6).border_1().cursor_pointer()
      .border_color(on ? t.accent : t.input).bg(on ? t.selected : t.raised).text_color(on ? t.foreground : t.muted)
      .on_click((_e, cx) => { click(); cx.notify(); }).child(label);
    const useTree = this.worktree && this.repo;
    const branch = branchFor(this.text);
    const where = useTree ? `new space · worktree ${this.repo.split("/").pop()} on ${branch}` : `new tab in ${this.cwd ?? "home"}`;
    return v_flex().id("agent-launch").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .w_full().p(18).gap(12).bg(t.popover).text_color(t.foreground).text_size(12.5)
      .child(h_flex().items_center().child(div().flex_1().text_size(15).font_semibold().child("Start agent"))
        .child(div().text_size(11).text_color(t.dim).child("Tab agent · ⇧Tab worktree · Esc")))
      .child(Input.new(this.input).h(36).px(10).rounded(9).border_1().border_color(t.accent).bg(t.background).text_size(12.8).text_color(t.foreground))
      .child(h_flex().gap(6).items_center()
        .children(AGENTS.map((a, i) => chip(`la-agent-${a.name}`, a.name, i === this.agent, () => { this.agent = i; })))
        .child(div().w(12))
        .when(Boolean(this.repo), (el) => el.child(chip("la-tree", "worktree", this.worktree, () => { this.worktree = !this.worktree; }))))
      .child(div().text_size(11.5).text_color(t.dim).truncate().child(where))
      .when(Boolean(this.error), (el) => el.child(div().text_size(11.5).text_color(t.ansi1).child(this.error)))
      .child(h_flex().gap(8).justify_end()
        .child(div().id("la-cancel").h(32).px(14).flex().items_center().rounded(8).bg(t.raised).cursor_pointer()
          .on_click(() => this.dismiss()).child("Cancel"))
        .child(div().id("la-start").h(32).px(14).flex().items_center().rounded(8).cursor_pointer()
          .bg(this.text.trim() ? t.solid : t.raised).text_color(this.text.trim() ? t.solid_foreground : t.dim)
          .on_click((_e, cx) => this.start(cx)).child(this.busy ? "Creating worktree…" : "Start")));
  }
}
