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
  status.hidePower = 1
  status.hideEfficiency = 1

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local perc = status.battery[16+1]
  local perc2 = status.battery[16+2]
  -- battery 1 cell voltage (no alerts on battery 1)
  local flags = 0
  lcd.setColor(CUSTOM_COLOR,WHITE) -- white
  flags = CUSTOM_COLOR
  -- (100+2)*0.667=68, -4*0.882=-4
  if status.battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+68, y+-4, status.battery[1+1] + 0.5, PREC2+SMLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+68, y+-4, (status.battery[1+1] + 0.5)*0.1, PREC1+SMLSIZE+RIGHT+flags)
  end
  -- 101*0.667=67, 16*0.882=14
  local lx = x+67
  lcd.drawText(lx, y+14, "V", SMLSIZE+flags)
  lcd.drawText(lx, y+-2, status.battsource, SMLSIZE+flags)
  -- battery 2 cell voltage
  flags = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      -- 32*0.667=21, 55*0.882=49
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+21,y+49)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+21,y+49)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+21,y+49)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+21,y+49)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  -- 51*0.882=45
  if status.battery[1+2] * 0.01 < 10 then
    lcd.drawNumber(x+68, y+45, status.battery[1+2] + 0.5, PREC2+SMLSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+68, y+45, (status.battery[1+2] + 0.5)*0.1, PREC1+SMLSIZE+RIGHT+flags)
  end

  lx = x+67
  -- 67*0.882=59
  lcd.drawText(lx, y+59, "V", SMLSIZE+flags)
  lcd.drawText(lx, y+45, status.battsource, SMLSIZE+flags)
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(140, 140, 140))
  lcd.drawText(x, y+-2, "B1", SMLSIZE+flags)
  lcd.drawText(x, y+45, "B2", SMLSIZE+flags)

  -- batt2 capacity bar % (10*0.667=7, 108*0.882=95, 100*0.667=67, 20*0.882=18)
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,255, 255))
  lcd.drawFilledRectangle(x+7, y+95,67,18,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(0, 255, 0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(255,0, 0))
  end
  lcd.drawGauge(x+7, y+95,67,18,perc2,100,CUSTOM_COLOR)
  -- battery 2 percentage (50*0.667=33, 104*0.882=92)
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  local strperc2 = string.format("%02d%%",perc2)
  lcd.drawText(x+33, y+92, strperc2, SMLSIZE+CUSTOM_COLOR)

  -- POWER --
  -- power 1 (95*0.667=63, 24*0.882=21, 97*0.667=65, 31*0.882=27)
  lcd.setColor(CUSTOM_COLOR,WHITE) -- white
  local power1 = status.battery[4+1]*status.battery[7+1]*0.01
  lcd.drawNumber(x+63,y+21,power1,SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+65,y+27,"W",SMLSIZE+CUSTOM_COLOR)
  -- power 2 (82*0.882=72, 89*0.882=79)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local power2 = status.battery[4+2]*status.battery[7+2]*0.01
  lcd.drawNumber(x+63,y+72,power2,SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(x+65,y+79,"W",SMLSIZE+CUSTOM_COLOR)
end

function panel.background(myWidget)
end

return panel
