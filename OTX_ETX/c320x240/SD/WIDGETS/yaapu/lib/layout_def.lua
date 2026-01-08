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

-- scaled from 480x272: X * 0.667, Y * 0.882
-- scaled from 480x272: X * 0.667, Y * 0.882
local customSensorXY = {
  { 27, 170, 27, 179},
  { 80, 170, 80, 179},
  { 133, 170, 133, 179},
  { 187, 170, 187, 179},
  { 240, 170, 240, 179},
  { 293, 170, 293, 179},
  boxY = 170
}

function layout.draw(widget, customSensors, leftPanel, centerPanel, rightPanel)
  local colorLabel = lcd.RGB(140, 140, 140)
  -- reset visibility, panels can override this
  status.hidePower = 0
  status.hideEfficiency = 0
  -- center panel
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  centerPanel[status.currentScreen].draw(widget)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  -- home directory arrow (240*0.667=160, 173*0.882=153)
  libs.drawLib.drawRVehicle(160,153,15,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
  local battIdForPower = 1
  -- with dual battery default is to show aggregate view
  if status.batt2sources.fc or status.batt2sources.vs then
    if status.showDualBattery == false then
      -- dual battery: aggregate view (360*0.667=240, 18*0.882=16)
      rightPanel[status.currentScreen].draw(widget, 240, 16, 0)
      -- left pane info
      leftPanel[status.currentScreen].draw(widget, 0, 16, 0)
      battIdForPower = 0
    else
      -- dual battery:battery 1 right pane
      rightPanel[status.currentScreen].draw(widget, 240, 16, 1)
      -- dual battery:battery 2 left pane
      rightPanel[status.currentScreen].draw(widget, 240, 16, 2)
    end
  else
    -- battery 1 right pane in single battery mode
    rightPanel[status.currentScreen].draw(widget, 240, 16, 1)
    -- left pane info  in single battery mode
    leftPanel[status.currentScreen].draw(widget, 0, 16, 0)
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  -- RPM 1 (10*0.667=7, 150*0.882=132)
  if conf.enableRPM == 2  or conf.enableRPM == 3 then
    lcd.drawText(7, 132, "RPM 1", SMLSIZE+CUSTOM_COLOR)
    libs.drawLib.drawBar("rpm1", 7, 132+13, 60, 20, utils.colors.darkyellow, math.abs(telemetry.rpm1), SMLSIZE)
  end
  -- RPM 2 (115*0.667=77)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  if conf.enableRPM == 3 then
    lcd.drawText(77, 132, "RPM 2", SMLSIZE+CUSTOM_COLOR+0)
    libs.drawLib.drawBar("rpm2", 77, 132+13, 60, 20, utils.colors.darkyellow, math.abs(telemetry.rpm2), SMLSIZE)
  end
  -- throttle % (315*0.667=210, 150*0.882=132, 165*0.882=146)
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(210, 132, "THR %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  lcd.drawNumber(210,146,telemetry.throttle,SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- efficiency (check if hidden by another panel) (395*0.667=263)
  if status.hideEfficiency == 0 then
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    lcd.drawText(263, 132, "EFF mAh", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local speed = utils.getMaxValue(telemetry.hSpeed,14)
    -- efficiency for indipendent batteries makes sense only for battery 1
    local eff = speed > 2 and status.battery[7+battIdForPower]*1000/(speed*conf.horSpeedMultiplier) or 0
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(263,146+(eff > 9999 and 5 or 0),eff,(eff > 9999 and 0 or SMLSIZE)+RIGHT+CUSTOM_COLOR)
  end
  -- power (check if hidden by another panel) (478*0.667=319)
  if status.hidePower == 0 then
    lcd.setColor(CUSTOM_COLOR,colorLabel)
    local power = status.battery[4+battIdForPower]*status.battery[7+battIdForPower]*0.01
    local powerUnit = (power > 999) and "kW" or "W"
    local flags = (power > 999) and PREC2 or 0
    lcd.drawText(319, 132, string.format("PWR %s",powerUnit), SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawNumber(319,146,power*(power > 999 and 0.1 or 1),SMLSIZE+RIGHT+CUSTOM_COLOR+flags)
  end
  libs.layoutLib.drawTopBar()
  local msgRows = 3
  if customSensors ~= nil then
    msgRows = 1
    -- draw custom sensors
    libs.drawLib.drawCustomSensors(customSensors, customSensorXY, utils.colors.lightgrey)
  end
  libs.layoutLib.drawStatusBar(msgRows)
  local nextX = libs.drawLib.drawTerrainStatus(82, 18)
  libs.drawLib.drawFenceStatus(nextX,18)
  lcd.setColor(CUSTOM_COLOR,WHITE)
end

return layout

