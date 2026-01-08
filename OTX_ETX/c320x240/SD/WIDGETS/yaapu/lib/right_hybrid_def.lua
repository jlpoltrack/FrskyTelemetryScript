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

------------------------------------------------------------------------------------
-- On hybrid vehicle we have voltage and current from battery 1, mah from battery 2
------------------------------------------------------------------------------------
function panel.draw(widget, x, y, battId)
  status.hidePower = 1
  status.hideEfficiency = 1

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  --  battery min cell
  local flags = 0
  --
  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  if status.showMinMaxValues == false then
    if status.battLevel2 == false and status.alarms[8][2] > 0 then
      -- 17*0.667=11, 0*0.882=0
      utils.drawBlinkBitmap("cell_red_blink_86x30",x+11,y+0)
      utils.lcdBacklightOn()
    elseif status.battLevel2 == true then
      lcd.drawBitmap(utils.getBitmap("cell_red_86x30"),x+11,y+0)
    elseif status.battLevel1 == false and status.alarms[7][2] > 0 then
      utils.drawBlinkBitmap("cell_orange_blink_86x30",x+11,y+0)
      utils.lcdBacklightOn()
    elseif status.battLevel1 == true then
      lcd.drawBitmap(utils.getBitmap("cell_orange_86x30"),x+11,y+0)
      lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
    end
  end
  flags = CUSTOM_COLOR
  -- (85+2)*0.667=58, -4*0.882=-4
  if status.battery[1+1] * 0.01 < 10 then
    lcd.drawNumber(x+58, y+-4, status.battery[1+1] + 0.5, PREC2+MIDSIZE+RIGHT+flags)
  else
    lcd.drawNumber(x+58, y+-4, (status.battery[1+1] + 0.5)*0.1, PREC1+MIDSIZE+RIGHT+flags)
  end

  -- 86*0.667=57, 12*0.882=11
  local lx = x+57
  lcd.drawText(lx, y+11, "V", SMLSIZE+flags)
  lcd.drawText(lx, y+-2, status.battsource, SMLSIZE+flags)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white) -- white
  -- battery current (85*0.667=57, 134*0.882=118, 86*0.667=57, 149*0.882=131)
  local lowAmp = status.battery[7+1]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+57,y+118,x+57,y+131,status.battery[7+1]*(lowAmp and 1 or 0.1),"A",MIDSIZE+RIGHT+CUSTOM_COLOR+(lowAmp and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- battery mah is from battery 2
  -- we display remaining liters vs used liters as usual (102*0.667=68, 113*0.882=100)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.01f/%.01fL",(status.battery[13+2]-status.battery[10+2])/1000,status.battery[13+2]/1000)
  lcd.drawText(x+68, y+100, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- fuel gauge from battery 2 (20*0.667=13, 34*0.882=30)
  -- note: fuelgauge image would need to be scaled too - using smaller parameters
  lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  libs.drawLib.drawGauge(x+13,y+30,"fuelgauge_50x50", 280, 63, 17, 5, status.battery[16+2], 125, CUSTOM_COLOR)
end

function panel.background(myWidget)
end

return panel
