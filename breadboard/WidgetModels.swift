import AppKit
import Foundation
import SwiftUI

// MARK: - Widget Type

enum WidgetKind: String, CaseIterable, Identifiable, Codable, CustomStringConvertible {
    case html = "HTML Widget"
    case url = "Embedded URL"
    case template = "Pre-built Template"

    var id: String { rawValue }
    var description: String { rawValue }

    var icon: String {
        switch self {
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .url: return "link"
        case .template: return "square.on.square"
        }
    }

    var helpText: String {
        switch self {
        case .html: return "Write custom HTML, CSS, and JavaScript"
        case .url: return "Embed a web page by URL"
        case .template: return "Use a pre-built widget template"
        }
    }
}

// MARK: - Widget Template

struct WidgetTemplate: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var icon: String
    var category: String
    var htmlContent: String

    static let available: [WidgetTemplate] = [
        WidgetTemplate(
            name: "Clock",
            description: "A clean analog or digital clock",
            icon: "clock",
            category: "Utilities",
            htmlContent: clockTemplateHTML
        ),
        WidgetTemplate(
            name: "Notes",
            description: "A simple sticky note widget",
            icon: "note.text",
            category: "Productivity",
            htmlContent: notesTemplateHTML
        ),
        WidgetTemplate(
            name: "System Monitor",
            description: "CPU, memory, and disk usage monitor",
            icon: "chart.pie",
            category: "System",
            htmlContent: systemMonitorTemplateHTML
        ),
        WidgetTemplate(
            name: "Weather",
            description: "Weather display with current conditions",
            icon: "cloud.sun",
            category: "Utilities",
            htmlContent: weatherTemplateHTML
        ),
        WidgetTemplate(
            name: "Todo List",
            description: "A simple task list",
            icon: "checklist",
            category: "Productivity",
            htmlContent: todoTemplateHTML
        ),
        WidgetTemplate(
            name: "Date & Calendar",
            description: "Current date with mini calendar",
            icon: "calendar",
            category: "Utilities",
            htmlContent: dateCalendarTemplateHTML
        ),
        WidgetTemplate(
            name: "Breadboard Variables",
            description: "Monitor and display breadboard variables",
            icon: "variable",
            category: "System",
            htmlContent: variablesTemplateHTML
        ),
        WidgetTemplate(
            name: "GitHub Stats",
            description: "Display GitHub profile statistics",
            icon: "chevron.left.forwardslash.chevron.right",
            category: "Developer",
            htmlContent: githubStatsTemplateHTML
        ),
    ]
}

// MARK: - Widget Item

/// A configurable widget that displays HTML content in a floating panel.
struct WidgetItem: Identifiable, Equatable, Codable {
    var id = UUID()
    var name: String = "New Widget"
    var kind: WidgetKind = .html

    // HTML content (for .html and .template kinds)
    var htmlContent: String = ""

    // URL (for .url kind)
    var urlString: String = ""

    // Template reference (for .template kind)
    var templateID: UUID?

    // Display settings
    var icon: String = "sparkles"
    var isEnabled: Bool = true
    var width: Double = 400
    var height: Double = 300
    var refreshInterval: Double = 0 // 0 = no auto-refresh
    var backgroundColor: String = "#1a1a2e"
    var textColor: String = "#ffffff"
    var cornerRadius: Double = 12

    // Variables that this widget subscribes to (for live updates)
    var subscribedVariableNames: [String] = []

    var summary: String {
        switch kind {
        case .html:
            let preview = htmlContent.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if preview.isEmpty { return "HTML Widget (empty)" }
            let prefix = preview.prefix(60)
            return "HTML: \(prefix)\(preview.count > 60 ? "…" : "")"
        case .url:
            return urlString.isEmpty ? "URL Widget (empty)" : urlString
        case .template:
            if let tid = templateID, let template = WidgetTemplate.available.first(where: { $0.id == tid }) {
                return "Template: \(template.name)"
            }
            return "Template Widget"
        }
    }

