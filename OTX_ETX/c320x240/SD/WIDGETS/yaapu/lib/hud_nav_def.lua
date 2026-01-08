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
-- viewport: 280x134 -> 187x118
-- last updated: 2026-01-08
--
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()

---------------------------------
-- Note: Home is absolute origin
---------------------------------

-- home relative vehicle coordinates
local myX = 0
local myY = 0

-- viewport relative vehicle coordinates
local myScreenX = 0
local myScreenY = 0

-- scaled viewport dimensions: 280*0.667=187, 134*0.882=118
local viewWidth = 160  -- HUD width
local viewHeight = 115 -- HUD height

-- absolute viewport home offset (centered in HUD area)
-- HUD area: x=80-240, y=16-131
local originX = 80 + viewWidth/2
local originY = 16 + viewHeight/2

-- size of grid in pixel (50*0.667=33)
local tileSize = 33
-- zoom factor
local zoom = 0.5
-- last n point circulart buffer
local xPoints = {}
local yPoints = {}

local sample = 0
local sampleCount = 0
local lastSample = getTime()

local avgDistSamples = {}

avgDistSamples[0] = 0

local avgDist = 0;
local avgDistSum = 0;
local avgDistSample = 0;
local avgDistSampleCount = 0;
local avgDistLastSampleTime = getTime();

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

local function drawVehicle(x,y,r,angle,style,xmin,xmax,ymin,ymax,color)
  local x1 = x + r * math.cos(math.rad(angle - 90))
  local y1 = y + r * math.sin(math.rad(angle - 90))
  local x2 = x + r * math.cos(math.rad(angle - 90 + 150))
  local y2 = y + r * math.sin(math.rad(angle - 90 + 150))
  local x3 = x + r * math.cos(math.rad(angle - 90 - 150))
  local y3 = y + r * math.sin(math.rad(angle - 90 - 150))
  local x4 = x + r * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = y + r * 0.5 *math.sin(math.rad(angle - 270))
  --
  libs.drawLib.drawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x1,y1,x3,y3,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x2,y2,x4,y4,style,xmin,xmax,ymin,ymax,color)
  libs.drawLib.drawLineWithClipping(x3,y3,x4,y4,style,xmin,xmax,ymin,ymax,color)
end

local function updateMyPosition(widget)
  -- calculate new absolute position
  if telemetry.homeAngle >= 0 then
    myX = telemetry.homeDist*math.cos(math.rad(telemetry.homeAngle-270))
    myY = telemetry.homeDist*math.sin(math.rad(telemetry.homeAngle-270))

    myScreenX = zoom*myX + originX;
    myScreenY = zoom*myY + originY;
  end

  if getTime() - avgDistLastSampleTime > 20 then
    avgDistSamples[avgDistSample] = telemetry.homeDist
    avgDistSampleCount = avgDistSampleCount+1
    avgDistSample = avgDistSampleCount%10
    avgDistLastSampleTime = getTime()

    avgDistSum = 0
    local samples=math.min(avgDistSampleCount,10)-1
    for s=0,samples
    do
      avgDistSum = avgDistSum+avgDistSamples[s]
    end
    avgDist=avgDistSum/(samples+1)
  end
  -- update last n positioins buffer
  if getTime() - lastSample > 50 then
    xPoints[sample] = myX
    yPoints[sample] = myY
    sampleCount = sampleCount+1
    sample = sampleCount%20
    lastSample = getTime()
  end
end

function panel.draw(widget)
  -- HUD area for 320x240: x=80-240, y=16-131
  local minX = 80
  local minY = 16
  local maxX = 80 + viewWidth
  local maxY = 16 + viewHeight

  lcd.setColor(CUSTOM_COLOR,lcd.RGB(0x63, 0x30, 0x00)) --623000 old brown
  lcd.drawFilledRectangle(minX,minY,viewWidth,viewHeight,CUSTOM_COLOR)
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  --
  updateMyPosition(widget)

  -- draw the tile grids
  local myTileSize = tileSize*zoom

  lcd.setColor(CUSTOM_COLOR,utils.colors.grey)

  local myCode = libs.drawLib.computeOutCode(myScreenX, myScreenY, minX+13, minY+13,maxX-13, maxY-13);

  -- center vehicle on screen
  if myCode == 1 or myCode == 2 or myCode == 8 or myCode == 4 then
      originX = 80 + viewWidth/2 - zoom*myX;
      originY = 16 + viewHeight/2 - zoom*myY
  end

  -- round minX to closest tileSize multiple
  local xStart = 80 + viewWidth/2 + 7 - (1+math.floor(viewWidth/2/tileSize))*tileSize
  local xOffset = xStart + originX%myTileSize

  for v=0,1+viewWidth/myTileSize
  do
    libs.drawLib.drawLineWithClipping(xOffset+v*myTileSize,minY,xOffset+v*myTileSize,maxY,SOLID,minX+1,maxX-1,minY+1,maxY-1,CUSTOM_COLOR)
  end

  local yStart = 16 + viewHeight/2 + 10 - (1+math.floor(viewHeight/2/tileSize))*tileSize
  local yOffset = yStart + originY%myTileSize
  for h=0,1+viewHeight/myTileSize
  do
    libs.drawLib.drawLineWithClipping(minX,yOffset+h*myTileSize,maxX,yOffset+h*myTileSize,SOLID,minX+1,maxX-1,minY+1,maxY-1,CUSTOM_COLOR)
  end

  local homeCode = libs.drawLib.computeOutCode(originX, originY, minX+7, minY+7,maxX-7, maxY-7);

  local originXclip = originX;
  local originYclip = originY;

  if bit32.band(homeCode,1) == 1 then
    originXclip = minX+7;
  end
  if bit32.band(homeCode,2) == 2 then
    originXclip = maxX-7;
  end
  if bit32.band(homeCode,8) == 8 then
      originYclip = minY+7;
  end
  if bit32.band(homeCode,4) == 4 then
    originYclip = maxY-7;
  end

  if originXclip ~= originX or originYclip ~= originY then
    utils.drawBlinkBitmap("minihomeorange",originXclip-7/2,originYclip-7/2)
  else
    libs.drawLib.drawHomeIcon(originXclip-7/2,originYclip-7/2,utils)
  end

  -- last n points
  lcd.setColor(CUSTOM_COLOR,utils.colors.darkyellow)
  for p=0, math.min(sampleCount-1,20-1)
  do
    local xx = zoom*xPoints[p] + originX;
    local yy = zoom*yPoints[p] + originY;
    if (xx ~= myScreenX or yy ~= myScreenY) and libs.drawLib.computeOutCode(xx, yy, minX+2, minY+2, maxX-2, maxY-2) == 0 then
        lcd.drawFilledRectangle(xx,yy,2,2,CUSTOM_COLOR)
    end
  end

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)

  -- vehicle size: 20*0.667=13
  drawVehicle(myScreenX, myScreenY, 13, telemetry.yaw, SOLID, minX, maxX, minY, maxY, CUSTOM_COLOR)

  lcd.drawNumber(minX,minY+viewHeight+5,avgDist,SMLSIZE+CUSTOM_COLOR)

  lcd.setColor(CUSTOM_COLOR,utils.colors.white)
end

function panel.background(widget)
end

return panel
