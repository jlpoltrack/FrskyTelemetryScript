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
  -- panel width: 80px (scaled from 120px)
  -- scale factor for internal offsets: 0.667
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = status.battery[16+battId]
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      -- 31*0.667=21, 14*0.882=12
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+21,y+12)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+21,y+12)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+21,y+12)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+21,y+12)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  -- 106*0.667=71, 10*0.882=9
  if status.battery[1+battId] * 0.01 < 10 then
    libs.drawLib.drawNumberWithDim(x+71, y+9, x+71, y+14, status.battery[1+battId] + 0.5, "V", PREC2+MIDSIZE+RIGHT+flags, SMLSIZE+flags)
  else
    libs.drawLib.drawNumberWithDim(x+71, y+9, x+71, y+14, (status.battery[1+battId] + 0.5)*0.1, "V", PREC1+MIDSIZE+RIGHT+flags, SMLSIZE+flags)
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  
  -- battery voltage and current with better spacing
  local voltage = status.battery[4+battId] * 0.1
  local current = status.battery[7+battId] * 0.1
  lcd.drawText(x+38, y+50, string.format("%.1fV", voltage), SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+76, y+50, string.format("%.1fA", current), SMLSIZE+RIGHT+CUSTOM_COLOR)
  
  -- display capacity bar % (x+5, y+70, width 70, height 19)
  local color = lcd.RGB(255,0, 0)
  if perc > 50 then
    color = lcd.RGB(0, 255, 0)
  elseif perc <= 50 and perc > 25 then
    color = lcd.RGB(255, 204, 0) -- yellow
  end
  libs.drawLib.drawMinMaxBar(x+5, y+70,70,19,color,perc,0,100,0)
  -- battery mah
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10+battId]/1000,status.battery[13+battId]/1000)
  lcd.drawText(x+76, y+90, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140, 140, 140))
  local battLabel = "B1B2"
  if battId == 0 then
    if conf.battConf ==  3 then
      -- alarms are based on battery 1
      battLabel = "B1"
    elseif conf.battConf ==  4 then
      -- alarms are based on battery 2
      battLabel = "B2"
    end
  else
    battLabel = (battId == 1 and "B1" or "B2")
  end

  -- labels
  lcd.drawText(x+1, y+-2, battLabel, SMLSIZE+CUSTOM_COLOR)

  if status.showMinMaxValues == true then
    -- cell voltage min/max arrow
    libs.drawLib.drawVArrow(x+78, y+16,false,true)
  end
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(140, 140, 140))
  lcd.drawText(x+73, y+-2, string.format("%s CELL",string.upper(status.battsource)), SMLSIZE+RIGHT+CUSTOM_COLOR)
end

function panel.background(myWidget)
end

return panel
