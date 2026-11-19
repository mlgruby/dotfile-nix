// Bottom status bar for the Herdr app: Herdr's own facts on the left,
// the tmux status-right segments on the right. The segments come from the
// same script tmux runs (~/.config/tmux/status/status-right.sh), so both
// bars show the same data. The script prints tmux style markup
// (#[fg=..,bg=..]text); parse() turns it into coloured runs.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, spaces, panes, focused, theme, exec, home, checking, props, setBadge } from "herdr";

const SEPARATOR = "\u{e0b2}"; // powerline left-pointing solid arrow
const REFRESH_MS = 10000; // same as tmux status-interval
const FONT = "JetBrainsMono NFM"; // Nerd Font glyphs used by the script
// The status-left.sh segments that belong in this bar: the next meeting
// and PRs waiting on your review. The session name and the herdr TUI count
// are left out (the app shows its own agents on the left).
const LEFT_EXTRAS = `
d="$HOME/.config/tmux/status"
source "$d/lib.sh"; source "$d/calendar.sh"; source "$d/reviews.sh"
tmux_status_collect_calendar; tmux_status_collect_reviews
status_output=""; status_prev_bg="#1d2021"
append_segment "$calendar_bg" "$calendar_fg" "$calendar_status"
append_segment "$reviews_bg" "$reviews_fg" "$reviews_status"
printf '%s' "$status_output"
`;
// tmux bar background in status-right.sh; drawn as the app bar colour instead.
const TMUX_BAR_BG = "#1d2021";
// Segment backgrounds that tmux_status_alt_bg (lib.sh) takes in turn.
const SEGMENT_BG = ["#3c3836", "#504945"];
// The dot between items in one segment, as codexbar.sh draws it (AI_SEPARATOR).
const DOTS = "#bdae93";
const dots = (id) => div().id(id).flex_none().text_color(DOTS).child("\u22ee");
// Puts the dots between each two items.
const dotted = (key, items) => items.flatMap((el, i) => (i ? [dots(`${key}-dots-${i}`), el] : [el]));
// The open PR of the focused terminal's branch, and its checks. gh asks
// GitHub, so look once a minute, and again when the folder changes.
const PR_MS = 60000;
const PR_FIELDS = "number,state,isDraft,url,statusCheckRollup";

// The focused terminal's folder; null on a remote machine (gh runs here).
function focusedFolder() {
  const space = spaces().find((s) => s.active), f = focused();
  const pane = f?.pane ? panes().find((p) => p.pane === f.pane) : null;
  const remote = f?.pane === null ? f.terminal?.includes("/") : Boolean(space?.machine);
  return remote ? null : pane?.cwd || f?.cwd || space?.folder || null;
}

// Sum of a PR's checks: CheckRun has status/conclusion, StatusContext has state.
export function checkSummary(rollup) {
  const n = { pass: 0, fail: 0, pending: 0 };
  for (const c of rollup ?? []) {
    const v = (c.conclusion || c.state || "").toUpperCase();
    if (c.status && c.status !== "COMPLETED") n.pending++;
    else if (["FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"].includes(v)) n.fail++;
    else if (["PENDING", "EXPECTED", "QUEUED", "IN_PROGRESS", ""].includes(v)) n.pending++;
    else n.pass++;
  }
  return n;
}

// The AWS profile that aws.sh shows (for Copy on click).
const AWS_PROFILE = `
d="$HOME/.config/tmux/status"
source "$d/lib.sh"; source "$d/aws.sh"; tmux_status_collect_aws
printf '%s' "$aws_profile"
`;
// Clickable segments, found by their text: what a click does and its tooltip.
const ACTIONS = [
  { test: /\breviews?\b/, tip: "Open PRs waiting on your review", run: () => exec("open", ["https://github.com/pulls/review-requested"]) },
  { test: /NOW:|in \d+m:/, tip: "Open Calendar", run: () => exec("open", ["-a", "Calendar"]) },
  {
    test: /\u{f0e0f}/u, tip: "Copy the AWS profile name",
    run: async (cx) => {
      const r = await exec("bash", ["-c", AWS_PROFILE], { timeout: 5000 });
      if (r.code === 0 && r.stdout) cx.write_to_clipboard(r.stdout);
    },
  },
];

