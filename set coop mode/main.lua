local mod = RegisterMod('Set Co-op Mode', 1)
local json = require('json')
local game = Game()

mod.onGameStartHasRun = false
mod.coopModes = { 'default', 'true co-op', 'co-op babies' }

mod.state = {}
mod.state.coopMode = 'default'

function mod:onGameStart()
  if mod:HasData() then
    local _, state = pcall(json.decode, mod:LoadData())
    
    if type(state) == 'table' then
      if type(state.coopMode) == 'string' and mod:getCoopModesIdx(state.coopMode) > 0 then
        mod.state.coopMode = state.coopMode
      end
    end
  end
  
  mod.onGameStartHasRun = true
  mod:onNewRoom()
end

function mod:onGameExit()
  mod:save()
  mod.onGameStartHasRun = false
end

function mod:save()
  mod:SaveData(json.encode(mod.state))
end

function mod:onNewRoom()
  if not mod.onGameStartHasRun then
    return
  end
  
  if mod.state.coopMode == 'true co-op' then
    game:SetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED, false) -- repurposed
  elseif mod.state.coopMode == 'co-op babies' then
    game:SetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED, true)
  end
end

function mod:getCoopModesIdx(val)
  for i, v in ipairs(mod.coopModes) do
    if v == val then
      return i
    end
  end
  
  return 0
end

-- start ModConfigMenu --
function mod:setupModConfigMenu()
  for _, v in ipairs({ 'Settings' }) do
    ModConfigMenu.RemoveSubcategory(mod.Name, v)
  end
  ModConfigMenu.AddSetting(
    mod.Name,
    'Settings',
    {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return mod:getCoopModesIdx(mod.state.coopMode)
      end,
      Minimum = 1,
      Maximum = #mod.coopModes,
      Display = function()
        return 'Co-op mode : ' .. mod.state.coopMode
      end,
      OnChange = function(n)
        mod.state.coopMode = mod.coopModes[n]
        mod:save()
      end,
      Info = { 'Default: true co-op in 1st room', 'True co-op: in all rooms', 'Co-op babies: in all rooms' }
    }
  )
  ModConfigMenu.AddText(mod.Name, 'Settings', '(Applied each time a room is entered)')
  ModConfigMenu.AddSpace(mod.Name, 'Settings')
  ModConfigMenu.AddSetting(
    mod.Name,
    'Settings',
    {
      Type = ModConfigMenu.OptionType.BOOLEAN,
      CurrentSetting = function()
        return game:GetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED)
      end,
      Display = function()
        return 'Current mode : ' .. (game:GetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED) and 'co-op babies' or 'true co-op')
      end,
      OnChange = function(b)
        game:SetStateFlag(GameStateFlag.STATE_BOSSPOOL_SWITCHED, b)
      end,
      Info = { 'Toggle mode' }
    }
  )
end
-- end ModConfigMenu --

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.onGameStart)
mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, mod.onGameExit)
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.onNewRoom)

if ModConfigMenu then
  mod:setupModConfigMenu()
end