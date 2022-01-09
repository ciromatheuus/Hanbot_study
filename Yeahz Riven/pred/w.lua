local TS = module.internal('TS')
local orb = module.internal('orb')
local pred = module.internal('pred')

local w = module.load(header.id, 'spell/w')
local push = module.load(header.id, 'pred/push')
local menu = module.load(header.id, 'menu')

local source = nil

local input = {
  delay = 0,
  radius = 0,
  dashRadius = 0,
  boundingRadiusModSource = 0,
  boundingRadiusModTarget = 0,
}


local f = function(res, obj, dist)
  if dist > 1500 then return end
  if pred.present.get_prediction(input, obj, source) then
    res.obj = obj
    return true
  end
end

local res = {}

local get_prediction = function(pos)
  input.radius = w.radius()
  return TS.get_result(f, TS.filter_set[1], false, true)
end

local get_spell_state = function()
  return w.is_ready()
end

local get_action_state = function(pos)
  if get_spell_state() then
    source = pos
    res = get_prediction(pos)
    if res.obj then
      return res
    end
  end
end

local invoke_action = function(pause)
  player:castSpell('self', 1)
  if pause then
    orb.core.set_server_pause()
  end
end

local get_total_radius = function()
  return w.radius()
end

local get_total_delay = function()
  return 0
end


local enemy_range = 1200
local enemy_inrange = function (dist)
  for i=0, objManager.enemies_n-1 do
    local obj = objManager.enemies[i]
    -- print("obj.charName",obj.charName)
    -- print("obj.isOnScreen",obj.isOnScreen)
    -- print("obj.isDead",obj.isDead)
    if player.pos2D:dist(obj.pos2D) < dist and not obj.isDead and obj.isTargetable then
      return true
    end
  end
end

local push_w_NE = function ()
  return menu.farm_setting.lane_clear.push_w_NE:get() and not enemy_inrange(1200) or not menu.farm_setting.lane_clear.push_w_NE:get()
end

local get_push_state = function()
  if get_spell_state() then
    local obj,p2= push.get_prediction(get_total_delay(), get_total_radius())
    if obj and menu.farm_setting.farm:get() then
      if obj.team == TEAM_ENEMY and menu.farm_setting.lane_clear.push_w:get() then
        if push_w_NE() then
          if push.get_minion_count_inrange(player.pos, get_total_radius()) >= menu.farm_setting.lane_clear.push_w_count.value then
            res = {obj = obj}
            return res
          end
        end
      end
      if (obj.team == TEAM_NEUTRAL and menu.farm_setting.jungle_clear.push_w:get()) then
        if push.get_minion_count_inrange(player.pos, get_total_radius()) >= menu.farm_setting.jungle_clear.push_w_count.value or (obj.highValue) then
          res = {obj = obj}
          return res
        end
      end
    end
  end
end

return {
  get_action_state = get_action_state,
  invoke_action = invoke_action,
  get_spell_state = get_spell_state,
  get_total_radius = get_total_radius,
  get_total_delay = get_total_delay,
  get_push_state = get_push_state,
}