    /// Resolve the HTML content to render, substituting templates and variables.
    func resolvedHTML(with variables: [String: String] = [:]) -> String {
        switch kind {
        case .html:
            return substituteVariables(in: htmlContent, variables: variables)
        case .url:
            return "" // URLs are loaded directly in WKWebView
        case .template:
            if let tid = templateID, let template = WidgetTemplate.available.first(where: { $0.id == tid }) {
                return substituteVariables(in: template.htmlContent, variables: variables)
            }
            return substituteVariables(in: htmlContent, variables: variables)
        }
    }

    private func substituteVariables(in html: String, variables: [String: String]) -> String {
        var result = html
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
}

// MARK: - Widgets Config (for JSON persistence)

struct WidgetsConfig: Codable {
    var items: [WidgetItem] = []
}

// MARK: - Defaults

extension WidgetItem {
    static func defaults() -> [WidgetItem] {
        [
            WidgetItem(
                name: "Quick Clock",
                kind: .template,
                templateID: WidgetTemplate.available.first(where: { $0.name == "Clock" })?.id,
                icon: "clock",
                width: 300,
                height: 200,
                refreshInterval: 1
            ),
            WidgetItem(
                name: "Sticky Notes",
                kind: .template,
                templateID: WidgetTemplate.available.first(where: { $0.name == "Notes" })?.id,
                icon: "note.text",
                width: 350,
                height: 300
            ),
        ]
    }
}

// MARK: - Template HTML Content

private let clockTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100vh;
    color: {{textColor}};
    overflow: hidden;
  }
  .clock-container {
    text-align: center;
    background: {{backgroundColor}};
    padding: 24px;
    border-radius: {{cornerRadius}}px;
    width: 100%;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }
  .time {
    font-size: 3em;
    font-weight: 300;
    letter-spacing: 2px;
    font-variant-numeric: tabular-nums;
  }
  .date {
    font-size: 1em;
    opacity: 0.7;
    margin-top: 8px;
  }
  .seconds {
    font-size: 1.2em;
    opacity: 0.5;
  }
</style>
</head>
<body>
<div class="clock-container">
  <div class="time" id="time">00:00</div>
  <div class="date" id="date">Loading...</div>
</div>
<script>
  function updateClock() {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    const s = String(now.getSeconds()).padStart(2, '0');
    document.getElementById('time').innerHTML = h + ':' + m + '<span class="seconds">:' + s + '</span>';
    const opts = { weekday: 'long', month: 'long', day: 'numeric' };
    document.getElementById('date').textContent = now.toLocaleDateString(undefined, opts);
  }
  updateClock();
  setInterval(updateClock, 1000);
</script>
</body>
</html>
"""

private let notesTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
  }
  .note {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }
  .note-header {
    display: flex;
    align-items: center;
    margin-bottom: 12px;
    color: {{textColor}};
  }
  .note-header h2 {
    font-size: 1em;
    font-weight: 600;
    opacity: 0.8;
  }
  .note-body {
    flex: 1;
    background: rgba(255,255,255,0.08);
    border: none;
    border-radius: 8px;
    padding: 12px;
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    font-size: 0.9em;
    color: {{textColor}};
    resize: none;
    outline: none;
    width: 100%;
  }
  .note-body::placeholder {
    color: rgba(255,255,255,0.3);
  }
  .note-footer {
    margin-top: 8px;
    text-align: right;
    font-size: 0.7em;
    opacity: 0.4;
    color: {{textColor}};
  }
</style>
</head>
<body>
<div class="note">
  <div class="note-header">
    <h2>📝 Notes</h2>
  </div>
  <textarea class="note-body" id="noteBody" placeholder="Type something..."></textarea>
  <div class="note-footer" id="noteFooter">Auto-saved locally</div>
</div>
<script>
  const saved = localStorage.getItem('breadboard_notes');
  if (saved) document.getElementById('noteBody').value = saved;
  document.getElementById('noteBody').addEventListener('input', function() {
    localStorage.setItem('breadboard_notes', this.value);
    document.getElementById('noteFooter').textContent = 'Saved ' + new Date().toLocaleTimeString();
  });
</script>
</body>
</html>
"""

