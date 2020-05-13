class 'BuffExplorer'
	
function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
	t2[k] = v
  end
  return t2
end
  
  function BuffExplorer:__init()

	  self.Heroes = {}
	  self.Buffs  = {}
	  self.OldBuffs = {}
	  self.RemoveBuffCallback = {}
	  self.UpdateBuffCallback = {}
	  for i = 1, Game.HeroCount() do
		  local hero = Game.Hero(i)
			 table.insert(self.Heroes, hero)
		  self.Buffs[hero.networkID] = {}
		  self.OldBuffs[hero.networkID] = {}

	  end
	   Callback.Add("Tick", function () self:Tick() end)
  end

  function BuffExplorer:RemoveBuff(unit,buff)
	  for i, cb in pairs(self.RemoveBuffCallback) do
		  cb(unit,buff)
	  end
  end
  
  function BuffExplorer:UpdateBuff(unit,buff)
	  for i, cb in pairs(self.UpdateBuffCallback) do
		  cb(unit,buff)
	  end
  end
  
  function BuffExplorer:Tick()
    local check = os.clock()
    local tick = GetTickCount()

    for _, hero in pairs(self.Heroes) do
        for i = 0, hero.buffCount do
            local buff = hero:GetBuff(i)
            if self:Valid(buff) then
                if self.OldBuffs[hero.networkID][buff.name] then
                    self.OldBuffs[hero.networkID][buff.name].tick = tick
                end

                if not self.Buffs[hero.networkID][buff.name] or (self.Buffs[hero.networkID][buff.name] and self.Buffs[hero.networkID][buff.name].expireTime ~= buff.expireTime) then
                    self.Buffs[hero.networkID][buff.name] = {expireTime = buff.expireTime, buff = buff, tick = tick}
                    self:UpdateBuff(hero,buff)
                end
            end
        end
    end

    for _, hero in pairs(self.Heroes) do
        for buffname,buffinfo in pairs(self.OldBuffs[hero.networkID]) do
            if buffinfo.tick and buffinfo.tick ~=tick then
                self:RemoveBuff(hero,buffinfo.buff)
                self.OldBuffs[hero.networkID][buffname].tick = nil
                self.OldBuffs[hero.networkID][buffname] = nil
            end
        end
    end

    for _, hero in pairs(self.Heroes) do
        self.OldBuffs[hero.networkID] = table.shallow_copy(self.Buffs[hero.networkID])
    end

end
  
  function BuffExplorer:Valid(buff)
    return buff and buff.name and #buff.name > 0 and #buff.name < 50 
    and buff.count >0 and buff.duration < 5000
    and buff.expireTime > Game.Timer() and buff.startTime <= Game.Timer()
end


  if not _G.BuffExplorer then	
	  _G.BuffExplorer = BuffExplorer() 
  end	
  
  OnBuffGain = function(cb)
	  table.insert(BuffExplorer.UpdateBuffCallback,cb)
  end
  OnBuffLost = function(cb)
	  table.insert(BuffExplorer.RemoveBuffCallback,cb)
  end

