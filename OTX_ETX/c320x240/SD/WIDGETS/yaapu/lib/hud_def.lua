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

function panel.draw(widget)
  -- scaled from 480x272: HUD area
  -- original: minY=18, maxY=148, minX=120, maxX=360
  -- scaled: minY=16, maxY=131, minX=80, maxX=240
  local minY = 16  --HUD_Y
  local maxY = 131 --HUD_Y + HUD_HEIGHT
  local minX = 80  --HUD_X
  local maxX = 240 --HUD_X + HUD_WIDTH

  -- hud dimensions: 240x130 -> 160x115
  libs.drawLib.drawArtificialHorizon(minX, minY, 160, 115, "hud_bg", nil, utils.colors.hudTerrain, 4, 16, 1.6)

  -- hashmarks
  local startY = minY + 1
  local endY = maxY - 9
  local step = 16
  -- hSpeed
  local roundHSpeed = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1/5)+0.5)*5;
  local offset = math.floor((telemetry.hSpeed*conf.horSpeedMultiplier*0.1-roundHSpeed)*0.2*step);
  local ii = 0;
  local yy = 0
  lcd.setColor(CUSTOM_COLOR,utils.colors.hudDash)
  for j=roundHSpeed+20,roundHSpeed-20,-5
  do
      yy = startY + (ii*step) + offset - 12
      if yy >= startY and yy < endY then
        -- 182*0.667=121
        lcd.drawNumber(121,  yy, j, SMLSIZE+CUSTOM_COLOR+RIGHT)
      end
      ii=ii+1;
  end
  -- altitude
  local roundAlt = math.floor((telemetry.homeAlt*unitScale/5)+0.5)*5;
  offset = math.floor((telemetry.homeAlt*unitScale-roundAlt)*0.2*step);
  ii = 0;
  yy = 0
  for j=roundAlt+20,roundAlt-20,-5
  do
      yy = startY + (ii*step) + offset - 12
      if yy >= startY and yy < endY then
        -- 298*0.667=199
        lcd.drawNumber(199,  yy, j, SMLSIZE+CUSTOM_COLOR)
      end
      ii=ii+1;
  end
  lcd.setColor(CUSTOM_COLOR,WHITE)

  -------------------------------------
  -- hud bitmap (120*0.667=80)
  -------------------------------------
  lcd.drawBitmap(utils.getBitmap("hud"),80,16)

  -------------------------------------
  -- vario
  -------------------------------------
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*telemetry.vSpeed),5)
  local varioH = varioSpeed/varioMax*44
  if telemetry.vSpeed > 0 then
    -- 18*0.882=16, 50*0.882=44
    varioY = 16 + (44 - varioH)
    lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  else
    -- 97*0.882=86
    varioY = 86
    lcd.setColor(CUSTOM_COLOR,utils.colors.red)
  end
  -- 349*0.667=233, width 11*0.667=7
  lcd.drawFilledRectangle(233, varioY, 7, varioH, CUSTOM_COLOR)

  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- DATA
  -- altitude
  local homeAlt = utils.getMaxValue(telemetry.homeAlt,11) * unitScale
  local alt = homeAlt
  if status.terrainEnabled == 1 then
    alt = telemetry.heightAboveTerrain * unitScale
    lcd.setColor(CUSTOM_COLOR,BLACK)
    -- 294*0.667=196, 98*0.882=86, 55*0.667=37, 19*0.882=17
    lcd.drawRectangle(196, 86, 37, 17, CUSTOM_COLOR)
    lcd.drawFilledRectangle(196, 86, 37, 17, CUSTOM_COLOR+SOLID)
  end
  lcd.setColor(CUSTOM_COLOR, utils.colors.green)

  -- adjusted y to 48 to move up within black box, x to 202 to move right
  if math.abs(alt) > 999 or alt < -99 then
    lcd.drawNumber(202,48,alt,SMLSIZE+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(202,75,homeAlt,SMLSIZE+CUSTOM_COLOR+LEFT)
    end
  elseif math.abs(alt) >= 10 then
    lcd.setColor(CUSTOM_COLOR, utils.colors.green)
    lcd.drawNumber(202,48,alt,MIDSIZE+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(202,75,homeAlt,SMLSIZE+CUSTOM_COLOR+LEFT)
    end
  else
    lcd.setColor(CUSTOM_COLOR, utils.colors.green)
    lcd.drawNumber(202,48,alt*10,MIDSIZE+PREC1+CUSTOM_COLOR+LEFT)
    if status.terrainEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(202,75,homeAlt*10,PREC1+SMLSIZE+CUSTOM_COLOR+LEFT)
    end
  end

  -- telemetry.hSpeed and telemetry.airspeed are in dm/s
  local hSpeed = utils.getMaxValue(telemetry.hSpeed,14) * 0.1 * conf.horSpeedMultiplier
  local speed = hSpeed

  if status.airspeedEnabled == 1 then
    speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    lcd.setColor(CUSTOM_COLOR,lcd.RGB(10,20,30))
    -- 120*0.667=80, 98*0.882=86, 66*0.667=44
    lcd.drawRectangle(80, 86, 44, 17, CUSTOM_COLOR)
    lcd.drawFilledRectangle(80, 86, 44, 17, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR,WHITE)
    lcd.drawText(82,85,"G",SMLSIZE+CUSTOM_COLOR+LEFT)
  end
  -- adjusted y to 48 to move up within black box, x to 118 to move left
  if (math.abs(speed) >= 10) then
    lcd.setColor(CUSTOM_COLOR,utils.colors.green)
    lcd.drawNumber(118,48,speed,MIDSIZE+CUSTOM_COLOR+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(118,75,hSpeed,SMLSIZE+CUSTOM_COLOR+RIGHT)
    end
  else
    lcd.setColor(CUSTOM_COLOR,utils.colors.green)
    lcd.drawNumber(118,48,speed*10,MIDSIZE+CUSTOM_COLOR+PREC1+RIGHT)
    if status.airspeedEnabled == 1 then
      lcd.setColor(CUSTOM_COLOR, utils.colors.white)
      lcd.drawNumber(118,75,hSpeed*10,SMLSIZE+CUSTOM_COLOR+PREC1+RIGHT)
    end
  end

  -- wind
  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR,BLACK)
    -- 120*0.667=80, 128*0.882=113, 66*0.667=44, 21*0.882=19
    lcd.drawRectangle(80, 113, 44, 19, CUSTOM_COLOR)
    lcd.drawFilledRectangle(80, 113, 44, 19, CUSTOM_COLOR+SOLID)
    lcd.setColor(CUSTOM_COLOR, utils.colors.white)
    lcd.drawText(82,114,"W",SMLSIZE+CUSTOM_COLOR+LEFT)
    lcd.drawNumber(124,110,telemetry.trueWindSpeed*conf.horSpeedMultiplier,PREC1+SMLSIZE+CUSTOM_COLOR+RIGHT)
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
  -- min/max arrows (168*0.667=112, 301*0.667=201, 73*0.882=64)
  if status.showMinMaxValues == true then
    libs.drawLib.drawVArrow(112, 64,true,false)
    libs.drawLib.drawVArrow(201, 64,true,false)
  end

  -- vspeed box
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  local vSpeed = utils.getMaxValue(telemetry.vSpeed,13) * 0.1 -- m/s

  local xx = math.abs(vSpeed*conf.vertSpeedMultiplier) > 999 and 4 or 3
  xx = xx + (vSpeed*conf.vertSpeedMultiplier < 0 and 1 or 0)

  -- 240*0.667=160, 123*0.882=109
  if math.abs(vSpeed*conf.vertSpeedMultiplier*10) > 99 then
    lcd.drawNumber(160 + (xx/2)*10, 109, vSpeed*conf.vertSpeedMultiplier, SMLSIZE+CUSTOM_COLOR+RIGHT)
  else
    lcd.drawNumber(160 + (xx/2)*10, 109, vSpeed*conf.vertSpeedMultiplier*10, SMLSIZE+CUSTOM_COLOR+RIGHT+PREC1)
  end

  -- compass ribbon (18*0.882=16, 220*0.667=147, 130*0.882=115)
  -- params: y, myWidget, width, xMin, xMax, stepWidth, bigFont, fontOffset, color
  libs.drawLib.drawCompassRibbon(16,myWidget,147,87,233,17,false,0,utils.colors.compassRibbon)
  -- pitch and roll (248*0.667=165, 90*0.882=79, 216*0.667=144, 74*0.882=65)
  lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
  -- moved pitch further down to y=86 to center in black bar
  local xoffset =  math.abs(telemetry.pitch) > 99 and 5 or 0
  lcd.drawNumber(165+xoffset,86,telemetry.pitch,SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.drawNumber(144,65,telemetry.roll,SMLSIZE+CUSTOM_COLOR+RIGHT)
  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  if conf.enableWIND == true then
    lcd.setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
    -- LCD_W/2=160, 86*0.882=76
    libs.drawLib.drawWindArrow(160,76,20,31,31,telemetry.trueWindAngle-telemetry.yaw, 1.3, CUSTOM_COLOR);
    libs.drawLib.drawWindArrow(160,76,23,31,31,telemetry.trueWindAngle-telemetry.yaw, 1.3, CUSTOM_COLOR);
  end
end

function panel.background(myWidget)
end

return panel

