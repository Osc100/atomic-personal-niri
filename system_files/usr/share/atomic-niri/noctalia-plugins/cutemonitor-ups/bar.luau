--!nonstrict
-- Bar item: the power-source icon (or a drawn battery) with an optional label,
-- a summary tooltip, and the detail panel on left click. In the normal state
-- it sets no colors, so the icon and text follow the bar like every other
-- item; only outage and alert states add color.

local shared = require("./shared.luau")

local KEYS = shared.KEYS
local PANEL = "osc/cutemonitor-ups:details"
local TOOLTIP_ROWS = { "state", "supply", "battery", "runtime", "load", "utility_voltage" }

local displayMode = noctalia.getConfig("display_mode") or "icon"
local batteryColor = noctalia.getConfig("battery_color") or "on_surface"
local showLabel = noctalia.getConfig("show_label") ~= false
local labelContent = noctalia.getConfig("label_content") or "battery_load"
local labelStyle = noctalia.getConfig("label_style") or "text"
local iconColorSetting = noctalia.getConfig("icon_color") or ""
local iconKind = noctalia.getConfig("icon") or "power"
local onlyOnBattery = noctalia.getConfig("only_on_battery") == true
local hideWithSystemBattery = noctalia.getConfig("hide_with_system_battery") ~= false
local colors = {
  warning = noctalia.getConfig("warning_color") or "tertiary",
  alert = noctalia.getConfig("alert_color") or "error",
}
local highLoad = tonumber(noctalia.getConfig("high_load")) or 80

-- Label content -> the stats it shows, in order
local CONTENT = {
  battery_load = { "battery_pct", "load_pct" },
  battery = { "battery_pct" },
  load = { "load_pct" },
  load_w = { "load_w" },
  runtime = { "runtime" },
}

local snap = noctalia.state.get(KEYS.snapshot)
local link = noctalia.state.get(KEYS.link)
local systemBattery = noctalia.state.get(KEYS.systemBattery)

-- "" from the shared color rules means "the bar's own color": pass nil so the
-- host default applies.
local function tint(color: string): string?
  return if color == "" then nil else color
end

-- Battery outline filled to the charge level, with the terminal cap on the right.
-- `color` is the Warning/Alert color during those states, else nil.
local function drawnBattery(pct: number?, color: string?)
  local ink = color or batteryColor
  local filled = math.floor(math.clamp((pct or 0) / 100, 0, 1) * 18 + 0.5)
  local level = {}
  if filled > 0 then
    table.insert(level, ui.box({ width = filled, height = 7, radius = 1.5, fill = ink }))
  end
  return ui.row({ gap = 1, align = "center" }, {
    ui.row({ width = 24, height = 12, padding = 2.5, radius = 3, border = ink, borderWidth = 1.3, align = "center" }, level),
    ui.box({ width = 2, height = 5, radius = 1, fill = ink }),
  })
end

-- The built-in sysmon widget's gauge (src/shell/bar/widgets/sysmon_widget.cpp),
-- so a stat shown as a meter sits beside the system group's own: thickness
-- max(3, round(fontSizeBody 14 x 0.3)), length round(14 x 0.85) beside a glyph,
-- fully rounded, filled from the bottom (from the left on a vertical bar) over
-- a track of the fill at 30% alpha, and empty below a pixel of fill. ui.progress
-- has no vertical orientation, hence the track holding a fill box.
local METER_THICKNESS = 4
local METER_LENGTH = 12

local function meter(pct: number?, color: string, vertical: boolean)
  local share = math.clamp((pct or 0) / 100, 0, 1)
  local filled = share * METER_LENGTH
  if filled < 1 then
    filled = 0
  end
  local level = {}
  if filled > 0 then
    table.insert(level, if vertical
      then ui.box({ width = filled, height = METER_THICKNESS, radius = METER_THICKNESS / 2, fill = color })
      else ui.box({ width = METER_THICKNESS, height = filled, radius = METER_THICKNESS / 2, fill = color }))
  end
  local track = {
    width = if vertical then METER_LENGTH else METER_THICKNESS,
    height = if vertical then METER_THICKNESS else METER_LENGTH,
    radius = METER_THICKNESS / 2,
    fill = `{color}/0.3`,
    justify = if vertical then "start" else "end",
  }
  return if vertical then ui.row(track, level) else ui.column(track, level)
