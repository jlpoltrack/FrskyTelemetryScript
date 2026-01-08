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
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140, 140, 140))
  -- 1*0.667=1, -2*0.882=-2, 63*0.882=56
  lcd.drawText(x+1,y+-2,"B1",0+CUSTOM_COLOR+SMLSIZE)
  lcd.drawText(x+1,y+56,"B2",0+CUSTOM_COLOR+SMLSIZE)

  local perc1 = status.battery[16+1]
  local perc2 = status.battery[16+2]
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- battery 1 current (100*0.667=67, -4*0.882=-4, 6*0.882=5)
  local flagUseDecimals = status.battery[7+1]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+67,y+-4,x+67,y+5,status.battery[7+1]*(flagUseDecimals and 1 or 0.1),"A",SMLSIZE+RIGHT+CUSTOM_COLOR+(flagUseDecimals and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- battery 2 current (65*0.882=57)
  flagUseDecimals = status.battery[7+2]*0.1 < 10
  libs.drawLib.drawNumberWithDim(x+67,y+-4+57,x+67,y+5+57,status.battery[7+2]*(flagUseDecimals and 1 or 0.1),"A",SMLSIZE+RIGHT+CUSTOM_COLOR+(flagUseDecimals and PREC1 or 0),SMLSIZE+CUSTOM_COLOR)
  -- battery 1 capacity bar % (10*0.667=7, 25*0.882=22, 100*0.667=67, 18*0.882=16)
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawFilledRectangle(x+7, y+22,67,16,CUSTOM_COLOR)
  if perc1 > 50 then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,255,0))
  elseif perc1 <= 50 and perc1 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR, utils.colors.red)
  end
  lcd.drawGauge(x+7, y+22,67,16,perc1,100,CUSTOM_COLOR)
  -- battery 2 capacity bar %
  lcd.setColor(CUSTOM_COLOR, WHITE)
  lcd.drawFilledRectangle(x+7, y+22+57,67,16,CUSTOM_COLOR)
  if perc2 > 50 then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(0,255,0))
  elseif perc2 <= 50 and perc2 > 25 then
      lcd.setColor(CUSTOM_COLOR,lcd.RGB(255, 204, 0)) -- yellow
  else
    lcd.setColor(CUSTOM_COLOR, RED)
  end
  lcd.drawGauge(x+7, y+22+57,67,16,perc2,100,CUSTOM_COLOR)
  -- battery 1 percentage (52*0.667=35, 24*0.882=21)
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  local strperc = string.format("%02d%%",perc1)
  lcd.drawText(x+35, y+21, strperc, SMLSIZE+CUSTOM_COLOR)
  -- battery 2 percentage
  lcd.setColor(CUSTOM_COLOR,utils.colors.black) -- black
  strperc = string.format("%02d%%",perc2)
  lcd.drawText(x+35, y+21+57, strperc, SMLSIZE+CUSTOM_COLOR)
  -- battery 1 mah (110*0.667=73, 44*0.882=39)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local strmah = string.format("%.02f/%.01fAh",status.battery[10+1]/1000,status.battery[13+1]/1000)
  lcd.drawText(x+73, y+39, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- battery 2 mah
  strmah = string.format("%.02f/%.01fAh",status.battery[10+2]/1000,status.battery[13+2]/1000)
  lcd.drawText(x+73, y+39+57, strmah, SMLSIZE+RIGHT+CUSTOM_COLOR)

  -- GPS Altitude uses either RPM1 panel or overrides Efficiency panel
  -- 92*0.667=61
  local gpsAltX = x+61
  if conf.enableRPM == 2  or conf.enableRPM == 3 then
    status.hideEfficiency = 1
    -- 395*0.667=263
    gpsAltX = x+263
  end
  -- use power panel if RPM2 is enabled (192*0.667=128)
  local homeDistX = x+128
  if conf.enableRPM == 3 then
    status.hidePower = 1
    -- 478*0.667=319
    homeDistX = x+319
  end
  -- home distance (130*0.882=115)
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(140,140,140))
  lcd.drawText(homeDistX, y+115, "HOME("..unitLabel..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*unitScale)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- 145*0.882=128
  lcd.drawText(homeDistX, y+128, strdist, SMLSIZE+flags+RIGHT+CUSTOM_COLOR)
  -- GPS Altitude and rangefinder
  if conf.rangeFinderMax > 0 then
    flags = 0
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,16)
    lcd.setColor(CUSTOM_COLOR,utils.colors.lightgrey)
    lcd.drawText(gpsAltX, y+115, "RNG("..unitLabel..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      -- 65*0.667=43, (145+4)*0.882=131, 21*0.882=19
      lcd.drawFilledRectangle(gpsAltX-43, y+131,43,19,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(gpsAltX, y+128, string.format("%.1f",rng*0.01*unitScale), SMLSIZE+RIGHT+CUSTOM_COLOR)
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
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(140,140,140))
    lcd.drawText(gpsAltX, y+115, "GALT("..unitLabel..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local stralt = string.format("%d",alt*unitScale)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(gpsAltX, y+128, stralt, SMLSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
end

function panel.background(myWidget)
end

return panel
