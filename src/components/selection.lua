local selection =
  Concord.component(
  function(e, all_actions, all_directions)
    e.action = _constants.DEFAULT_ACTION
    e.all_actions = all_actions

    e.direction = _constants.DEFAULT_DIRECTION
    e.all_directions = all_directions

    e.is_passing = false
  end
)

function selection:set_action(action)
  assert(self.all_actions[action], "Received invalid action to selection:set_action")
  self.action = action
  self:cancel_pass()
end

function selection:set_direction(direction)
  assert(self.all_directions[direction], "Received invalid direction to selection:set_direction")
  self.direction = direction
  self:cancel_pass()
end

function selection:reset()
  self.action = _constants.DEFAULT_ACTION
  self.direction = _constants.DEFAULT_DIRECTION
  self.is_passing = false
end

function selection:prompt_pass()
  self.is_passing = true
end

function selection:cancel_pass()
  self.is_passing = false
end

function selection:to_string()
  return (self.action or "") .. ":" .. self.direction
end

return selection
