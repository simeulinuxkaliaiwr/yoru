.pragma library

// Hyprland's and niri's binds put into aro's form (`bind = mod+shift+q, close[, arg]`),
// so the keys view reads one language whatever the compositor.

// letters, and the key names KeysView.nice() knows, in aro's spelling; anything else as written
function keyName(k) {
    const l = k.toLowerCase();
    return k.length === 1 || ["apostrophe", "minus", "period", "slash", "bracketleft", "bracketright", "space", "escape",
                              "left", "right", "up", "down", "return", "comma", "equal"].includes(l) ? l : k;
}

const hyprMods = { super: "mod", win: "mod", logo: "mod", mod4: "mod", shift: "shift", ctrl: "ctrl", control: "ctrl", alt: "alt", mod1: "alt" };
const dirs = { l: "left", r: "right", u: "up", d: "down", left: "left", right: "right", up: "up", down: "down" };

// every match of a /g pattern (Qt's JavaScript has no String.matchAll)
function all(re, s) {
    const out = []; let m;
    re.lastIndex = 0;
    while ((m = re.exec(s)) !== null) { out.push(m); if (m[0] === "") re.lastIndex++; }
    return out;
}

function line(combo, action, arg) {
    return "bind = " + combo + ", " + action + (arg !== "" && arg !== undefined ? ", " + arg : "");
}

// Hyprland before 0.56, hyprland.conf: bind = SUPER SHIFT, Q, killactive
function fromHyprConf(text) {
    const vars = {};
    for (const m of all(/^\s*\$(\w+)\s*=\s*(.*?)\s*$/gm, text)) vars[m[1]] = m[2];
    const act = { exec: "spawn", killactive: "close", togglefloating: "float", fullscreen: "fullscreen", exit: "quit",
                  workspace: "workspace", movetoworkspace: "sendto", movetoworkspacesilent: "sendto", movefocus: "focus",
                  movewindow: "move", resizeactive: "resize", togglesplit: "split", pin: "sticky", cyclenext: "switch",
                  togglespecialworkspace: "scratchpad_show", togglegroup: "group" };
    const out = [];
    for (const raw of text.split("\n")) {
        const m = raw.replace(/\s#.*$/, "").match(/^\s*bind[lrenit]*\s*=\s*([^,]*),\s*([^,]+),\s*([^,]+?)\s*(?:,\s*(.*?))?\s*$/);
        if (!m) continue;
        const mods = m[1].replace(/\$(\w+)/g, (_, k) => vars[k] ?? k).trim().toLowerCase()
            .split(/[\s_+]+/).filter(x => x).map(x => hyprMods[x] ?? x);
        let a = m[3].trim().toLowerCase(), arg = (m[4] ?? "").replace(/\$(\w+)/g, (_, k) => vars[k] ?? "$" + k).trim();
        if (a === "movetoworkspace" && arg.startsWith("special")) { a = "scratchpad"; arg = ""; }
        if (a === "fullscreen" && arg === "1") { a = "maximize"; arg = ""; }
        if ((a === "movefocus" || a === "movewindow") && dirs[arg]) arg = dirs[arg];
        out.push(line(mods.concat(keyName(m[2].trim())).join("+"), act[a] ?? a, arg));
    }
    return out.join("\n");
}

// --- Hyprland 0.56+, hyprland.lua: hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal)) ---
// Lua is code, so this reads the plain shapes: string locals, `..` joins, and
// numeric for loops (the stock config binds its workspaces in one).

function stripLuaComments(text) {
    let out = "", q = null;
    for (let i = 0; i < text.length; i++) {
        const c = text[i];
        if (q) { out += c; if (c === "\\") { out += text[++i] ?? ""; } else if (c === q) q = null; continue; }
        if (c === '"' || c === "'") { q = c; out += c; continue; }
        if (c === "-" && text[i + 1] === "-") { while (i < text.length && text[i] !== "\n") i++; out += "\n"; continue; }
        out += c;
    }
    return out;
}

// splits at top-level commas (or at `sep`), past strings and brackets
function split(s, sep) {
    const parts = []; let depth = 0, q = null, cur = "";
    for (let i = 0; i < s.length; i++) {
        const c = s[i];
        if (q) { cur += c; if (c === "\\") cur += s[++i] ?? ""; else if (c === q) q = null; continue; }
        if (c === '"' || c === "'") { q = c; cur += c; continue; }
        if ("({[".includes(c)) depth++;
        if (")}]".includes(c)) depth--;
        if (depth === 0 && s.startsWith(sep, i)) { parts.push(cur.trim()); cur = ""; i += sep.length - 1; continue; }
        cur += c;
    }
    if (cur.trim() !== "") parts.push(cur.trim());
    return parts;
}

// the text inside the bracket that opens at `at`
function inside(s, at) {
    let depth = 0, q = null;
    for (let i = at; i < s.length; i++) {
        const c = s[i];
        if (q) { if (c === "\\") i++; else if (c === q) q = null; continue; }
        if (c === '"' || c === "'") { q = c; continue; }
        if (c === "(") depth++;
        if (c === ")" && --depth === 0) return s.slice(at + 1, i);
    }
    return null;
}

function value(expr, env) {
    expr = expr.trim();
    const str = expr.match(/^"((?:[^"\\]|\\.)*)"$|^'((?:[^'\\]|\\.)*)'$/);
    if (str) return (str[1] ?? str[2]).replace(/\\(.)/g, "$1");
    if (/^-?\d+(\.\d+)?$/.test(expr)) return Number(expr);
    if (/^[A-Za-z_]\w*$/.test(expr)) return env[expr];
    const mod = expr.match(/^(\w+)\s*%\s*(\d+)$/);
    if (mod && typeof env[mod[1]] === "number") return env[mod[1]] % Number(mod[2]);
    const parts = split(expr, "..");
    if (parts.length > 1) {
        const vs = parts.map(p => value(p, env));
        return vs.some(v => v === undefined) ? undefined : vs.join("");
    }
    return undefined;
}

