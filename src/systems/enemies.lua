local enemies =
  Concord.system(
  {_components.enemy, _components.grid, _components.brain, "ENEMIES"},
  {_components.control, _components.grid, _components.health, "PLAYER"}
)
function enemies:init()
  self.timer = Timer.new()
  self.process_enemy_callback_fn = nil
  self.enemies_to_action = {}
  self.current_phase = nil
  self.active = false
  self.turn_duration = 0.5
end

function enemies:update(dt)
  if self.active then
    self.timer:update(dt)

    if #self.enemies_to_action == 0 then
      -- all enemies processed, weeeeee
      self.active = false
      self:getWorld():emit("end_phase", "ENEMIES")
    end
  end
end

function enemies:begin_phase(phase)
  if phase ~= "ENEMIES" then
    return
  end

  self.active = true
  self.enemies_to_action = {}
  for i = 1, self.ENEMIES.size do
    local e = self.ENEMIES:get(i)
    table.insert(self.enemies_to_action, e)
  end

  self.process_enemy_callback_fn =
    self.timer:every(
    self.turn_duration / self.ENEMIES.size,
    function()
      self:action_top_enemy()
    end,
    #self.enemies_to_action
  )
end

function enemies:action_top_enemy()
  -- pop enemy from our table
  local enemy = table.remove(self.enemies_to_action, 1)
  if enemy:get(_components.enemy).marked_for_deletion then
    return
  end
  local brain = enemy:get(_components.brain)
  if brain.type == "goblin" then
    -- choose an action with their BRAIN
    self:action_goblin(enemy)
  else
    print("mystery brain...duhhh....")
  end
end

function enemies:action_goblin(e)
  local enemy_grid = e:get(_components.grid)

  local player = self.PLAYER:get(1)
  local player_grid = player:get(_components.grid)

  local delta = player_grid.position - enemy_grid.position
  local choices = {{"wait", 1}}

  if delta.x > 0 then
    table.insert(choices, {"right", 5})
  end
  if delta.x < 0 then
    table.insert(choices, {"left", 5})
  end
  if delta.y > 0 then
    table.insert(choices, {"down", 5})
  end
  if delta.y < 0 then
    table.insert(choices, {"up", 5})
  end
  local choice = _util.g.choose_weighted(unpack(choices))

  if choice ~= "wait" then
    self:getWorld():emit("attempt_entity_move", e, choice)
  end
end

return enemies