private let systemMonitorTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'SF Mono', 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
  }
  h2 {
    font-size: 0.9em;
    font-weight: 600;
    opacity: 0.7;
    margin-bottom: 16px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  .stat {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.06);
  }
  .stat:last-child { border-bottom: none; }
  .stat-label { opacity: 0.6; font-size: 0.85em; }
  .stat-value { font-weight: 500; font-size: 0.85em; }
  .bar-container {
    background: rgba(255,255,255,0.08);
    border-radius: 4px;
    height: 4px;
    margin-top: 4px;
  }
  .bar-fill {
    background: linear-gradient(90deg, #00d2ff, #3a7bd5);
    border-radius: 4px;
    height: 100%;
    transition: width 0.5s ease;
  }
</style>
</head>
<body>
<div class="container">
  <h2>System Monitor</h2>
  <div class="stat">
    <span class="stat-label">CPU</span>
    <span class="stat-value" id="cpu">--</span>
  </div>
  <div class="bar-container"><div class="bar-fill" id="cpuBar" style="width:0%"></div></div>
  <div class="stat">
    <span class="stat-label">Memory</span>
    <span class="stat-value" id="memory">--</span>
  </div>
  <div class="bar-container"><div class="bar-fill" id="memBar" style="width:0%"></div></div>
  <div class="stat">
    <span class="stat-label">Uptime</span>
    <span class="stat-value" id="uptime">--</span>
  </div>
  <div class="stat">
    <span class="stat-label">Processes</span>
    <span class="stat-value" id="processes">--</span>
  </div>
</div>
<script>
  function formatUptime(seconds) {
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (d > 0) return d + 'd ' + h + 'h';
    if (h > 0) return h + 'h ' + m + 'm';
    return m + 'm';
  }

  async function updateStats() {
    try {
      const res = await fetch('/breadboard/system-stats');
      const data = await res.json();
      document.getElementById('cpu').textContent = (data.cpu || 0).toFixed(1) + '%';
      document.getElementById('cpuBar').style.width = Math.min((data.cpu || 0), 100) + '%';
      document.getElementById('memory').textContent = (data.memory || 0).toFixed(1) + '%';
      document.getElementById('memBar').style.width = Math.min((data.memory || 0), 100) + '%';
      document.getElementById('uptime').textContent = formatUptime(data.uptime || 0);
      document.getElementById('processes').textContent = data.processes || '--';
    } catch(e) {
      // Fallback: show animated placeholders
    }
  }
  updateStats();
  setInterval(updateStats, 5000);
</script>
</body>
</html>
"""

private let weatherTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: linear-gradient(135deg, {{backgroundColor}}, {{backgroundColor}}dd);
    border-radius: {{cornerRadius}}px;
    padding: 24px;
    height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  .location {
    font-size: 0.85em;
    opacity: 0.6;
    margin-bottom: 4px;
  }
  .temp {
    font-size: 3.5em;
    font-weight: 200;
    margin-bottom: 4px;
  }
  .condition {
    font-size: 1em;
    opacity: 0.8;
    margin-bottom: 16px;
  }
  .details {
    display: flex;
    gap: 16px;
    font-size: 0.8em;
    opacity: 0.6;
  }
</style>
</head>
<body>
<div class="container">
  <div class="location" id="location">Loading location...</div>
  <div class="temp" id="temp">--°</div>
  <div class="condition" id="condition">Fetching weather...</div>
  <div class="details">
    <span id="humidity">--% humidity</span>
    <span id="wind">-- wind</span>
  </div>
</div>
<script>
  async function updateWeather() {
    try {
      // Uses a free public API (no key needed for basic conditions)
      const res = await fetch('https://wttr.in/?format=j1');
      const data = await res.json();
      const cc = data.current_condition[0];
      document.getElementById('location').textContent = data.nearest_area[0].areaName[0].value + ', ' + data.nearest_area[0].country[0].value;
      document.getElementById('temp').textContent = cc.temp_C + '°';
      document.getElementById('condition').textContent = cc.weatherDesc[0].value;
      document.getElementById('humidity').textContent = cc.humidity + '% humidity';
      document.getElementById('wind').textContent = cc.windspeedKmph + ' km/h wind';
    } catch(e) {
      document.getElementById('condition').textContent = 'Could not fetch weather';
    }
  }
  updateWeather();
  setInterval(updateWeather, 600000); // Every 10 min
</script>
</body>
</html>
"""

private let todoTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }
  h2 {
    font-size: 0.9em;
    font-weight: 600;
    opacity: 0.7;
    margin-bottom: 12px;
  }
  .input-row {
    display: flex;
    gap: 8px;
    margin-bottom: 12px;
  }
  .input-row input {
    flex: 1;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 6px;
    padding: 8px 12px;
    color: {{textColor}};
    font-size: 0.85em;
    outline: none;
  }
  .input-row input::placeholder { color: rgba(255,255,255,0.3); }
  .input-row button {
    background: rgba(255,255,255,0.12);
    border: none;
    border-radius: 6px;
    padding: 8px 14px;
    color: {{textColor}};
    cursor: pointer;
    font-size: 0.85em;
  }
  .input-row button:hover { background: rgba(255,255,255,0.2); }
  .todo-list {
    flex: 1;
    overflow-y: auto;
    list-style: none;
  }
  .todo-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.05);
    font-size: 0.85em;
  }
  .todo-item input[type="checkbox"] {
    appearance: none;
    width: 16px;
    height: 16px;
    border: 1.5px solid rgba(255,255,255,0.2);
    border-radius: 4px;
    cursor: pointer;
    flex-shrink: 0;
  }
  .todo-item input[type="checkbox"]:checked {
    background: #00d2ff;
    border-color: #00d2ff;
  }
  .todo-item.done .todo-text {
    text-decoration: line-through;
    opacity: 0.4;
  }
  .todo-item .delete {
    margin-left: auto;
    cursor: pointer;
    opacity: 0.3;
    font-size: 0.9em;
  }
  .todo-item .delete:hover { opacity: 1; }
  .counter {
    font-size: 0.75em;
    opacity: 0.4;
    margin-top: 8px;
  }
