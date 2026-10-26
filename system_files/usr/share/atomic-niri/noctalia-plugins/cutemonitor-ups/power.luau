--!nonstrict
-- Bar item: a laptop's power draw in watts beside a plug, from the same sysfs
-- reading the Control Center's Power tab shows through UPower. Hidden on a
-- machine without a system battery, so it can sit in any bar.

local shared = require("./shared.luau")

local KEYS = shared.KEYS

local battery = noctalia.state.get(KEYS.systemBattery)

local function render()
  local present = battery ~= nil and battery.present == true
  barWidget.setVisible(present)
  if not present then
    return
  end

  local children = {
    ui.glyph({ name = "plug" }),
    ui.label({ text = shared.formatWatts(battery.watts) }),
  }
  local container = if barWidget.isVertical()
    then ui.column({ gap = 2, align = "center" }, children)
    else ui.row({ gap = 4, align = "center" }, children)
  barWidget.render(container)

  local rows = {}
  if battery.watts ~= nil then
    table.insert(rows, { key = noctalia.tr("power.draw"), value = string.format("%.1f W", battery.watts) })
  end
  table.insert(rows, { key = noctalia.tr("power.status"), value = battery.status or "Unknown" })
  barWidget.setTooltip(rows)
end

noctalia.state.watch(KEYS.systemBattery, function(value)
  battery = value
  render()
end)

-- The service's updates drive rendering; the bar's own tick only has to keep
-- up with a missed one.
noctalia.setUpdateInterval(60000)

function update()
  render()
end