// Split tmux markup into runs of { fg, bg, text }.
export function parse(markup) {
  const runs = [];
  let fg = null;
  let bg = null;
  const re = /#\[([^\]]*)\]|([^#]+|#(?!\[))/g;
  for (const m of markup.matchAll(re)) {
    if (m[1] !== undefined) {
      for (const attr of m[1].split(",")) {
        const [k, v] = attr.split("=");
        if (k === "fg") fg = v === "default" ? null : v;
        else if (k === "bg") bg = v === "default" ? null : v;
        else if (k === "default") { fg = null; bg = null; }
      }
    } else if (m[2]) {
      const last = runs[runs.length - 1];
      if (last && last.fg === fg && last.bg === bg && m[2] !== SEPARATOR && last.text !== SEPARATOR) last.text += m[2];
      else runs.push({ fg, bg, text: m[2] });
    }
  }
  return runs;
}

export default class DevStatus extends View {
  init(_props, cx) {
    this.runs = [];
    this.error = null;
    if (checking()) return;
    this.script = `${home()}/.config/tmux/status/status-right.sh`;
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
    this.pr = null; // { number, url, draft, checks } or null
    this.refreshPr(cx, true);
    // Look each 2 s for a new folder; ask GitHub when it changes or PR_MS passed.
    cx.timer.every(2000, (cx) => this.refreshPr(cx, false));
  }

  refreshPr(cx, force) {
    const cwd = focusedFolder();
    const due = force || cwd !== this.prAt || Date.now() - (this.prChecked ?? 0) > PR_MS;
    if (this.prBusy || !due) return;
    this.prBusy = true;
    this.prAt = cwd;
    this.prChecked = Date.now();
    cx.spawn(async (cx) => {
      let pr = null;
      try {
        if (cwd) {
          const r = await exec("gh", ["pr", "view", "--json", PR_FIELDS], { cwd, timeout: 15000 });
          const d = r.code === 0 ? JSON.parse(r.stdout) : null;
          if (d?.state === "OPEN") pr = { number: d.number, url: d.url, draft: d.isDraft, checks: checkSummary(d.statusCheckRollup) };
        }
      } catch {}
      finally { this.prBusy = false; }
      if (cwd === this.prAt && JSON.stringify(pr) !== JSON.stringify(this.pr)) { this.pr = pr; cx.notify(); }
    });
  }

  prSegment(t) {
    const pr = this.pr;
    if (!pr) return null;
    const c = pr.checks;
    // GitHub Actions icon, then one state glyph (Font Awesome stroke): x, clock or check.
    const [icon, color] = c.fail ? ["\u{f00d}", t.ansi9]
      : c.pending ? ["\u{f017}", t.blocked]
      : c.pass ? ["\u{f00c}", t.done] : [null, t.dim];
    const tip = `PR #${pr.number}${pr.draft ? " (draft)" : ""}: ${c.pass} passed, ${c.fail} failed, ${c.pending} running. Click to open.`;
    return h_flex().id("pr").gap(8).items_center().flex_none().cursor_pointer().tooltip(tip)
      .on_click(() => { exec("open", [pr.url]).catch(() => {}); })
      .child(div().text_color(pr.draft ? t.dim : t.ansi13).child(`\u{f407} #${pr.number}`))
      .when(Boolean(icon), (el) => el.child(dots("pr-dots"))
        .child(h_flex().gap(6).items_center()
          .child(div().text_color(t.muted).child("\u{f52e}"))
          .child(div().text_color(color).child(icon))));
  }