end

-- Stats a meter can show: shares of a whole. The rest stay text in meter style.
local METERED = { battery_pct = "batteryPct", load_pct = "loadPct" }

local function setTooltip(level: string)
  if level == "none" then
    local starting = link == nil or link.state == "starting"
    local title = noctalia.tr(if starting then "status.starting" else "status.none")
    local reason = if link and link.message and link.message ~= "" then link.message else nil
    barWidget.setTooltip(if reason then `{title}\n{reason}` else title)
    return
  end
  local now = os.time()
  local ctx = { style = "short", now = now }
  local rows = {}
  for _, key in TOOLTIP_ROWS do
    local value = if key == "state" and level == "lost"
      then shared.lostText(link, now)
      else shared.rowValue(key, snap, ctx)
    if value ~= nil then
      table.insert(rows, { key = noctalia.tr("rows." .. key), value = value })
    end
  end
  barWidget.setTooltip(rows)
end

local tickMs = 0

local function render()
  local level = shared.level(snap, link)

  -- Tick every second while the data is stale so its age counts up; otherwise
  -- the service's updates drive rendering. This goes before the visibility
  -- check because the bar's default tick is 250 ms.
  local wanted = if level == "lost" then 1000 else 60000
  if wanted ~= tickMs then
    tickMs = wanted
    noctalia.setUpdateInterval(wanted)
  end

  -- A laptop shows its own battery instead (the power item and Noctalia's).
  local laptop = hideWithSystemBattery and systemBattery ~= nil and systemBattery.present == true
  local visible = not laptop and (not onlyOnBattery or (snap ~= nil and snap.onBattery == true))
  barWidget.setVisible(visible)
  if not visible then
    return
  end

  local vertical = barWidget.isVertical()
  local iconColor = tint(shared.levelColor(level, "", colors))
  local children = {}
  if displayMode == "battery" and snap ~= nil then
    table.insert(children, drawnBattery(snap.batteryPct, iconColor))
  elseif displayMode ~= "none" or not showLabel or snap == nil then
    -- The battery glyph follows the charge; with no UPS or no contact the power
    -- glyph says so either way.
    local glyph = if iconKind == "battery" and level ~= "none" and level ~= "lost"
      then shared.batteryIcon(snap.batteryPct)
      else shared.powerIcon(snap, level)
    table.insert(children, ui.glyph({ name = glyph, color = iconColor or tint(iconColorSetting) }))
  end

  if showLabel and snap ~= nil then
    local stats = table.clone(CONTENT[labelContent] or CONTENT.battery_load)
    if snap.onBattery and labelContent ~= "runtime" then
      table.insert(stats, "runtime")
    end
    if vertical then
      stats = { stats[1] }
    end
    for i, statKey in stats do
      local color = tint(shared.statColor(statKey, snap, "", colors, highLoad))
      local field = METERED[statKey]
      if labelStyle == "meter" and field ~= nil then
        table.insert(children, meter(snap[field], color or "on_surface", vertical))
      else
        if i > 1 then
          table.insert(children, ui.label({ text = "·" }))
        end
        table.insert(children, ui.label({ text = shared.formatStat(statKey, snap), color = color }))
      end
    end
  end

  local opacity = if level == "lost" then 0.5 else 1
  local container = if vertical
    then ui.column({ gap = 2, align = "center", opacity = opacity }, children)
    else ui.row({ gap = 4, align = "center", opacity = opacity }, children)
  barWidget.render(container)
  setTooltip(level)
end

-- The link always arrives right after the snapshot, so it does the rendering.
noctalia.state.watch(KEYS.snapshot, function(value)
  snap = value
end)
noctalia.state.watch(KEYS.link, function(value)
  link = value
  render()
end)
noctalia.state.watch(KEYS.systemBattery, function(value)
  systemBattery = value
  render()
end)

-- Left click is bound to the panel in plugin.toml; this covers a removed binding.
function onClick()
  noctalia.togglePanel(PANEL)
end

function update()
  render()
end
