--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
-- adapted for 320x240 from 480x272 (scale: 0.667x width, 0.882x height)
-- last updated: 2026-01-08
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

local ver, radio, maj, minor, rev = getVersion()

local lastProcessCycle = getTime()
local processCycle = 0

local layout = {}

local conf
local telemetry
local status
local utils
local libs

function layout.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

local initialized = false

local function setup(widget)
  if not initialized then
    initialized = true
  end
end

local function drawRightBar(widget)
  -- scaled Y positions: 20*0.882=18, 60*0.882=53, 100*0.882=88, 140*0.882=123
  local yCell = 18
  local yPERC = 53
  local yALT = 88
  local ySPD = 123

  -- 60*0.882=53, 194*0.882=171
  local yDIST = 53
  local yHOME = 171

  local colorLabel = lcd.RGB(140,140,140)
  -- CELL
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- -3*0.882=-3
  lcd.drawText(LCD_W-2, yCell-3, string.upper(status.battsource).." V", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  -- 7*0.882=6
  if status.battery[1] * 0.01 < 10 then
    lcd.drawNumber(LCD_W-2, yCell+6, status.battery[1] + 0.5, PREC2+TXT_ALIGN+SMLSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(LCD_W-2, yCell+6, (status.battery[1] + 0.5)*0.1, PREC1+TXT_ALIGN+SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- aggregate batt %
  local strperc = string.format("%2d", status.battery[16])
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-4, yPERC-3, "BATT %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-4, yPERC+6, strperc, SMLSIZE+CUSTOM_COLOR+RIGHT)

  -- alt
  local alt = telemetry.homeAlt * unitScale
  local altLabel = "ALT"
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    altLabel = "HAT"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, yALT-3, string.format("%s %s", altLabel, unitLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-2, yALT+6, string.format("%.0f",alt), SMLSIZE+CUSTOM_COLOR+RIGHT)

  -- speed
  local speed = telemetry.hSpeed * 0.1 * conf.horSpeedMultiplier
  local speedLabel = "GSPD"
  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    speedLabel = "ASPD"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, ySPD-3, string.format("%s %s", speedLabel, conf.horSpeedLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-2, ySPD+6, string.format("%.01f",speed), SMLSIZE+CUSTOM_COLOR+RIGHT)

  -- home distance (6*0.667=4)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(4, yDIST-3, string.format("HOME %s", unitLabel), SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(4, yDIST+6, string.format("%.0f",telemetry.homeDist*unitScale), SMLSIZE+CUSTOM_COLOR)

  -- home angle (440*0.667=293, 18*0.667=12)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  libs.drawLib.drawRVehicle(293,yHOME,12,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
end

function layout.draw(widget, customSensors, leftPanel, centerPanel, rightPanel)
  setup(widget)
  drawRightBar(widget)

  libs.layoutLib.drawTopBar()
  libs.layoutLib.drawStatusBar(2)
  -- 6*0.667=4, 22*0.882=19
  local nextX = libs.drawLib.drawTerrainStatus(4,19)
  libs.drawLib.drawFenceStatus(nextX,19)
end

function layout.background(widget)
end

return layout
