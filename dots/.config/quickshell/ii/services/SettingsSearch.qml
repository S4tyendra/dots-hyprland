pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * Search index for the settings overlay.
 *
 * Settings pages are loaded lazily. While the user is searching, the settings
 * overlay loads every page once and hands each page item to `indexPage()`.
 * The collected index is kept as plain data, so pages can be unloaded again
 * without losing search results.
 *
 * Entry shape: { pageIndex, pageName, pageIcon, section, sectionIcon, label }
 */
Singleton {
    id: root

    property var allEntries: []
    property string query: ""

    readonly property var results: {
        const q = root.query.trim().toLowerCase()
        if (q === "")
            return []

        const scored = []
        for (let i = 0; i < root.allEntries.length; i++) {
            const entry = root.allEntries[i]
            const label = (entry.label || "").toLowerCase()
            const section = (entry.section || "").toLowerCase()
            const pageName = (entry.pageName || "").toLowerCase()

            let score = -1
            if (label.startsWith(q))
                score = 0
            else if (label.includes(q))
                score = 1
            else if (section.startsWith(q))
                score = 2
            else if (section.includes(q))
                score = 3
            else if (pageName.includes(q))
                score = 4
            if (score < 0)
                continue
            scored.push({ entry: entry, score: score })
        }
        scored.sort((a, b) => a.score - b.score || a.entry.label.length - b.entry.label.length)
        return scored.slice(0, 60).map(item => item.entry)
    }

    /** Replace the index entries belonging to one settings page. */
    function indexPage(pageIndex, pageName, pageIcon, pageItem) {
        const collected = { seen: {}, entries: [] }
        root.collectFromItem(pageItem, collected)
        const others = root.allEntries.filter(entry => entry.pageIndex !== pageIndex)
        const pageEntries = collected.entries.map(entry => ({
            pageIndex: pageIndex,
            pageName: pageName,
            pageIcon: pageIcon,
            section: entry.section,
            sectionIcon: entry.sectionIcon,
            label: entry.label
        }))
        root.allEntries = others.concat(pageEntries)
    }

    function collectFromItem(item, collected) {
        if (!item)
            return

        try {
            const labels = root.labelsFor(item)
            if (labels.length > 0) {
                const section = root.nearestSection(item)
                for (let i = 0; i < labels.length; i++) {
                    const label = String(labels[i]).replace(/\s+/g, " ").trim()
                    if (label.length < 2 || label.length > 120)
                        continue
                    const key = `${section.title}|${label}`
                    if (collected.seen[key])
                        continue
                    collected.seen[key] = true
                    collected.entries.push({
                        label: label,
                        section: section.title,
                        sectionIcon: section.icon
                    })
                }
            }

            const children = item.children
            if (children) {
                for (let i = 0; i < children.length; i++)
                    root.collectFromItem(children[i], collected)
            }
        } catch (e) {
            // Introspection is best-effort: a page may be mid-destruction.
        }
    }

    function labelsFor(item) {
        const labels = []
        const isControl = item.checked !== undefined
            || item.value !== undefined
            || item.currentValue !== undefined
            || item.placeholderText !== undefined

        if (root.isNonEmptyString(item.title))
            labels.push(item.title)
        if (root.isNonEmptyString(item.mainText))
            labels.push(item.mainText)
        if (root.isNonEmptyString(item.placeholderText))
            labels.push(item.placeholderText)
        if (isControl && root.isNonEmptyString(item.text))
            labels.push(item.text)
        return labels
    }

    function nearestSection(item) {
        let title = ""
        let icon = ""
        let current = item
        while (current) {
            if (!title && root.isNonEmptyString(current.title))
                title = current.title
            if (!icon && root.isNonEmptyString(current.icon))
                icon = current.icon
            if (title && icon)
                break
            current = current.parent
        }
        return { title: title, icon: icon }
    }

    function isNonEmptyString(value) {
        return typeof value === "string" && value.trim() !== ""
    }
}
