
local path = mod_loader.mods[modApi.currentMod].scriptPath
local ceo_rst_gray = require(path .."replaceIsland/ceo_rst_grayscale")
local this = {}

local islandRandomize = false

function this.loadIslandOrder()
	local m = lmn_replace_island
	
	m.islandOrder = {}
	for island, _ in pairs(m.islands) do
		table.insert(m.islandOrder, island)
	end
	
	local order = {}
	local i = 0
	sdlext.config("modcontent.lua", function(obj)
		for _, island in ipairs(m.mostRecent.defaultCorps) do
			if not list_contains(obj.islandOrder or {}) then
				i = i + 1
				order[island] = i
			end
		end
		
		for _, island in ipairs(obj.islandOrder or {}) do
			i = i + 1
			order[island] = i
		end
		
		islandRandomize = obj.islandRandomize or false
	end)
	
	for island, _ in pairs(m.islands) do
		if not order[island] then
			i = i + 1
			order[island] = i
		end
	end
	
	if not isContinuePresent() and islandRandomize then
		local keys, j = {}, 1
		for k,_ in pairs(m.islands) do
			keys[j] = k
			j= j+1
		end
	
		math.randomseed(os.time())
		for j=0,30 do --num swaps
			local k1 = math.random(1, #keys)
			local k2 = math.random(1, #keys)
			if not m.unlockRst and k1 ~= 4 and k2 ~= 4 then   --not RST
				order[keys[k1]], order[keys[k2]] = order[keys[k2]], order[keys[k1]]
			end
		end
	end

	table.sort(m.islandOrder, function(a,b)
		return order[a] < order[b]
	end)
	
	lmn_replace_island.saveIslandOrder()
end

function isContinuePresent()
  local path = os.getKnownFolder(5).."/My Games/Into the Breach/"
  local profilePath = path.."profile_"..Settings.last_profile.."/"
  local savePath = profilePath.."saveData.lua"

  return modApi:fileExists(savePath)
end

function this.saveIslandOrder()
	local m = lmn_replace_island
	
	sdlext.config("modcontent.lua", function(obj)
		obj.islandOrder = m.islandOrder
		obj.islandRandomize = islandRandomize
	end)
end

-- ui based heavily on pilot_arrange.lua from the mod_loader.
function this.createUi()
	local checkbox
	local m = lmn_replace_island
	
	local islandButtons = {}
	
	local onExit = function(self)
		m.islandOrder = {}
		
		for i = 1, #islandButtons do
			m.islandOrder[i] = islandButtons[i].id
		end
		islandRandomize = checkbox.checked
		
		m.saveIslandOrder()
	end
	
	sdlext.showDialog(function(ui)
		ui.onDialogExit = onExit
		
		local portraitW = 122 + 8
		local portraitH = 122 + 8
		local gap = 10
		local cellW = portraitW + gap
		local cellH = portraitH + gap
		
		local frametop = Ui()
			:width(0.4):height(0.8)
			:posCentered()
			:caption(m.texts.IslandArrange_FrameTitle)
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:addTo(ui)
		
		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(24)
			:addTo(frametop)
		
		local placeholder = Ui()
			:pospx(-cellW, -cellH)
			:widthpx(portraitW):heightpx(portraitH)
			:decorate({ })
			:addTo(scrollarea)
		
		local portraitsPerRow = math.floor(ui.w * frametop.wPercent / cellW)
		frametop
			:width((portraitsPerRow * cellW + scrollarea.padl + scrollarea.padr) / ui.w)
			:posCentered()
		
		local draggedElement
		local function rearrange()
			local index = list_indexof(islandButtons, placeholder)
			if index ~= nil and draggedElement ~= nil then
				local col = math.floor(draggedElement.x / cellW + 0.5)-1
				local row = math.floor(draggedElement.y / cellH + 0.5)
				local desiredIndex = 1 + col + row * portraitsPerRow
				
				if desiredIndex < 1 then desiredIndex = 1 end
				if desiredIndex > #islandButtons then desiredIndex = #islandButtons end
				
				if desiredIndex ~= index then
					table.remove(islandButtons, index)
					table.insert(islandButtons, desiredIndex, placeholder)
				end
				
				-- always put RST back to slot 2.
				if not m.unlockRst and islandButtons[2].id ~= "Corp_Desert" then
					for i, v in ipairs(islandButtons) do
						if v.id == "Corp_Desert" then
							if i ~= 2 then
								table.remove(islandButtons, i)
								table.insert(islandButtons, 2, v)
								break
							end
						end
					end
				end
			end
			
			for i = 1, #islandButtons do
				local col = (i) % portraitsPerRow
				local row = math.floor((i) / portraitsPerRow)
				local button = islandButtons[i]
				
				button:pospx(cellW * col, cellH * row)
				if button == placeholder then
					placeholderIndex = i
				end
			end
			
			if placeholderIndex ~= nil and draggedElement ~= nil then
			
			end
		end
		
		local bheight = 40
		local twobuttonH = bheight * 2 + gap
		
		local newDraw = function(self, screen)
			if checkbox.checked then
				self.disabled = true
			else
				self.disabled = false
			end
			ui.draw(self, screen)
		end
		
		local function addRandomButton()
			checkbox = UiCheckbox()
				:widthpx(portraitW):heightpx(bheight)
				:pospx(0, (portraitH - twobuttonH) * 0.5 + bheight + gap)
				:settooltip("Randomize Island order each time a new game is started.\n\nRequires game to be restarted with no save file. Complete your current timeline or use ABANDON TIMELINE to remove current save file.")
				:decorate({
					DecoCheckbox(),
					DecoAlign(4, 2),
					DecoText("Randomize"),
				})
				:addTo(scrollarea)
			
			checkbox.checked = islandRandomize
		end
		
		local function addDefaultButton()
			local button = Ui()
				:widthpx(portraitW):heightpx(bheight)
				:pospx(0, (portraitH - twobuttonH) * 0.5)
				:settooltip("Default Island order.\n\nRemember to restart game for changes to take effect.")
				:decorate({
					DecoButton(),
					DecoAlign(23,2),
					DecoText("Default"),
				})
				:addTo(scrollarea)			
			button.draw = newDraw -- Needed for disabling when Randomize checkbox is set
			
			button.onclicked = function()
				local corps = {
					"Corp_Grass",
					"Corp_Desert",
					"Corp_Snow",
					"Corp_Factory"
				}
				
				for j = 1,4 do
					if islandButtons[j].id ~= corps[j] then
						for i, v in ipairs(islandButtons) do
							if v.id == corps[j] then
								islandButtons[i], islandButtons[j] = islandButtons[j], islandButtons[i]
							end
						end
					end
				end

				for i = 1, #islandButtons do
					local col = (i) % portraitsPerRow
					local row = math.floor((i) / portraitsPerRow)
					local button0 = islandButtons[i]
					
					button0:pospx(cellW * col, cellH * row)
				end
				return true
			end
		end
		
		local function addIslandButton(i, id)
			local island = m.islands[id]
			local corp = m.corps[island.corp]
			local col = (i) % portraitsPerRow
			local row = math.floor((i) / portraitsPerRow)
			
			local surface = sdl.scaled(2, sdlext.surface("img/portraits/ceo/".. corp.CEO_Image))
			local button = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:settooltip(m.corps[island.corp].Name)
				:decorate({
					DecoButton(),
					DecoAlign(-4),
					DecoSurface(surface)
				})
				:addTo(scrollarea)			
			button.draw = newDraw -- Needed for disabling when Randomize checkbox is set
			
			-- Make RST grayscale and lock the button from moving.
			if not m.unlockRst and id == "Corp_Desert" then
				local surface = ceo_rst_gray
				button
					:decorate({
						DecoFrame(),
						DecoAlign(2, -2),
						DecoSurface(surface)
					})
					:settooltip(m.corps[island.corp].Name .." is LOCKED due to final mission")
					.disabled = true
			else
				button:registerDragMove()
			end
			button.id = id
			
			islandButtons[i] = button
			
			button.startDrag = function(self, mx, my, btn)
				UiDraggable.startDrag(self, mx, my, btn)
				
				draggedElement = self
				placeholder.x = self.x
				placeholder.y = self.y
				
				local index = list_indexof(islandButtons, self)
				if index ~= nil then
					islandButtons[index] = placeholder
				end
				
				self:bringToTop()
				rearrange()
			end
			
			button.stopDrag = function(self, mx, my, btn)
				UiDraggable.stopDrag(self, mx, my, btn)
				
				local index = list_indexof(islandButtons, placeholder)
				if index ~= nil and draggedElement ~= nil then
					islandButtons[index] = draggedElement
				end
				
				placeholder:pospx(-2 * cellW, -2 * cellH)
				
				draggedElement = nil
				
				rearrange()
			end
			
			button.dragMove = function(self, mx, my)
				UiDraggable.dragMove(self, mx, my)
				
				rearrange()
			end
		end
		
		addRandomButton()
		addDefaultButton()
		
		for i = 1, #m.islandOrder do
			addIslandButton(#islandButtons + 1, m.islandOrder[i])
		end
	end)
end

return this