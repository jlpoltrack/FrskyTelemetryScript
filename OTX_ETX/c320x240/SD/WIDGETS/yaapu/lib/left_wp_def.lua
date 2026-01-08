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
  local flags = 0
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    -- 10*0.667=7, -4*0.882=-4
    lcd.drawText(x+7, y+-4, "RNG "..unitLabel, SMLSIZE+CUSTOM_COLOR)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.setColor(CUSTOM_COLOR,utils.colors.red)
      -- 65*0.667=43, (5+4)*0.882=8, 21*0.882=19
      lcd.drawFilledRectangle(x+7, y+8,43,19,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    -- 5*0.882=4
    lcd.drawText(x+7, y+4, string.format("%.1f",rng*0.01*unitScale), SMLSIZE+flags+CUSTOM_COLOR)
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
    lcd.drawText(x+7, y+-4, "GALT "..unitLabel, SMLSIZE+CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(x+7, y+4, alt*unitScale, SMLSIZE+flags+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- 31*0.882=27
  lcd.drawText(x+7, y+27, "HOME-TRAVEL", SMLSIZE+CUSTOM_COLOR)
  -- 81*0.882=71
  lcd.drawText(x+7, y+71, "WP "..unitLabel, SMLSIZE+CUSTOM_COLOR)
  -- VALUES
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
  local strdist = string.format("%d%s",dist*unitScale,unitLabel)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  -- 40*0.882=35
  if dist < 999 then
    lcd.drawText(x+7, y+35, strdist, SMLSIZE+flags+CUSTOM_COLOR)
  else
    lcd.drawText(x+7, y+35, string.format("%0.2f%s", dist*unitLongScale, unitLongLabel), SMLSIZE+flags+CUSTOM_COLOR)
  end
  -- total distance (62*0.882=55)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawText(x+7, y+55, string.format("%0.2f%s", telemetry.totalDist*unitLongScale, unitLongLabel), SMLSIZE+CUSTOM_COLOR+PREC2)
  -- draw WP info only for supported flight modes
  -- AUTO, GUIDED, LOITER, RTL, QRTL, QLOITER, QLAND, FOLLOW, ZIGZAG
  if status.wpEnabledMode == 1 then
    -- wp number (112*0.882=99)
    lcd.drawText(x+7, y+99, string.format("#%d",telemetry.wpNumber),SMLSIZE+CUSTOM_COLOR)
    -- wp distance (91*0.882=80)
    lcd.drawNumber(x+7, y+80, telemetry.wpDistance * unitScale,SMLSIZE+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing (100*0.667=67)
    libs.drawLib.drawRVehicle(x+67,y+99,9,telemetry.wpOffsetFromCog,CUSTOM_COLOR)
  else
    -- wp number
    lcd.drawText(x+7, y+99, "# ---",SMLSIZE+CUSTOM_COLOR)
    -- wp distance
    lcd.drawText(x+7, y+80, "---",SMLSIZE+CUSTOM_COLOR)
    -- LINES
    lcd.setColor(CUSTOM_COLOR,utils.colors.white) --yellow
    -- wp bearing
    libs.drawLib.drawRVehicle(x+67, y+99, 9, 0, CUSTOM_COLOR)
  end

  if status.showMinMaxValues == true then
    -- 3*0.667=2, (5+4)*0.882=8
    libs.drawLib.drawVArrow(x+2, y+8,true,false)
    -- (40+4)*0.882=39
    libs.drawLib.drawVArrow(x+2, y+39,true,false)
  end
end

function panel.background(myWidget)
  -- WP
  setTelemetryValue(0x050F, 0, 10, telemetry.wpNumber, 0 , 0 , "WPN")
  setTelemetryValue(0x082F, 0, 10, telemetry.wpDistance, 9 , 0 , "WPD")
end

return panel
