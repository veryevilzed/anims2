
local anims = {
  _VERSION     = 'Anim',
  _DESCRIPTION = 'A sprite and animation library for LÖVE based on sodapop (https://github.com/tesselode/sodapop)',
  _URL         = '',
  _LICENSE     = [[ ]]
}


local Animation = {}
local Sprite = {}

local scripts = require "animsscript"
local lgd = love.graphics.draw

local function newAnimation(parameters)
  local animation = {
    atlas               = parameters.atlas,
    stopAtEnd           = parameters.stopAtEnd,
    stopScriptAtEnd     = parameters.stopScriptAtEnd,
    onFramesEnd         = parameters.onFramesEnd or function() end,
    onScriptsEnd        = parameters.onScriptsEnd or function() end,
    frames              = {},
    scripts             = {},
    playing             = parameters.playing or true,
    playingScript       = parameters.playingScript or true,
    current             = 1,
    currentScript       = 1,
    sx                  = parameters.sx or 1,
    sy                  = parameters.sy or 1,
    x                   = parameters.x or 0,
    y                   = parameters.y or 0,
    r                   = parameters.r or 0,
    z                   = parameters.z or 0,
  }
  setmetatable(animation, {__index = Animation})
  for i = 1, #parameters.frames do
    animation:addFrames(unpack(parameters.frames[i]))
  end
  
  if parameters.scripts then
    for i = 1, #parameters.scripts do
      animation:addScript(unpack(parameters.scripts[i]))
    end
  else
    playingScript = false
  end
 
  if parameters.reverse then animation:reverse() end
  animation.timer = animation.frames[1].duration
  animation.scriptTimer = 0
  if animation.scripts and #animation.scripts>0 then 
    animation.scriptTimer = animation.scripts[1].duration
  end
  return animation
end

function Animation:reverse()
    local newFrames = {}
    local newScripts = {}
    for i = #self.frames, 1, -1 do
        table.insert(newFrames, self.frames[i])
    end
    table.insert(newScripts, self.scripts[i])

    self.frames = newFrames
    self.scripts = newScripts
end

function Animation:addFrames(name, duration, start, finish, mode)
    local dx = 1
    if start>finish then dx = -1 end
    for x = start, finish, dx  do
        table.insert(self.frames, {
            name = string.format(name, x),
            duration = duration,
            mode = mode or "simple"
        })
    end
end

function Animation:addScript(name, duration, ...)
    table.insert(self.scripts, 
        scripts[name](scripts[name],duration, ...)
    )
end

