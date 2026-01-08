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

local customSensors = nil

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
  status.hidePower = 0
  status.hideEfficiency = 0

  -- scaled: 118*0.667=79, 14*0.882=12, 42*0.882=37, 56*0.882=49, 86*0.882=76, 100*0.882=88
  local customSensorXY = {
    { x+79, y+0, x+79, y+12, lcd.RGB(140,140,140)},
    { x+79, y+37, x+79, y+49, lcd.RGB(140,140,140)},
    { x+79, y+76, x+79, y+88, lcd.RGB(140,140,140)},
  }

  if customSensors ~= nil then
    libs.drawLib.drawCustomSensors(customSensors, customSensorXY, lcd.RGB(140, 140, 140))
  else
    customSensors = utils.loadCustomSensors("right")
  end
end

function panel.background(myWidget)
end

return panel
