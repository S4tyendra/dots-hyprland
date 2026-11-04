pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Search index for the settings overlay.
 *
 * The index is built by parsing the settings pages' QML source files,
 * which the overlay feeds in as text (one FileView per page). Pages are
 * never instantiated for indexing, so searching doesn't pay the cost of
 * creating every page's object tree, and unvisited pages stay unloaded.
 * Keybind labels are extracted from the Hyprland keybind files the same
 * way (see `indexKeybinds()`).
 *
 * Entry shape: { pageIndex, pageName, pageIcon, section, sectionIcon, label }
 */
Singleton {
    id: root

    property var allEntries: []
    property string query: ""

    signal navigationRequested(var entry)
    readonly property var results: search(root.query, 60)

    function search(query, limit = 60) {
        const tokens = query.toLowerCase().trim().split(/\s+/).filter(Boolean);
        if (tokens.length === 0) return [];
        const scored = [];
        for (const entry of root.allEntries) {
            const label = Translation.tr(entry.label).toLowerCase();
            const section = Translation.tr(entry.section).toLowerCase();
            const page = entry.pageName.toLowerCase();
            const combined = [label, section, page, entry.label, entry.section].join(" ").toLowerCase();
            if (!tokens.every(token => combined.includes(token))) continue;
            const score = tokens.reduce((total, token) => total + (label.startsWith(token) ? 0 : label.includes(token) ? 1 : section.includes(token) ? 2 : 3), 0);
            scored.push({entry: entry, score: score});
        }
        scored.sort((a, b) => a.score - b.score || a.entry.label.length - b.entry.label.length);
        return scored.slice(0, limit).map(item => item.entry);
    }

    // Block types whose label property names a searchable setting. The
    // property carrying the label differs per type; see labelFor().
    readonly property var labelledTypes: [
        "ConfigSwitch", "ConfigSpinBox", "ConfigSlider", "ConfigComboBox",
        "ConfigSelectionArray", "ConfigTextArea", "RippleButtonWithIcon"
    ]

    /** Replace the index entries belonging to one settings page. */
    function indexPage(pageIndex, pageName, pageIcon, source) {
        root.replaceEntries(pageIndex, "page", pageName, pageIcon, root.parsePageSource(source))
    }

    /** Index keybind descriptions extracted from the Hyprland keybind files. */
    function indexKeybinds(pageIndex, pageName, pageIcon, sources) {
        const parsed = []
        const seen = {}
        const descriptionRe = /description\s*=\s*"((?:[^"\\]|\\.)*)"/
        for (let s = 0; s < sources.length; s++) {
            const lines = (sources[s] || "").split("\n")
            for (let i = 0; i < lines.length; i++) {
                const match = lines[i].match(descriptionRe)
                if (!match)
                    continue
                const label = match[1].replace(/\\(.)/g, "$1")
                if (label.length < 2 || seen[label])
                    continue
                seen[label] = true
                parsed.push({ section: "Keybinds", sectionIcon: "keyboard", label: label })
            }
        }
        root.replaceEntries(pageIndex, "keybinds", pageName, pageIcon, parsed)
    }

    function replaceEntries(pageIndex, origin, pageName, pageIcon, parsed) {
        const others = []
        for (let i = 0; i < root.allEntries.length; i++) {
            const entry = root.allEntries[i]
            if (entry.pageIndex !== pageIndex || entry.origin !== origin)
                others.push(entry)
        }
        const pageEntries = []
        for (let i = 0; i < parsed.length; i++) {
            pageEntries.push({
                pageIndex: pageIndex,
                pageName: pageName,
                pageIcon: pageIcon,
                section: parsed[i].section,
                sectionIcon: parsed[i].sectionIcon,
                label: parsed[i].label,
                origin: origin
            })
        }
        root.allEntries = others.concat(pageEntries)
    }

    /**
     * Extract section and control labels from one page's QML source.
     * A brace-counting stack tracks the enclosing block type; a `title:`,
     * `text:` or `mainText:` line holding a string literal is attributed
     * to that block. Braces inside strings can skew the stack, but
     * balanced one-liners cancel out and the pages are written one
     * property per line, which is what this relies on.
     */
    function parsePageSource(source) {
        const entries = []
        const seen = {}
        const typeStack = []
        let section = ""
        let sectionIcon = ""
        let sectionEntryStart = 0
        let sectionTitleSeen = false
        let pendingIcon = ""

        const typeOpenRe = /^\s*([A-Z][\w.]*)\s*\{/
        const labelRe = /^\s*(title|text|mainText)\s*:\s*(?:Translation\.tr\(\s*)?"((?:[^"\\]|\\.)*)"/
        const labelReSingle = /^\s*(title|text|mainText)\s*:\s*(?:Translation\.tr\(\s*)?'((?:[^'\\]|\\.)*)'/
        const iconRe = /^\s*icon\s*:\s*"([^"]*)"/

        const lines = (source || "").split("\n")
        for (let li = 0; li < lines.length; li++) {
            const line = lines[li]
            const enclosing = typeStack.length > 0 ? typeStack[typeStack.length - 1] : ""
            const typeMatch = line.match(typeOpenRe)

            if (typeMatch && typeMatch[1] === "ContentSection") {
                sectionEntryStart = entries.length
                sectionTitleSeen = false
                pendingIcon = ""
            }

            // A section's `icon:` may come before or after its `title:`;
            // whichever arrives second completes the pair, and entries
            // already emitted for this section get the icon backfilled.
            if (enclosing === "ContentSection") {
                const iconMatch = line.match(iconRe)
                if (iconMatch) {
                    pendingIcon = iconMatch[1]
                    if (sectionTitleSeen) {
                        sectionIcon = pendingIcon
                        for (let e = sectionEntryStart; e < entries.length; e++)
                            entries[e].sectionIcon = sectionIcon
                    }
                }
            }

            const labelMatch = line.match(labelRe) || line.match(labelReSingle)
            if (labelMatch && enclosing !== "") {
                const prop = labelMatch[1]
                const label = labelMatch[2].replace(/\\(.)/g, "$1").replace(/\s+/g, " ").trim()
                if (enclosing === "ContentSection" && prop === "title") {
                    section = label
                    sectionIcon = pendingIcon
                    sectionTitleSeen = true
                    root.pushEntry(entries, seen, section, sectionIcon, label)
                } else if (enclosing === "ContentSubsection" && prop === "title") {
                    root.pushEntry(entries, seen, section, sectionIcon, label)
                } else if (root.labelledTypes.indexOf(enclosing) !== -1 && prop === root.labelPropFor(enclosing)) {
                    root.pushEntry(entries, seen, section, sectionIcon, label)
                }
            }

            let opens = 0
            let closes = 0
            for (let ci = 0; ci < line.length; ci++) {
                if (line[ci] === "{")
                    opens++
                else if (line[ci] === "}")
                    closes++
            }
            for (let c = 0; c < closes; c++)
                typeStack.pop()
            for (let o = 0; o < opens; o++)
                typeStack.push(o === 0 && typeMatch ? typeMatch[1] : "")
        }
        return entries
    }

    function labelPropFor(type) {
        return type === "RippleButtonWithIcon" ? "mainText" : (type === "ContentSubsection" ? "title" : "text")
    }

    function pushEntry(entries, seen, section, sectionIcon, label) {
        if (label.length < 2 || label.length > 120)
            return
        const key = section + "|" + label
        if (seen[key])
            return
        seen[key] = true
        entries.push({ section: section, sectionIcon: sectionIcon, label: label })
    }
}