  refresh(cx) {
    if (this.busy) return;
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        const [extra, r] = await Promise.all([
          exec("bash", ["-c", LEFT_EXTRAS], { timeout: 20000 }).catch(() => null),
          exec("bash", [this.script], { timeout: 20000 }),
        ]);
        if (r.code === 0) {
          const extraRuns = extra?.code === 0 ? parse(extra.stdout.replace(/\n+$/, "")) : [];
          const rightRuns = parse(r.stdout.replace(/\n+$/, ""));
          // Join the two groups: the first status-right arrow starts on the
          // last extra segment's colour, not on the bar background.
          const lastBg = extraRuns.filter((x) => x.bg && x.bg.toLowerCase() !== TMUX_BAR_BG).pop()?.bg;
          if (lastBg && rightRuns[0]?.text === SEPARATOR) rightRuns[0] = { ...rightRuns[0], bg: lastBg };
          this.runs = [...extraRuns, ...rightRuns];
          this.error = null;
        } else {
          this.error = (r.stderr || "status-right.sh failed").trim().split("\n")[0];
        }
      } catch (e) {
        this.error = String(e?.message ?? e);
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  left(t) {
    const list = agents();
    const count = (status) => list.filter((a) => a.status === status).length;
    // One icon and count per state that has agents (Nerd Font glyphs; the
    // robot matches the tmux herdr segment). Hover shows the state name.
    const states = [
      ["working", "\u{f06a9}", t.working],
      ["blocked", "\u{f009e}", t.blocked],
      ["done", "\u{f012c}", t.done],
      ["idle", "\u{f04b2}", t.idle ?? t.muted],
      ["unknown", "\u{f0625}", t.dim],
    ].map(([name, icon, color]) => ({ name, icon, color, n: count(name) })).filter((st) => st.n > 0);
    const agentsEl = h_flex().gap(12).items_center()
      .when(list.length === 0, (el) => el.child(div().text_color(t.dim).child("no agents")))
      .children(dotted("agents", states.map((st) => div().id(`agents-${st.name}`).text_color(st.color).tooltip(`${st.n} ${st.name}`).child(`${st.icon} ${st.n}`))));
    // Segments as on the right side: tmux's two greys in turn, then an arrow
    // that points right, into the next segment or the bar.
    const parts = [agentsEl, this.prSegment(t)].filter(Boolean);
    const bgs = parts.map((_, i) => SEGMENT_BG[i % 2]);
    return h_flex().h_full().items_center().overflow_hidden().flex_1()
      .children(parts.flatMap((el, i) => [
        div().id(`left-${i}`).h_full().flex_none().flex().items_center().px(12).bg(bgs[i]).child(el),
        div().id(`left-sep-${i}`).h_full().w(12).flex_none().when(i + 1 < parts.length, (s) => s.bg(bgs[i + 1]))
          .child(svg("mods/dev-status/sep-right.svg").w(12).h_full().text_color(bgs[i])),
      ]));
  }

  right(t) {
    const bg = (c) => (c && c.toLowerCase() !== TMUX_BAR_BG ? c : null);
    if (this.error) {
      return h_flex().px(12).items_center().text_color(t.blocked).child(this.error);
    }
    return h_flex().h_full().flex_none().items_center().children(
      this.runs.map((r, i) => {
        if (r.text === SEPARATOR) {
          return div().id(`sep-${i}`).h_full().w(12).flex_none().when(Boolean(bg(r.bg)), (el) => el.bg(bg(r.bg)))
            .child(svg("mods/dev-status/sep.svg").w(12).h_full().text_color(r.fg ?? t.chrome));
        }
        const action = ACTIONS.find((a) => a.test.test(r.text));
        return div().id(`run-${i}`).h_full().flex_none().flex().items_center().whitespace_nowrap()
          .when(Boolean(action), (el) => el.cursor_pointer().tooltip(action.tip)
            .on_click((_e, cx) => cx.spawn(async (cx) => { try { await action.run(cx); } catch {} })))
          .when(Boolean(bg(r.bg)), (el) => el.bg(bg(r.bg)))
          .text_color(r.fg ?? t.foreground)
          .child(r.text);
      }));
  }

  // Dock badge: how many agents need you. Set only when the number changes.
  badge(list) {
    const n = list.filter((a) => a.status === "blocked").length;
    if (n === this.badged) return;
    this.badged = n;
    setBadge(n ? String(n) : null);
  }

  render() {
    const t = theme();
    if (!checking()) this.badge(agents());
    // props.edge "top": the bar sits above the tabs, so the border goes below it.
    const top = props()?.edge === "top";
    return h_flex().id("root").size_full().items_center().bg(t.chrome)
      .when(top, (el) => el.border_b(1)).when(!top, (el) => el.border_t(1)).border_color(t.border)
      .font_family(FONT).text_size(14)
      .child(this.left(t))
      .child(this.right(t));
  }
}
