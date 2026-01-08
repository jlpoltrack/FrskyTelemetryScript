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
-- original panel width: 120px, scaled panel width: 80px
-- last updated: 2026-01-08
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


local panel = {}

local conf
local telemetry
local status
local utils
local libs

function panel.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function panel.draw(widget, x, y, battId)
  local colorLabel = lcd.RGB(140, 140, 140)
  lcd.setColor(CUSTOM_COLOR,colorLabel)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if conf.rangeFinderMax > 0 then
    flags = 0
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      -- 8*0.667=5, 9*0.882=8, 102*0.667=68, 27*0.882=24
      lcd.drawFilledRectangle(x+5, y+8+4,68,24, CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    -- 10*0.667=7
    lcd.drawText(x+7, y+0, string.format("RANGE %s",unitLabel), SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    -- 9*0.882=8
    lcd.drawText(x+7, y+8, string.format("%.1f",rng*0.01*unitScale), MIDSIZE+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,12)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(x+7, y+0, string.format("GALT %s",unitLabel), SMLSIZE+CUSTOM_COLOR)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(x+7, y+8, stralt, MIDSIZE+flags+CUSTOM_COLOR)
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local label = unitLabel
  if dist*unitScale > 999 then
    flags = flags + PREC2
    dist = dist*unitLongScale*100
    label = unitLongLabel
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- 42*0.882=37
  lcd.drawText(x+7, y+37, string.format("HOME %s",label), SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- 51*0.882=45
  lcd.drawNumber(x+7, y+45, dist, MIDSIZE+flags+CUSTOM_COLOR)

  -- total distance
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- 86*0.882=76
  lcd.drawText(x+7, y+76, string.format("TRAVEL %s",unitLongLabel), SMLSIZE+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local mult = telemetry.totalDist*unitLongScale > 99 and 10 or 100
  local prec = telemetry.totalDist*unitLongScale > 99 and PREC1 or PREC2
  -- 95*0.882=84
  lcd.drawNumber(x+7, y+84, telemetry.totalDist*unitLongScale*mult, prec+MIDSIZE+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    -- 4*0.667=3, (9+4)*0.882=11
    libs.drawLib.drawVArrow(x+3, y+11,true,false)
    -- (51+4)*0.882=49
    libs.drawLib.drawVArrow(x+3, y+49,true,false)
  end
end

function panel.background(myWidget)
end

return panel