function Animation:setScriptParams(index, df)
  self.currentScript = math.min(#self.scripts, index)
  self.scripts[self.currentScript].df = math.min(self.scripts[index].duration, df)
  self.playingScript = true
end

function Animation:goToFrame(frame)
  assert(frame <= #self.frames, 'Frame number out of range')
  self.current = frame
  self.timer   = self.frames[self.current].duration
  self.playing = true
end

function Animation:draw(x, y, r, sx, sy, flipX, flipY)
    local txt, _, quad, offset, rect = self.atlas:get(self.frames[self.current].name)
    if offset == nil then  error("Animation: " .. self.frames[self.current].name .. " not found") end
    if flipX then sx = -sx end
    if flipY then sy = -sy end
    local tx,ty,tr,tsx,tsy,color = 0,0,0,1,1,nil
    if self.scripts and self.scripts[self.currentScript] then tx,ty,tr,tsx,tsy,color,mode, alphamode = self.scripts[self.currentScript]:draw() end
    if mode ~= "alpha" or alphamode ~= "alphamultiply" then love.graphics.setBlendMode(mode or "alpha", alphamode or "alphamultiply") end
    if color then love.graphics.setColor(color) end
    lgd(txt, quad, x+tx+self.x, y+ty+self.y, r+tr+self.r, sx*tsx*self.sx, sy*tsy*self.sy, offset[3]/2 - offset[1], offset[4]/2 - offset[2])
    if mode ~= "alpha" or alphamode ~= "alphamultiply" then love.graphics.setBlendMode("alpha", "alphamultiply") end
    --love.graphics.setBlendMode("alpha", "alphamultiply")
    if color then love.graphics.setColor({255,255,255,255}) end
end

function Animation:advance()
    self.current = self.current + 1
    if self.current > #self.frames then
        self.onFramesEnd(self.parent, self)
        if self.stopAtEnd then
          self.playing = false
          self.current = #self.frames
        else
          self.current = 1
        end
    end
    if self.playing then
        self.timer = self.timer + self.frames[self.current].duration
    end
end


function Animation:advanceScript()
    self.currentScript = self.currentScript + 1
    if self.currentScript > #self.scripts then
        self.onScriptsEnd(self.parent, self)
        if self.stopScriptAtEnd then
          self.playingScript = false
          self.currentScript = #self.scripts
        else
          self.currentScript = 1
        end
    end
    self.scripts[self.currentScript]:reset()
    -- if self.playingScript then
    --     self.scriptTimer = self.scriptTimer + self.scripts[self.currentScript].duration
    -- end
end


function Animation:update(dt)
  if self.playing then
    self.timer = self.timer - dt
    while self.timer < 0 do
      self:advance()
      if not self.playing then
        break
      end
    end
  end
  
  if self.playingScript and #self.scripts > 0 then 
    self.scripts[self.currentScript]:update(dt)
    local d = self.scripts[self.currentScript].df - self.scripts[self.currentScript].duration
    if d>0 then
      self:advanceScript()
    end
  end
end


function Sprite:addAnimation(name, parameters)
  self.animations[name] = newAnimation(parameters)
  self.animations[name].parent = self
  if not self.current then self:switch(name) end
end


function Sprite:switch(name, params)
  --assert(self.animations[name], 'No animation named '..name)
  self.disable = self.animations[name] == nil
  if self.disable then return; end
  if not params then params = {} end
  local frame = 1 
  local scriptFrame = 1
  local scriptDf = 0
  if self.current and params.saveFrame then frame = self.current.current end
  if self.current and params.saveScript then 
    scriptFrame = self.current.currentScript
    --print(self.current, scriptFrame)
    scriptDf = self.current.scripts[scriptFrame].df
  end

  self.current = self.animations[name]
  self.current.parent = self
  -- Frames
  if params.resumeFrame then 
  elseif params.saveFrame then
      self.current.current = math.min(frame, #self.current.frames)
  else 
      self.current:goToFrame(1)
  end
  -- Scripts
  if #self.current.scripts>0 then
    if params.resumeScript then
    elseif params.saveScript then
        self.current:setScriptParams(scriptFrame, scriptDf)
    else 
        self.current:setScriptParams(1,0)
    end
  end
end

function Sprite:goToFrame(frame) if self.current then self.current:goToFrame(frame) end end

function Sprite:update(dt)
  if self.disable then return; end
  if self.playing then self.current:update(dt) end
  if self.playing_script then if self.current_script then self.current_script:update(dt) end end
end

function Sprite:draw(ox, oy)
    if self.disable then return; end
    ox, oy = ox or 0, oy or 0
    love.graphics.setColor(self.color)
    self.current:draw(self.x + ox, self.y + oy, self.r, self.sx, self.sy,
    self.flipX, self.flipY)
end


function anims.newAnimatedSprite(x, y)
  local sprite = {
    animations = {},
    scripts    = {},
    x          = x or 0,
    y          = y or 0,
    r          = 0,
    sx         = 1,
    sy         = 1,
    flipX      = false,
    flipY      = false,
    color      = {255, 255, 255, 255},
    playing    = true,
  }
  setmetatable(sprite, {__index = Sprite})
  return sprite
end

function anims.newSprite(image, x, y)
  local sprite = sodapop.newAnimatedSprite(x, y)
  sprite:addAnimation('main', {
    image       = image,
    frameWidth  = image:getWidth(),
    frameHeight = image:getHeight(),
    frames      = {
      {1, 1, 1, 1, 1},
    },
  })
  return sprite
end

return anims