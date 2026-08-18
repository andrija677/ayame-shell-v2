pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../settings"

QtObject {
    id: root

    readonly property var events: eventAdapter.events ?? []

    function dateKey(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return year + "-" + month + "-" + day;
    }

    function eventsForDate(date) {
        const key = dateKey(date);
        const monthDay = key.slice(5);
        return events.filter(event => event.date === key
            || (event.recurrence === "yearly" && event.date.slice(5) === monthDay));
    }

    function occurrenceForEvent(event, fromDate) {
        const parts = event.date.split("-").map(Number);
        let occurrence = new Date(parts[0], parts[1] - 1, parts[2]);
        if (event.recurrence === "yearly") {
            occurrence = new Date(fromDate.getFullYear(), parts[1] - 1, parts[2]);
            if (occurrence < new Date(fromDate.getFullYear(),
                    fromDate.getMonth(), fromDate.getDate()))
                occurrence.setFullYear(occurrence.getFullYear() + 1);
        }
        return occurrence;
    }

    function upcomingEvents(dayRange) {
        const today = new Date();
        const start = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        const dayMs = 24 * 60 * 60 * 1000;
        const upcoming = [];
        for (const event of events) {
            const occurrence = occurrenceForEvent(event, start);
            const daysUntil = Math.round((occurrence - start) / dayMs);
            if (daysUntil >= 0 && daysUntil <= dayRange) {
                upcoming.push({
                    id: event.id,
                    title: event.title,
                    occurrence: occurrence,
                    daysUntil: daysUntil,
                    reminderDays: event.reminderDays ?? 0,
                    recurrence: event.recurrence
                });
            }
        }
        upcoming.sort((a, b) => a.daysUntil - b.daysUntil);
        return upcoming;
    }

    function addEvent(title, date, yearly, reminderDays) {
        const cleanTitle = String(title || "").trim();
        if (!cleanTitle) return false;
        const updated = events.slice();
        updated.push({
            id: Date.now().toString() + Math.random().toString(16).slice(2),
            title: cleanTitle,
            date: dateKey(date),
            recurrence: yearly ? "yearly" : "none",
            reminderDays: reminderDays ?? 0
        });
        eventAdapter.events = updated;
        eventFile.writeAdapter();
        return true;
    }

    function removeEvent(id) {
        eventAdapter.events = events.filter(event => event.id !== id);
        eventFile.writeAdapter();
    }

    property FileView eventFile: FileView {
        id: eventFile
        path: StoragePaths.dataDir + "/events.json"
        preload: true
        atomicWrites: true
        printErrors: false
        JsonAdapter {
            id: eventAdapter
            property var events: []
        }
    }
}
