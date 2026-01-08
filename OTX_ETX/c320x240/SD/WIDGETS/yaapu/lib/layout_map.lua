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
-- last updated: 2026-01-07
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

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

local function drawMiniHud(x,y)
  -- scaled mini hud: 48*0.667=32, 36*0.882=32
  libs.drawLib.drawArtificialHorizon(x, y, 32, 28, nil, lcd.RGB(0x7B, 0x9D, 0xFF), lcd.RGB(0x63, 0x30, 0x00), 4, 5, 1.1)
  lcd.drawBitmap(utils.getBitmap("hud_40x48a"), x-1, y-8)
end

local flipFlop = true

local function drawTelemetryBar(widget)
  local colorLabel = lcd.RGB(140,140,140)
  -- CELL (LCD_W-2=318)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 18-2, string.upper(status.battsource).." V", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  if status.battery[1] * 0.01 < 10 then
    lcd.drawNumber(LCD_W-2, 18+6, status.battery[1] + 0.5, PREC2+SMLSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(LCD_W-2, 18+6, (status.battery[1] + 0.5)*0.1, PREC1+SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- aggregate batt % (60*0.882=53)
  local strperc = string.format("%2d", status.battery[16])
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-4, 53-2, "BATT %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-4, 53+6, strperc, SMLSIZE+CUSTOM_COLOR+RIGHT)

  -- alt (278*0.667=185, 167*0.882=147, 120*0.667=80, 48*0.882=42)
  local alt = telemetry.homeAlt * unitScale
  local altLabel = "ALT"
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    altLabel = "HAT"
  end
  lcd.drawBitmap(utils.getBitmap("graph_bg_80x27"),185, 147)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(185+78,147-1,altLabel.." "..unitLabel,SMLSIZE+CUSTOM_COLOR+RIGHT)
  local lastY = libs.drawLib.drawGraph("map_alt", 185-3, 147, 80, 40, utils.colors.darkyellow, alt, false, false, nil, nil)
  local altMin = libs.drawLib.getGraphMin("map_alt")
  local altMax = libs.drawLib.getGraphMax("map_alt")
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawText(185,147+8,string.format("%d",alt),SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(190,190,190))
  lcd.drawText(185,147+28,string.format("%d",altMin),SMLSIZE+CUSTOM_COLOR)
  lcd.drawText(185,147-2,string.format("%d",altMax),SMLSIZE+CUSTOM_COLOR)

  -- speed (100*0.882=88)
  local speed = telemetry.hSpeed * 0.1 * conf.horSpeedMultiplier
  local speedLabel = "GSPD"
  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    speedLabel = "ASPD"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 88-2, string.format("%s %s", speedLabel, conf.horSpeedLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-2, 88+6, string.format("%.01f",speed), SMLSIZE+CUSTOM_COLOR+RIGHT)
  -- home distance (140*0.882=123)
  local label = unitLabel
  local dist = telemetry.homeDist
  local flags = 0
  if dist*unitScale > 999 then
    flags = flags + PREC2
    dist = dist*unitLongScale*100
    label = unitLongLabel
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 123-2, string.format("HOME %s", label), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawNumber(LCD_W-2, 123+6, dist, SMLSIZE+flags+CUSTOM_COLOR+RIGHT)

  -- home angle (450*0.667=300, 194*0.882=171)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  libs.drawLib.drawRVehicle(300,171,12,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
end

function layout.draw(widget)
  -- map area scaled: 480*0.667=320, 200*0.882=176
  libs.mapLib.drawMap(widget, 0, 16, 320, 176, status.mapZoomLevel, 3, 2)
  if status.wpEnabledMode == 1 and status.wpEnabled == 1 and telemetry.wpNumber > 0 then
    -- wp number and distance (396*0.667=264)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawBitmap(utils.getBitmap("maps_box_40x11"),264-40,19-1)
    lcd.drawBitmap(utils.getBitmap("maps_box_40x11"),264-40,19+18)

    lcd.drawText(264, 19, string.format("#%d", telemetry.wpNumber),SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(264, 19+17, string.format("%d%s", telemetry.wpDistance * unitScale,unitLabel),SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  drawTelemetryBar(widget)
  drawMiniHud(2, 20)
  libs.layoutLib.drawTopBar()
  libs.layoutLib.drawStatusBar(2)
  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawBitmap(utils.getBitmap("maps_box_40x11"),40,20)
    lcd.drawBitmap(utils.getBitmap("maps_box_40x11"),40+40,20)
    lcd.drawText(40+20, 20, string.format("%.01f %s", telemetry.trueWindSpeed*conf.horSpeedMultiplier*0.1,conf.horSpeedLabel),SMLSIZE+CUSTOM_COLOR)
    libs.drawLib.drawRArrow(40+10,20+8,6,4,45,telemetry.trueWindAngle-180,CUSTOM_COLOR)
  end

  local nextX = libs.drawLib.drawTerrainStatus(3, 53)
  libs.drawLib.drawFenceStatus(nextX, 53)
end

function layout.background(widget)
  libs.drawLib.updateGraph("map_alt", telemetry.homeAlt)
end

return layout

