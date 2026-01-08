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

local lastProcessCycle = getTime()
local processCycle = 0

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

local val1Max = -math.huge
local val1Min = math.huge
local val2Max = -math.huge
local val2Min = math.huge
local initialized = false

local function drawMiniHud(x,y)
  libs.drawLib.drawArtificialHorizon(x, y, 32, 28, nil, lcd.RGB(0x7B, 0x9D, 0xFF), lcd.RGB(0x63, 0x30, 0x00), 4, 5, 1.1)
  lcd.drawBitmap(utils.getBitmap("hud_40x48a"), x-1, y-8)
end

local function setup(widget)
  if not initialized then
    val1Max = -math.huge
    val1Min = math.huge
    val2Max = -math.huge
    val2Min = math.huge
    libs.drawLib.resetGraph("plot1")
    libs.drawLib.resetGraph("plot2")
    initialized = true
  end
end

local function drawTelemetryBar()
  local colorLabel = lcd.RGB(140,140,140)
  -- CELL
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 18-2, string.upper(status.battsource).." V", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  if status.battery[1] * 0.01 < 10 then
    lcd.drawNumber(LCD_W-2, 18+6, status.battery[1] + 0.5, PREC2+SMLSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(LCD_W-2, 18+6, (status.battery[1] + 0.5)*0.1, PREC1+SMLSIZE+CUSTOM_COLOR+RIGHT)
  end
  -- aggregate batt %
  local strperc = string.format("%2d", status.battery[16])
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-4, 53-2, "BATT %", SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-4, 53+6, strperc, SMLSIZE+CUSTOM_COLOR+RIGHT)

  -- speed (140*0.882=123)
  local speed = telemetry.hSpeed * 0.1 * conf.horSpeedMultiplier
  local speedLabel = "GSPD"
  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    speedLabel = "ASPD"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 123-2, string.format("%s %s", speedLabel, conf.horSpeedLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-2, 123+6, string.format("%.01f",speed), SMLSIZE+CUSTOM_COLOR+RIGHT)
  
  -- home distance (180*0.882=159)
  local label = unitLabel
  local dist = telemetry.homeDist
  local flags = 0
  if dist*unitScale > 999 then
    flags = flags + PREC2
    dist = dist*unitLongScale*100
    label = unitLongLabel
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-2, 159-2, string.format("HOME %s", label), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawNumber(LCD_W-2, 159+6, dist, SMLSIZE+flags+CUSTOM_COLOR+RIGHT)


  -- alt (100*0.882=88)
  local alt = telemetry.homeAlt * unitScale
  local altLabel = "ALT"
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    altLabel = "HAT"
  end
  lcd.setColor(CUSTOM_COLOR,colorLabel)
  lcd.drawText(LCD_W-4, 88-2, string.format("%s %s", altLabel, unitLabel), SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W-4, 88+6, string.format("%.0f",alt), SMLSIZE+CUSTOM_COLOR+RIGHT)
  -- home angle (450*0.667=300, 245*0.882=216)
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  libs.drawLib.drawRVehicle(300,216,12,math.floor(telemetry.homeAngle - telemetry.yaw),CUSTOM_COLOR)
end