</style>
</head>
<body>
<div class="container">
  <h2>✅ Todo List</h2>
  <div class="input-row">
    <input type="text" id="todoInput" placeholder="Add a task..." />
    <button id="addBtn">Add</button>
  </div>
  <ul class="todo-list" id="todoList"></ul>
  <div class="counter" id="counter">0 items</div>
</div>
<script>
  let todos = JSON.parse(localStorage.getItem('breadboard_todos') || '[]');

  function render() {
    const list = document.getElementById('todoList');
    list.innerHTML = '';
    todos.forEach((todo, i) => {
      const li = document.createElement('li');
      li.className = 'todo-item' + (todo.done ? ' done' : '');
      li.innerHTML = '<input type="checkbox" ' + (todo.done ? 'checked' : '') + ' data-index="' + i + '"/>' +
        '<span class="todo-text">' + todo.text + '</span>' +
        '<span class="delete" data-index="' + i + '">✕</span>';
      li.querySelector('input[type="checkbox"]').addEventListener('change', function() {
        todos[i].done = this.checked;
        save();
      });
      li.querySelector('.delete').addEventListener('click', function() {
        todos.splice(i, 1);
        save();
      });
      list.appendChild(li);
    });
    document.getElementById('counter').textContent = todos.length + ' item' + (todos.length !== 1 ? 's' : '');
  }

  function save() {
    localStorage.setItem('breadboard_todos', JSON.stringify(todos));
    render();
  }

  document.getElementById('addBtn').addEventListener('click', function() {
    const input = document.getElementById('todoInput');
    const text = input.value.trim();
    if (text) {
      todos.push({ text: text, done: false });
      save();
      input.value = '';
    }
  });
  document.getElementById('todoInput').addEventListener('keydown', function(e) {
    if (e.key === 'Enter') document.getElementById('addBtn').click();
  });

  render();
