local hook =
  Concord.system(
  {_components.control, _components.hook_thrower, _components.grid, "PLAYER"},
  {_components.grid, _components.head, _components.chain, "HOOK"}
)

local _DIRECTION_OFFSETS = {
  ["right"] = Vector(1, 0),
  ["down"] = Vector(0, 1),
  ["left"] = Vector(-1, 0),
  ["up"] = Vector(0, -1)
}

function direction_to_offset(direction)
  assert(_DIRECTION_OFFSETS[direction], "'direction_to_offset' received invalid direction")
  return _DIRECTION_OFFSETS[direction]:clone()
end

function hook:init()
  self.timer = Timer.new()
end

function hook:throw_hook(direction)
  local player = self.PLAYER:get(1)
  local hook_thrower = player:get(_components.hook_thrower)
  -- check direction is valid

  hook_thrower:throw(direction)
  _assemblages.hook:assemble(
    Concord.entity(self:getWorld()),
    player:get(_components.grid).position + direction_to_offset(direction),
    direction
  )

  self:getWorld():emit("end_phase")
end

function hook:update(dt)
  self.timer:update(dt)
end

function hook:begin_phase(phase)
  if phase ~= "HOOK" then
    return
  end

  local player = self.PLAYER:get(1)
  if player:get(_components.hook_thrower).can_throw then
    print("skipping phase, there is no hook out")
    self:getWorld():emit("end_phase")
  else
    local to_remove = {}
    for i = 1, self.HOOK.size do
      local e = self.HOOK:get(i)
      local grid = e:get(_components.grid)
      local head = e:get(_components.head)
      local chain = e:get(_components.chain)
      if head.is_extending then
        -- check if we're at max length, if so, begin retracting
        if chain:is_full() then
          print("chain is full, lets retract")
          head:retract()
        else
          -- move one step in the head's direction
          chain:add_link_to_front(grid.position, head.direction)
          self:getWorld():emit("attempt_entity_move", e, head.direction, false)
        end
      end
      -- this is deliberatly not an else, as the above logic could change the state and we want to action that
      if not head.is_extending then
        -- we're retracting, move to the last chain link and shrink the chain
        self:getWorld():emit("attempt_entity_move", e, head.direction, false)
        chain:consume_last() -- TODO: might need some cleverness to not ALWAYS do this (what if it failed?)
        if #chain.links == 0 then -- TODO: where else can we do this? currently not allowing a final clutch movement to keep the hook
          table.insert(to_remove, e)
          player:get(_components.hook_thrower):reset()
        end
      end
      _util.t.print(chain.links)
    end

    for i, entity in ipairs(to_remove) do
      self:getWorld():removeEntity(entity)
    end

    self:getWorld():emit("end_phase")
  end
end

function hook:player_with_hook_moved(player_moved_from, direction)
  for i = 1, self.HOOK.size do
    local e = self.HOOK:get(i)
    e:get(_components.chain):add_link_to_back(player_moved_from, direction)
  end
end

function hook:invalid_entity_move(e)
  if not (e:has(_components.head) and e:has(_components.grid)) then
    return -- that ain't no hook
  end
  print("hooky hit a wall D:")
  e:get(_components.head):retract()
end

return hook
