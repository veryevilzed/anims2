
local easyng = require("easyng")
local path = require("path")
local scripts = {}


local Flip = {}
function Flip:reset()
    self.df = 0
    self.path = path.create({})
    self.r = 0
    local mode = self.parameters.mode or "full"
    if mode == "full" then
        self.path:add(
            function(pt)
                if pt > self.duration / 2 then
                    self.sx = -1
                    return "ok"
                end
                self.sx = easyng[name or "linearTo"](pt, 1, -1, self.duration / 2)
                return "c"
            end,
            function(pt)
                if pt > self.duration / 2 then
                    self.sx = self.parameters.sx or 1
                    return "ok"
                end
                self.sx = easyng[name or "linearTo"](pt, -1, 1, self.duration / 2)
                return "c"
            end
        )
    elseif mode == "half" then
        self.path:add(
            function(pt)
                if pt > self.duration then
                    self.sx = -1
                    return "ok"
                end
                self.sx = easyng[name or "linearTo"](pt, 1, 0, self.duration )
                return "c"
            end
        )        
    end
end

function Flip:update(dt)
    self.df = self.df + dt
    if self.path then self.path:update(dt) end
end

function Flip:draw() 
    return 0,0,0, self.sx or 1,1, {255,255,255,255}
end



local Shake = {}
function Shake:reset()
    self.df = 0
    self.path = path.create({})
    self.r = 0
    self.path:add(
        function(pt)
            if pt > self.duration / 4 then
                self.r = self.parameters.r
                return "ok"
            end
            self.r = easyng[name or "linearTo"](pt, 0, self.parameters.r, self.duration / 4)
            return "c"
        end,
        function(pt)
            if pt > self.duration / 2 then
                self.r = -self.parameters.r
                return "ok"
            end
            self.r = easyng[name or "linearTo"](pt, self.parameters.r, -self.parameters.r, self.duration / 2)
            return "c"
        end,
        function(pt)
            if pt > self.duration / 4 then
                self.r = 0
                return "ok"
            end
            self.r = easyng[name or "linearTo"](pt, -self.parameters.r, 0, self.duration / 4)
            return "c"
        end
    )
end

function Shake:update(dt)
    self.df = self.df + dt
    if self.path then self.path:update(dt) end
end

function Shake:draw() 
    return 0,0, self.r or 0, 1,1, {255,255,255,255}
end


local Wait = {}
function Wait:reset()
    self.df = 0
    if self.parameters.from then self.duration = self.parameters.from end
    if self.parameters.rnd then self.duration = self.duration + lume.random(self.parameters.rnd) end
end

function Wait:update(dt)
    self.df = self.df + dt
end

function Wait:draw() 
    return self.parameters.x or 0,
           self.parameters.y or 0,
           self.parameters.r or 0,
           self.parameters.sx or 1,
           self.parameters.sy or 1,
           self.parameters.color or {255,255,255,255} 
end

local Easyng = {}
function Easyng:reset()
    self.df = 0
end

function Easyng:update(dt)
    self.df = self.df + dt
end

function Easyng:__do(param)
    if not param then return; end
    return easyng[(param.name or "linear") .. "To"](math.min(self.df, self.duration), param.from, param.to, self.duration)
end

function Easyng:draw()
    local tx, ty, tr, sx, sy, cr,cg,cb,ca, mode, alphamode = 0,0,0,1,1, 255,255,255,255, "alpha", "alphamultiply"
    if self.parameters.scale then
        local f = self:__do(self.parameters.scale)
        sx, sy = sx * f, sy * f
    end

    if self.parameters.scaleX then 
        local f = self:__do(self.parameters.scaleX)
        sx = sx * f
    end

    if self.parameters.scaleY then 
        local f = self:__do(self.parameters.scaleY)
        sy = sy * f
    end

    if self.parameters.rotate then 
        local f = self:__do(self.parameters.rotate)
        tr = tr * f
    end

    if self.parameters.translateX then 
        local f = self:__do(self.parameters.translateX)
        tx = tx + f
    end

    if self.parameters.translateY then 
        local f = self:__do(self.parameters.translateY)
        ty = ty + f
    end

    if self.parameters.alpha then 
        local f = self:__do(self.parameters.alpha)
        ca = f
    end

    if self.parameters.colorA then 
        local f = self:__do(self.parameters.colorA)
        ca = f
    end


    if self.parameters.color then 
        local f = self:__do(self.parameters.color)
        cr,cg,cb = f,f,f
    end

    if self.parameters.colorR then 
        local f = self:__do(self.parameters.colorR)
        cr = f
    end

    if self.parameters.colorG then 
        local f = self:__do(self.parameters.colorG)
        cg = f
    end

    if self.parameters.colorB then 
        local f = self:__do(self.parameters.colorB)
        cb = f
    end

    if self.parameters.mode then 
        mode = self.parameters.mode
    end

    if self.parameters.alphamode then 
        alphamode = self.parameters.alphamode
    end


    return tx, ty, tr, sx, sy, {cr,cg,cb,ca}, mode, alphamode
end

function scripts:wait(duration, parameters)
     local s = {
        duration = duration,
        parameters = parameters or {},
        df = 0
    }
    setmetatable(s, {__index = Wait})
    s:reset()
    return s
end

function scripts:easyng(duration, parameters)
    local s = {
        duration = duration,
        parameters = parameters,
        df = 0
    }
    setmetatable(s, {__index = Easyng})
    s:reset()
    return s
end

function scripts:shake(duration, parameters)
    local s = {
        duration = duration,
        parameters = parameters,
        df = 0
    }
    setmetatable(s, {__index = Shake})
    s:reset()
    return s
end

function scripts:flip(duration, parameters)
    local s = {
        duration = duration,
        parameters = parameters,
        df = 0
    }
    setmetatable(s, {__index = Flip})
    s:reset()
    return s
end

return scripts