</script>
</body>
</html>
"""

private let dateCalendarTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  .day-name {
    font-size: 1em;
    opacity: 0.6;
    margin-bottom: 4px;
  }
  .day-number {
    font-size: 4em;
    font-weight: 200;
    line-height: 1;
  }
  .month-year {
    font-size: 1.2em;
    opacity: 0.7;
    margin-bottom: 20px;
  }
  .calendar-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 4px;
    text-align: center;
    font-size: 0.75em;
  }
  .calendar-grid .header {
    opacity: 0.4;
    font-weight: 500;
    padding: 4px 0;
  }
  .calendar-grid .day {
    padding: 4px;
    border-radius: 4px;
  }
  .calendar-grid .day.today {
    background: rgba(255,255,255,0.15);
    font-weight: 600;
  }
  .calendar-grid .day.other {
    opacity: 0.2;
  }
</style>
</head>
<body>
<div class="container">
  <div class="day-name" id="dayName">Loading</div>
  <div class="day-number" id="dayNumber">--</div>
  <div class="month-year" id="monthYear">--- ----</div>
  <div class="calendar-grid" id="calendarGrid"></div>
</div>
<script>
  function renderCalendar() {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth();
    const today = now.getDate();

    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    const shortDay = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    document.getElementById('dayName').textContent = dayNames[now.getDay()];
    document.getElementById('dayNumber').textContent = today;
    document.getElementById('monthYear').textContent = monthNames[month] + ' ' + year;

    const firstDay = new Date(year, month, 1).getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const daysInPrev = new Date(year, month, 0).getDate();

    let grid = document.getElementById('calendarGrid');
    grid.innerHTML = '';
    shortDay.forEach(d => {
      const div = document.createElement('div');
      div.className = 'header';
      div.textContent = d;
      grid.appendChild(div);
    });

    // Previous month days
    for (let i = firstDay - 1; i >= 0; i--) {
      const div = document.createElement('div');
      div.className = 'day other';
      div.textContent = daysInPrev - i;
      grid.appendChild(div);
    }

    // Current month days
    for (let d = 1; d <= daysInMonth; d++) {
      const div = document.createElement('div');
      div.className = 'day' + (d === today ? ' today' : '');
      div.textContent = d;
      grid.appendChild(div);
    }

    // Next month days
    const remaining = 42 - (firstDay + daysInMonth);
    for (let d = 1; d <= remaining; d++) {
      const div = document.createElement('div');
      div.className = 'day other';
      div.textContent = d;
      grid.appendChild(div);
    }
  }
  renderCalendar();
</script>
</body>
</html>
"""

private let variablesTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'SF Mono', 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
  }
  h2 {
    font-size: 0.9em;
    font-weight: 600;
    opacity: 0.7;
    margin-bottom: 16px;
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  .var-list {
    list-style: none;
  }
  .var-item {
    display: flex;
    justify-content: space-between;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.06);
    font-size: 0.85em;
  }
  .var-item:last-child { border-bottom: none; }
  .var-name {
    opacity: 0.6;
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
  }
  .var-value {
    font-weight: 500;
  }
  .empty {
    opacity: 0.4;
    font-size: 0.85em;
    text-align: center;
    margin-top: 24px;
  }
