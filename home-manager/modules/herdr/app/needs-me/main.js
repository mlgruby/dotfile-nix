// A drawer on the right edge of the panes: the agents that wait for you,
// blocked first, then done, the oldest change first. Only the state column
// shows until you hover it. A click goes to that agent. Empty: hidden.
// The same order drives Ctrl+A j (tmux-prefix), from waiting().

import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { agents, placement, run, theme } from "herdr";

const RANK = { blocked: 0, done: 1 };
const ICON = { blocked: "\u{f009e}", done: "\u{f012c}" };

// Agents that wait for the person, in the order to look at them.
export function waiting(list = agents()) {
  return list.filter((a) => a.status in RANK && a.app !== "shell").sort((x, y) => RANK[x.status] - RANK[y.status] || x.seq - y.seq);
}

const clean = (title) => (title ?? "").replace(/^[^\p{L}\p{N}~/]+/u, "").trim();

export default class NeedsMe extends View {
  render() {
    const t = theme();
    const list = waiting();
    if (!list.length) return div();
    const right = placement()?.edge !== "left";
    const color = (s) => (s === "blocked" ? t.blocked : t.done);
    return v_flex().id("needs-me").w(300).py(4).gap(2).text_size(12).text_color(t.foreground)
      .child(h_flex().h(22).px(10).gap(6).items_center().text_size(11).text_color(t.dim)
        .when(right, (el) => el.flex_row_reverse())
        .child(div().flex_none().w(16).text_color(t.blocked).child(String(list.length)))
        .child(div().flex_1().truncate().child("waiting for you")))
      .children(list.map((a) => h_flex().id(`nm-${a.address}`).h(26).px(10).gap(8).items_center().rounded(6)
        .cursor_pointer().hover((s) => s.bg(t.hover))
        .when(right, (el) => el.flex_row_reverse())
        .on_click(() => run("agent.focus", { terminal: a.address }))
        .child(div().flex_none().w(16).text_color(color(a.status)).child(ICON[a.status]))
        .child(div().flex_none().max_w(110).truncate().text_color(t.muted).child(`${a.space_name} · ${a.tab_name || a.tab_index}`))
        .child(div().flex_1().min_w(0).truncate().child(clean(a.title) || a.app || "agent"))));
  }
}
