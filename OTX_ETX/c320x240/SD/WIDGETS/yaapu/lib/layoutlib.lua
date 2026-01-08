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

local layoutLib = {}

local status
local telemetry
local conf
local utils
local libs

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

function layoutLib.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function layoutLib.drawTopBar()
  lcd.setColor(CUSTOM_COLOR, utils.colors.bars)
  -- black bar (height 16)
  lcd.drawFilledRectangle(0,0, LCD_W, 16, CUSTOM_COLOR)
  -- frametype and model name (left side)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.modelString ~= nil then
    local modelString = status.currentScreen == 1 and status.modelString or string.format("[%d] %s",status.currentScreen, status.modelString)
    lcd.drawText(2, 0, modelString, SMLSIZE+CUSTOM_COLOR)
  end
  -- time (right-aligned at screen edge)
  local time = getDateTime()
  local strtime = string.format("%02d:%02d:%02d",time.hour,time.min,time.sec)
  lcd.drawText(LCD_W, 0, strtime, SMLSIZE+RIGHT+CUSTOM_COLOR)
  -- RSSI/RTP info drawn via utils.drawRssi()
  if utils.telemetryEnabled() == false then
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawText(LCD_W/2, 0, "NO TELEM", SMLSIZE+CUSTOM_COLOR+CENTER)
  else
    utils.drawRssi()
  end
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
end

function layoutLib.drawNoTelemetryData(telemetryEnabled)
  -- no telemetry data
  if (not utils.telemetryEnabled()) then
    lcd.setColor(CUSTOM_COLOR,WHITE)
    -- scaled: 88*0.667=59, 74*0.882=65, 304*0.667=203, 84*0.882=74
    lcd.drawFilledRectangle(59,65, 203, 74, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
    lcd.drawFilledRectangle(61,67, 199, 70, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(160, 75, "no telemetry data", MIDSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(160, 105, "Yaapu Telemetry Widget 2.1.x dev".." (".. '7a17b47'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
    libs.layoutLib.drawTopBar()
    local info = model.getInfo()
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(0,0,info.name,SMLSIZE+CUSTOM_COLOR)
  end
end

function layoutLib.drawWidgetPaused()
  if conf.pauseTelemetry == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawFilledRectangle(59,65, 203, 74, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
    lcd.drawFilledRectangle(61,67, 199, 70, CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,BLACK)
    lcd.drawText(160, 75, "WIDGET PAUSED", MIDSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(160, 105, "Yaapu Telemetry Widget 2.1.x dev".." (".. '7a17b47'..")", SMLSIZE+CUSTOM_COLOR+CENTER)
  end
end

function layoutLib.drawStatusBar(maxRows)
  local yDelta = (maxRows-1)*10

  lcd.setColor(CUSTOM_COLOR,utils.colors.bars)
  -- 229*0.882=202, 480->320
  lcd.drawFilledRectangle(0,202-yDelta,320,LCD_H-(202-yDelta),CUSTOM_COLOR)
  -- flight time
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- 224*0.882=198
  lcd.drawTimer(LCD_W, 198-yDelta, model.getTimer(2).value, MIDSIZE+CUSTOM_COLOR+RIGHT)
  -- flight mode
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  if status.strFlightMode ~= nil then
    lcd.drawText(1,203-yDelta,status.strFlightMode,SMLSIZE+CUSTOM_COLOR)
  end
  -- gps status, draw coordinates if good at least once (375*0.667=250)
  if telemetry.lon ~= nil and telemetry.lat ~= nil then
    lcd.drawText(250, 200-yDelta, telemetry.strLat, SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.drawText(250, 212-yDelta, telemetry.strLon, SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- gps status
  local hdop = telemetry.gpsHdopC
  local strStatus = utils.gpsStatuses[telemetry.gpsStatus]
  local flags = BLINK
  local mult = 1

  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if hdop > 999 then
      hdop = 999
      flags = 0
      mult=0.1
    elseif hdop > 99 then
      flags = 0
      mult=0.1
    end
    -- 244*0.667=163, 226*0.882=199
    lcd.drawNumber(163,199-yDelta, hdop*mult,MIDSIZE+flags+CUSTOM_COLOR)
    -- SATS (206*0.667=137)
    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    lcd.drawText(137,203-yDelta, utils.gpsStatuses[telemetry.gpsStatus][1], SMLSIZE+CUSTOM_COLOR)
    lcd.drawText(137,212-yDelta, utils.gpsStatuses[telemetry.gpsStatus][2], SMLSIZE+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR,utils.colors.white)
    -- 198*0.667=132
    if telemetry.numSats == 15 then
      lcd.drawNumber(132,199-yDelta, telemetry.numSats, MIDSIZE+CUSTOM_COLOR+RIGHT)
      lcd.drawText(132,206-yDelta, "+", SMLSIZE+CUSTOM_COLOR)
    else
      lcd.drawNumber(132,199-yDelta,telemetry.numSats, MIDSIZE+CUSTOM_COLOR+RIGHT)
    end
  elseif telemetry.gpsStatus == 0 then
    -- 150*0.667=100
    utils.drawBlinkBitmap("nogpsicon",100,200-yDelta)
  else
    utils.drawBlinkBitmap("nolockicon",100,200-yDelta)
  end

  local offset = math.min(maxRows,#status.messages+1)
  for i=0,offset-1 do
    lcd.setColor(CUSTOM_COLOR,utils.mavSeverity[status.messages[(status.messageCount + i - offset) % (#status.messages+1)][2]][2])
    -- 256*0.882=226, row height 10 instead of 12
    lcd.drawText(1,(226-yDelta)+(10*i), status.messages[(status.messageCount + i - offset) % (#status.messages+1)][1],SMLSIZE+CUSTOM_COLOR)
  end
end

return layoutLib