</style>
</head>
<body>
<div class="container">
  <h2>📊 Breadboard Variables</h2>
  <ul class="var-list" id="varList">
    <li class="empty">No variables set yet</li>
  </ul>
</div>
<script>
  // Variables are injected via the app bridge / variable substitution
  // This widget displays inline {{variableName}} substitutions.
  // For dynamic updates, we re-render via the refresh interval.
  function renderVars() {
    // Placeholder: actual variable values come from the app bridge
    // The app substitutes {{variableName}} before rendering.
    const list = document.getElementById('varList');
    const items = list.querySelectorAll('.var-item');
    if (items.length === 0) {
      list.innerHTML = '<li class="empty">Subscribe to variables in widget settings</li>';
    }
  }
  renderVars();
</script>
</body>
</html>
"""

private let githubStatsTemplateHTML = """
<!DOCTYPE html>
<html>
<head>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Helvetica Neue', sans-serif;
    background: transparent;
    overflow: hidden;
    color: {{textColor}};
  }
  .container {
    background: {{backgroundColor}};
    border-radius: {{cornerRadius}}px;
    padding: 20px;
    height: 100vh;
  }
  h2 {
    font-size: 0.9em;
    font-weight: 600;
    opacity: 0.7;
    margin-bottom: 16px;
  }
  .stat-row {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 8px 0;
    border-bottom: 1px solid rgba(255,255,255,0.06);
  }
  .stat-row:last-child { border-bottom: none; }
  .stat-icon { opacity: 0.5; }
  .stat-label { flex: 1; opacity: 0.6; font-size: 0.85em; }
  .stat-value { font-weight: 500; font-size: 0.85em; }
  .username-input {
    width: 100%;
    background: rgba(255,255,255,0.08);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 6px;
    padding: 8px 12px;
    color: {{textColor}};
    font-size: 0.85em;
    outline: none;
    margin-bottom: 12px;
  }
  .username-input::placeholder { color: rgba(255,255,255,0.3); }
  .error {
    color: #ff6b6b;
    font-size: 0.8em;
    text-align: center;
    margin-top: 12px;
  }
</style>
</head>
<body>
<div class="container">
  <h2>🐙 GitHub Stats</h2>
  <input class="username-input" id="username" placeholder="Enter GitHub username..." />
  <div id="statsArea">
    <div style="text-align:center; opacity:0.4; font-size:0.85em; margin-top:20px;">Enter a username to see stats</div>
  </div>
</div>
<script>
  document.getElementById('username').addEventListener('change', function() {
    fetchStats(this.value.trim());
  });
  document.getElementById('username').addEventListener('keydown', function(e) {
    if (e.key === 'Enter') fetchStats(this.value.trim());
  });

  async function fetchStats(username) {
    if (!username) return;
    const area = document.getElementById('statsArea');
    area.innerHTML = '<div style="text-align:center; opacity:0.4; font-size:0.85em; margin-top:20px;">Loading...</div>';
    try {
      const res = await fetch('https://api.github.com/users/' + username);
      if (!res.ok) throw new Error('User not found');
      const data = await res.json();
      area.innerHTML = '' +
        '<div class="stat-row"><span class="stat-icon">📦</span><span class="stat-label">Repos</span><span class="stat-value">' + data.public_repos + '</span></div>' +
        '<div class="stat-row"><span class="stat-icon">⭐</span><span class="stat-label">Followers</span><span class="stat-value">' + data.followers + '</span></div>' +
        '<div class="stat-row"><span class="stat-icon">👤</span><span class="stat-label">Following</span><span class="stat-value">' + data.following + '</span></div>' +
        '<div class="stat-row"><span class="stat-icon">📅</span><span class="stat-label">Joined</span><span class="stat-value">' + new Date(data.created_at).toLocaleDateString() + '</span></div>';
    } catch(e) {
      area.innerHTML = '<div class="error">' + e.message + '</div>';
    }
  }
</script>
</body>
</html>
"""
