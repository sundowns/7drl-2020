local health =
  Concord.component(
  function(e, current, maximum)
    e.current = current
    e.maximum = maximum
  end
)

function health:reduce(delta)
  if self.current > 0 then
    self.current = self.current - delta
  end
end

function health:increase(delta)
  self.current = math.min(self.current + delta, self.maximum)
end

return health