// { direction = "left", workspace = i } → { direction: "left", workspace: 3 }
function table(expr, env) {
    const t = {};
    const m = expr.trim().match(/^\{([\s\S]*)\}$/);
    if (!m) return null;
    for (const kv of split(m[1], ",")) {
        const p = kv.match(/^(\w+)\s*=\s*([\s\S]+)$/);
        if (p) t[p[1]] = value(p[2], env);
    }
    return t;
}

function luaBind(args, env) {
    const combo = value(args[0], env);
    const d = (args[1] ?? "").match(/^hl\.dsp\.([\w.]+)\s*\(/);
    if (typeof combo !== "string" || !d) return null;
    const opts = args[2] ? table(args[2], env) : null;
    if (opts?.mouse) return null;
    const keys = combo.split("+").map(k => k.trim()).filter(k => k);
    const key = keys.pop();
    if (!key || /^mouse/.test(key)) return null;
    const mods = keys.map(k => hyprMods[k.toLowerCase()] ?? k.toLowerCase());
    const inner = inside(args[1], args[1].indexOf("("));
    const first = split(inner ?? "", ",")[0] ?? "";
    const t = first.startsWith("{") ? table(first, env) ?? {} : {};
    const v = first.startsWith("{") ? undefined : value(first, env);
    let a = d[1], arg = "";
    if (a === "exec_cmd") { a = "spawn"; arg = v ?? first; }
    else if (a === "window.close") a = "close";
    else if (a === "window.float") a = "float";
    else if (a === "window.fullscreen") a = t.mode === "maximized" ? "maximize" : "fullscreen";
    else if (a === "window.pin") a = "sticky";
    else if (a === "exit") a = "quit";
    else if (a === "layout" && v === "togglesplit") a = "split";
    else if (a === "workspace.toggle_special") a = "scratchpad_show";
    else if (a === "focus" && t.direction) { a = "focus"; arg = dirs[t.direction] ?? t.direction; }
    else if (a === "focus" && t.workspace !== undefined) { a = "workspace"; arg = String(t.workspace); }
    else if (a === "window.move" && String(t.workspace ?? "").startsWith("special")) a = "scratchpad";
    else if (a === "window.move" && t.workspace !== undefined) { a = "sendto"; arg = String(t.workspace); }
    else if (a === "window.move" && t.direction) { a = "move"; arg = dirs[t.direction] ?? t.direction; }
    else if (a === "window.resize" && t.direction) { a = "resize"; arg = dirs[t.direction] ?? t.direction; }
    else a = a.replace(/\./g, "_");
    return line(mods.concat(keyName(key)).join("+"), a, arg);
}

function fromHyprLua(text) {
    const src = stripLuaComments(text);
    const env = {};
    const out = [];
    // walks statements line by line; a `for v = a, b do … end` block runs its body once per value
    function run(lines, env) {
        for (let i = 0; i < lines.length; i++) {
            const l = lines[i];
            const loop = l.match(/^\s*for\s+(\w+)\s*=\s*(-?\d+)\s*,\s*(-?\d+)\s*do\s*$/);
            if (loop) {
                let depth = 1, j = i + 1;
                for (; j < lines.length; j++) {
                    if (/^\s*(for|if|while)\b.*\b(do|then)\s*$/.test(lines[j]) || /\bfunction\b/.test(lines[j])) depth++;
                    if (/^\s*end\b/.test(lines[j]) && --depth === 0) break;
                }
                const body = lines.slice(i + 1, j);
                for (let n = Number(loop[2]); n <= Number(loop[3]); n++) run(body, Object.assign({}, env, { [loop[1]]: n }));
                i = j;
                continue;
            }
            const local = l.match(/^\s*local\s+(\w+)\s*=\s*(.+?)\s*$/);
            if (local && !/hl\.bind\s*\(/.test(local[2])) { const v = value(local[2], env); if (v !== undefined) env[local[1]] = v; continue; }
            const at = l.search(/hl\.bind\s*\(/);
            if (at < 0) continue;
            // a call can run over several lines: gather until its bracket closes
            let s = l.slice(at), k = i;
            while (inside(s, s.indexOf("(")) === null && k + 1 < lines.length) s += "\n" + lines[++k];
            i = k;
            const r = luaBind(split(inside(s, s.indexOf("(")) ?? "", ","), env);
            if (r) out.push(r);
        }
    }
    run(src.split("\n"), env);
    return out.join("\n");
}

// --- niri, config.kdl: Mod+Shift+Q { close-window; } ---
function fromNiri(text) {
    const mods = { Mod: "mod", Super: "mod", Win: "mod", Shift: "shift", Ctrl: "ctrl", Control: "ctrl", Alt: "alt" };
    const act = { "close-window": "close", "toggle-window-floating": "float", "fullscreen-window": "fullscreen",
                  "maximize-column": "maximize", "focus-workspace": "workspace", "move-column-to-workspace": "sendto",
                  "move-window-to-workspace": "sendto", "toggle-overview": "overview", "quit": "quit",
                  "switch-preset-column-width": "width", "consume-or-expel-window-left": "group" };
    const re = /^\s*([A-Za-z0-9_+]+)((?:\s+[a-z-]+=(?:"[^"]*"|\S+))*)\s*\{\s*([a-z-]+)((?:\s+(?:"(?:[^"\\]|\\.)*"|[^;\s]+))*)\s*;\s*\}/;
    const out = [];
    for (const raw of text.split("\n")) {
        if (/^\s*\/\//.test(raw)) continue;
        const m = raw.match(re);
        if (!m || (!m[1].includes("+") && !/^(XF86|Print)/.test(m[1]))) continue;
        const parts = m[1].split("+");
        const key = parts.pop();
        const combo = parts.map(x => mods[x] ?? x.toLowerCase()).concat(keyName(key)).join("+");
        const args = all(/"((?:[^"\\]|\\.)*)"|([^\s"]+)/g, m[4] ?? "").map(x => x[1] !== undefined ? x[1].replace(/\\"/g, '"') : x[2]);
        let a = m[3], arg = args.join(" ");
        const d = a.match(/^(focus|move)-(?:column|window)(?:-or-[a-z]+)?-(left|right|up|down)$/);
        if (d) { a = d[1]; arg = d[2]; }
        else if (a === "spawn" || a === "spawn-sh") a = "spawn";
        else a = act[a] ?? a.replace(/-/g, "_");
        out.push(line(combo, a, arg));
    }
    return out.join("\n");
}
