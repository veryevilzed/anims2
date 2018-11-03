

function create(ctx)
  local res = {
    ctx = ctx,
    path = {},
    pt = 0,
    _wait = 0,
    add = function(self, ...)
      for _,fun in pairs({...}) do
        if type(fun) ~= "function" then error("Not function") end
        table.insert(self.path, fun)
      end
      return self
    end,
    clear = function(self)
      self.path = {}
      return self
    end,
    wait = function(self, n)
      self:add(function() return "wait",n end)
      return self
    end,
    animated = function(self)
      return #self.path > 0
    end,
    update = function(self, dt)
      if self.path and #self.path>0 then
        if self._wait > 0 then
          self._wait = self._wait - dt
          return
        end
        local res, arg = self.path[1](self.pt, self.ctx)
        self.pt = self.pt + dt
        if res == nil or res == "ok" then
          table.remove(self.path, 1)
          self.pt = 0
        elseif res == "continue" or res == "c" then
          if arg then
            self._wait = arg
          end
        elseif res == "imidietly" or res == "i" or res == "now" then
          table.remove(self.path, 1)
          self.pt = 0
          self:update(0)
        elseif res == "wait" or res == "w" then
          table.remove(self.path, 1)
          self.pt = 0
          if arg then
            self._wait = arg
          end
        else
        end
      end
      return #self.path > 0
    end
  }

  return res
end

return {
  create = create
}