function layout.draw(widget, customSensors, leftPanel, centerPanel, rightPanel)
  setup(widget)

  drawTelemetryBar(widget)

  -- plot area scaled: 80*0.667=53, 22*0.882=19, 120*0.882=106, 320*0.667=213, 94*0.882=83
  local PLOT_X = 53
  local PLOT1_Y = 19
  local PLOT2_Y = 106
  local PLOT_W = 213
  local PLOT_H = 83

  if conf.plotSource1 <= 1 and conf.plotSource2 <= 1 then
    lcd.setColor(CUSTOM_COLOR, lcd.RGB(80,80,80))
    lcd.drawFilledRectangle(PLOT_X,PLOT1_Y,PLOT_W,PLOT_H,SOLID+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR, lcd.RGB(80,80,80))
    lcd.drawFilledRectangle(PLOT_X,PLOT2_Y,PLOT_W,PLOT_H,SOLID+CUSTOM_COLOR)

    lcd.setColor(CUSTOM_COLOR, WHITE)
    lcd.drawText(PLOT_X+PLOT_W/2,PLOT1_Y+PLOT_H/2-6,"no source 1",SMLSIZE+CUSTOM_COLOR+CENTER)
    lcd.drawText(PLOT_X+PLOT_W/2,PLOT2_Y+PLOT_H/2-6,"no source 2",SMLSIZE+CUSTOM_COLOR+CENTER)
  else
    local y1,y2,val1,val2
    if conf.plotSource1 <= 1 or conf.plotSource2 <= 1 then
      PLOT1_Y = 18
      PLOT2_Y = 18
      PLOT_H = 171
    end
    -- val1
    if conf.plotSource1 > 1 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(80,80,80))
      lcd.drawFilledRectangle(PLOT_X,PLOT1_Y,PLOT_W,PLOT_H,SOLID+CUSTOM_COLOR)
      val1 = telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]]
      val1Min = libs.drawLib.getGraphMin("plot1")
      val1Max = libs.drawLib.getGraphMax("plot1")
      lcd.setColor(CUSTOM_COLOR, WHITE)
      lcd.drawText(PLOT_X+PLOT_W/2,PLOT1_Y-1,status.plotSources[conf.plotSource1][1],SMLSIZE+CUSTOM_COLOR+CENTER)
      lcd.drawText(PLOT_X,PLOT1_Y,string.format("%d", val1Max),SMLSIZE+CUSTOM_COLOR)
      lcd.drawText(PLOT_X,PLOT1_Y+PLOT_H-12,string.format("%d", val1Min),SMLSIZE+CUSTOM_COLOR)
      y1 = libs.drawLib.drawGraph("plot1", PLOT_X, PLOT1_Y+3, PLOT_W, PLOT_H-6, utils.colors.darkyellow, val1, false, false, nil, 20)
      if y1 ~= nil then
        lcd.setColor(CUSTOM_COLOR, WHITE)
        lcd.drawText(PLOT_X+PLOT_W/2,PLOT1_Y+PLOT_H/2-6,string.format("%d", val1),MIDSIZE+CUSTOM_COLOR+CENTER)
      end
    end
    -- val2
    if conf.plotSource2 > 1 then
      lcd.setColor(CUSTOM_COLOR, lcd.RGB(80,80,80))
      lcd.drawFilledRectangle(PLOT_X,PLOT2_Y,PLOT_W,PLOT_H,SOLID+CUSTOM_COLOR)
      val2 = telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]]
      val2Min = libs.drawLib.getGraphMin("plot2")
      val2Max = libs.drawLib.getGraphMax("plot2")
      lcd.setColor(CUSTOM_COLOR, WHITE)
      lcd.drawText(PLOT_X+PLOT_W/2,PLOT2_Y-1,status.plotSources[conf.plotSource2][1],SMLSIZE+CUSTOM_COLOR+CENTER)
      lcd.drawText(PLOT_X,PLOT2_Y,string.format("%d", val2Max),SMLSIZE+CUSTOM_COLOR)
      lcd.drawText(PLOT_X,PLOT2_Y+PLOT_H-12,string.format("%d", val2Min),SMLSIZE+CUSTOM_COLOR)
      y2 = libs.drawLib.drawGraph("plot2", PLOT_X, PLOT2_Y+3, PLOT_W, PLOT_H-6, utils.colors.white, val2, false, false, nil, 20)
      if y2 ~= nil then
        lcd.setColor(CUSTOM_COLOR, WHITE)
        lcd.drawText(PLOT_X+PLOT_W/2,PLOT2_Y+PLOT_H/2-6,string.format("%d", val2),MIDSIZE+CUSTOM_COLOR+CENTER)
      end
    end
  end
  libs.layoutLib.drawTopBar()
  libs.layoutLib.drawStatusBar(2)
  local nextX = libs.drawLib.drawTerrainStatus(4,19)
  libs.drawLib.drawFenceStatus(nextX,19)
end

function layout.background(widget)
  if status.unitConversion ~= nil then
    if conf.plotSource1 > 1 then
      libs.drawLib.updateGraph("plot1", telemetry[status.plotSources[conf.plotSource1][2]] * status.plotSources[conf.plotSource1][4] * status.unitConversion[status.plotSources[conf.plotSource1][3]], 35)
    end
    if conf.plotSource2 > 1 then
      libs.drawLib.updateGraph("plot2", telemetry[status.plotSources[conf.plotSource2][2]] * status.plotSources[conf.plotSource2][4] * status.unitConversion[status.plotSources[conf.plotSource2][3]], 35)
    end
  end
end

return layout

