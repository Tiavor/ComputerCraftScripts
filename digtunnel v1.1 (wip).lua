local ref={	chest= "minecraft:chest",
			chest2="minecraft:trapped_chest",
			stone= "minecraft:stone",
			coal=  "minecraft:coal",
			sand=  "minecraft:sand",
			gravel="minecraft:gravel"}
local doCeiling=true
local findfirst=false
local buildTunnel=false

-- priorities: 	-1 = do not use this block
-- 				0-3 places blocks with higher number first (per row)
local blockProperties={["minecraft:sapling"]={priority=0,placeDefault},
				["minecraft:bedrock"]={priority=-1},
				["minecraft:flowing_water"]={priority=-1},
				["minecraft:water"]={priority=0,placeWater},
				["minecraft:flowing_lava"]={priority=-1},
				["minecraft:lava"]={priority=0,placeWater},
				["minecraft:log"]={priority=1,placeWithRot},
				["minecraft:leaves"]={priority=0,placeDefault},
				["minecraft:tallgrass"]={priority=0,placeDefault},
				["minecraft:deadbush"]={priority=0,placeDefault},
				["minecraft:yellow_flower"]={priority=0,placeDefault},
				["minecraft:red_flower"]={priority=0,placeDefault},
				["minecraft:browen_mushroom"]={priority=0,placeDefault},
				["minecraft:red_mushroom"]={priority=0,placeDefault},
				["minecraft:lit_redstone_ore"]={priority=0,placeTorch},
				["minecraft:unlit_redstone_torch"]={priority=0,placeTorch},
				["minecraft:redstone_torch"]={priority=0,placeTorch},
				["minecraft:snow_layer"]={priority=0,placeDefault},
				["minecraft:cactus"]={priority=0,placeDefault},
				["minecraft:reeds"]={priority=0,placeDefault},
				["minecraft:pumpkin"]=placeHRot,
				["minecraft:brown_mushroom_block"]=1,
				["minecraft:red_mushroom_block"]=1,
				["minecraft:vine"]={priority=0,placeDefault},
				["minecraft:waterlily"]=-1,
				["minecraft:coca"]=-1,
				["minecraft:leaves2"]=-1,
				["minecraft:log2"]=1,
				["minecraft:double_plant"]={priority=-1},
				["minecraft:fire"]=-1,
				["minecraft:dispenser"]=2,
				["minecraft:sticky_piston"]=1,
				["minecraft:stone_slab"]=1,
				["minecraft:tnt"]={priority=-1},
				["minecraft:mob_spawner"]={priority=-1},
				["minecraft:torch"]=3,
				["minecraft:oak_stairs"]=1,
				["minecraft:chest"]=2,
				["minecraft:redstone_wire"]=-1,
				["minecraft:wheat"]=-1,
				["minecraft:furnace"]=2,
				["minecraft:wooden_door"]=placeDoor,
				["minecraft:ladder"]=-1,
				["minecraft:rail"]=-1,
				["minecraft:lever"]={priority=0,placeTorch},
				["minecraft:stone_pressure_plate"]=-1,
				["minecraft:stone_button"]={priority=0,placeTorch},
				["minecraft:fence"]=3,
				["minecraft:unpowered_repeater"]=placeRedstone,
				["minecraft:sandstone_stairs"]=placeStairs,
				["minecraft:tripwire_hook"]=-1,
				["minecraft:portal"]={priority=-1},
				["minecraft:nether_brick_stairs"]=placeStairs,
				["minecraft:nether_wart"]=-1,
				["minecraft:end_portal"]={priority=-1},
				["minecraft:lit_redstone_lamp"]=placeSomethingelse,
				["minecraft:powered_repeater"]=placeSomethingelse,
				["minecraft:ender_chest"]={priority=-1},
				["minecraft:tripwire"]=-1,
				["minecraft:spruce_stairs"]=placeStairs,
				["minecraft:birch_stairs"]=placeStairs,
				["minecraft:jungle_stairs"]=placeStairs,
				["minecraft:bed"]=placeBed,
				["minecraft:golden_rail"]=placeRedstone,
				["minecraft:detector_rail"]=placeRedstone,
				["minecraft:piston_head"]={priority=-1},
				["minecraft:piston_extension"]={priority=-1},
				["minecraft:double_stone_slab"]=placeDoubleslab,
				["minecraft:standing_sign"]]=placeStandingSign,
				["minecraft:lit_furnace"]=placeSomethingelse,
				["minecraft:iron_door"]=placeDoor,
				["minecraft:wall_sign"]=placeWallsign,
				["minecraft:wooden_button"]=placeTorch,
				["minecraft:skull"]=placeSkull,
				["minecraft:anvil"]=placeLast,
				["minecraft:trapped_chest"]=2,
				["minecraft:unpowered_comparator"]=3,
				["minecraft:powered_comparator"]=3,
				["minecraft:hopper"]=3,
				["minecraft:activator_rail"]=placeRedstone,
				["minecraft:dropper"]=2,
				["minecraft:wall_banner"]=3,
				["minecraft:standing_banner"]=3,
				["minecraft:spruce_fence_gate"]=3,
				["minecraft:birch_fence_gate"]=3,
				["minecraft:jungle_fence_gate"]=3,
				["minecraft:dark_oak_fence_gate"]=3,
				["minecraft:acacia_fence_gate"]=3,
				["minecraft:spruce_door"]=3,
				["minecraft:birch_door"]=3,
				["minecraft:jungle_door"]]=3,
				["minecraft:acacia_door"]]=3,
				["minecraft:dark_oak_door"]]=3,
				["minecraft:quarz_stairs"]=3,
				["minecraft:quartz_block"]]=3,
				["minecraft:light_weighted_pressure_plate"]=-1,
				["minecraft:heavy_weighted_pressure_plate"]=-1}

--do not change anything below
local tArgs={...}
local relCo={acX=0,acY=0,acZ=0,acDir=0} -- 0=ahead, 1=right, 2=behind, 3=left from starting point
local absCo={acX=0,acY=0,acZ=0,acDir=0}
local size={right,up,length}
local startPar -- ={coal={x=1,up=true}}
--local startPar={dump=0,coal=0,stone=0,start=0} -- only x coordinate, Y and Z are 0 as it should be setup
--local startParS={coal=true,stone=true,dump=true}--true=up, false=down
local offset=0
local reportText={"","","",""}
local errorText={"","",""}
local completion=0
local isRefueling=false
local prepareComplete=false
local virtualInventory={"","","","", "","","","", "","","","", "","","",""}
local virtualTemplate --  [[[[blockname,rotation,data],nextblock_Z,...],nextline_Y,...],nextrow_X,...] built in order x->X(y->Y(z->Z))
local templateSize={x=0,y=0,z=0}
local template
--  3:place 1st, special treatment
--  2:place 2nd, with horizontal rotation, e.g. chest, furnace; not pushable
--  1:place 3rd, with rotation and pushable; use pistons
--  0:place 4th, normal block, place from next row, no rotation
-- -1:place 5th, no rotation but depend on other blocks, e.g. leaves, flowers
-- -2:do not use these blocks

-- ### helper functions ### --
function report(...)
	local args={...}
	if #args>0 and args[0]~= nil then
		reportText={reportText[2],reportText[3],reportText[4],args[0]}
	end
	term.clear()
	term.setCursorPos(1,1)
	print("X:"..relCo.acX.." Z:"..relCo.acZ.." Y:"..relCo.acY.." dir:"..relCo.acDir
	.."\nFuel: "..turtle.getFuelLevel()
	.."\ndistance from spawn: "..getDistanceFromSpawn()
	.."\ncompletion status: "..completion.."%"
	.."\n"..reportText[4])
	if errorText[3]~="" then
		print("last Error:"
		.."\n"..errorText[3])
	end
	for i=1,4 do
		term.write(virtualInventory[i])
	end
end
function reportError(text)
	errorText={errorText[2],errorText[3],text}
	report()
end

function compareItem(name)
	if turtle.getItemCount()==0 then
		return false
	end
	local data=turtle.getItemDetail()
	return data.name==name
end
function compareBlockDown(name)
	local ok,data=turtle.inspectDown()
	if ok then
		return data.name==name
	end
	return false
end
function compareBlockUp(name)
	local ok,data=turtle.inspectUp()
	if ok then
		return data.name==name
	end
	return false
end
function compareBlock(name)
	local ok,data=turtle.inspect()
	if ok then
		return data.name==name
	end
	return false
end
function isChestAbove()
	return (compareBlockUp(ref.chest) or compareBlockUp(ref.chest2))
end
function isChestBelow()
	return (compareBlockDown(ref.chest) or compareBlockDown(ref.chest2))
end

function getXpos(item)
	if startPar[item] ~= nil then
		return startPar[item].x
	end
	if item==ref.coal then
		report("need pos of coal deposit "..startPar.coal)
		return startPar.coal
	elseif item==ref.stone then
		report("need pos of stone deposit "..startPar.stone)
		return startPar.stone
	else
		report("need pos of block dump "..startPar.dump)
		return startPar.dump
	end
end
function getUpChest(item)
	if item==coal then
		return startParS.coal
	elseif item==stone then
		return startParS.stone
	else
		return startParS.dump
	end
end

function select(name) -- selects the next slot with at least one in it, also full stacks; returns false if nothing found
	for i=1,16 do
		if virtualInventory[i] ~="" and virtualInventory[i][1]==block then
			turtle.select(i)
			return true
		end
	end
	return false
end
function selectB(name) -- selects the next not full stack or free slot after all slots are checked; returns false if no free space left and no not-full stacks found
	for i=1,16 do
		if virtualInventory[i] ~="" and virtualInventory[i][1]==block and virtualInventory[i][2]<64 then
			turtle.select(i)
			return true
		end
	end
	return selectFreeSlot()
end
function selectFreeSlot()
	--print("selecting next free slot")
	for i=1,16 do
		if virtualInventory[i] == "" then
			turtle.select(i)
			return true
		end
	end
	return false
end

function shortName(name)
	return string.sub(name,11)
end
function getItem(...) -- [slot] ; may return nil, check if there is an item in the selected or specified slot
	args={...}
	local slot=turtle.getSelectedSlot()
	if #args==1 then
		slot=args[1]
	end
	if turtle.getItemCount()>0 then
		local data=turtle.getItemDetail()
		return data.name
	end
	return nil
end
function getBlock()     --may return nil, use turtle.detetct() first
	local ok,data=turtle.inspect()
	if ok then
		return data.name
	end
	return nil
end
function getBlockUp()   --may return nil, use turtle.detetct() first
	local ok,data=turtle.inspectUp()
	if ok then
		return data.name
	end
	return nil
end
function getBlockDown() --may return nil, use turtle.detetct() first
	local ok,data=turtle.inspectDown()
	if ok then
		return data.name
	end
	return nil
end

function registerChestUp()
	report("registring the chest above with ")
	if not selectFreeSlot() then
		report("not enough free space to start")
		goto(0,0,0)
		read()
		--endProgram no free slot
	end
	if turtle.suckUp(1) then
		local item=getItem()
		if item==nil then
			reportError("got Item from chest but nothing was found in Inventory")
			read()
		end
		report(item..relCo.acX)
		startPar[item]={x=relCo.acX,up=true}
		turtle.dropUp(1)
		if item==ref.coal and turtle.getFuelLevel() <3000 then
			turtle.suckUp(64)
			turtle.refuel()
		end
	else
		report("dump "..relCo.acX)
		startPar.dump=relCo.acX
		startParS.dump=true
		local n=getNextFromInv()
		while n~=false do
			if n~=false then
				turtle.select(n)
				turtle.dropUp()
				remFromInv()
			end
			n=getNextFromInv()
		end
	end
end
function registerChestDown()
	report("registring the chest below with ")
	if not selectFreeSlot() then
		report("not enough free space to start")
		read()
		--endProgram no free slot
	end
	if turtle.suckDown(1) then
		local item=getItem()
		if item==nil then
			reportError("got Item from chest but nothing was found in Inventory")
			read()
		end
		report(item..relCo.acX)
		startPar[item]={x=relCo.acX,up=false}
		turtle.dropDown(1)
		if item==ref.coal and turtle.getFuelLevel() <3000 then
			turtle.suckDown(64)
			turtle.refuel()
		end
	else
		report("dump "..relCo.acX)
		startPar.dump=relCo.acX
		startParS.dump=false
		local n=getNextFromInv()
		while n~=false do
			if n~=false then
				turtle.select(n)
				turtle.dropDown()
				remFromInv()
			end
			n=getNextFromInv()
		end
	end
end
-- unloading and refuel
function unloadBlocks() -- will save position and return to it at the end
	report("unloading blocks")
	local lastpos={x=relCo.acX,y=relCo.acY,z=relCo.acZ,dir=relCo.acDir}
	goto(startPar.start,0,0)
	while select(ref.coal) do
		if turtle.getFuelLevel() < getDistanceFromSpawn(lastX)*40+1500 then
			turtle.refuel()
			remFromInv(turtle.getSelectedSlot())
		else
			goto(startPar[ref.coal].x,0,0)
			if getUpChest(ref.coal) then
				remFromInv(i)
				turtle.dropUp()
			else
				remFromInv(i)
				turtle.dropDown()
			end
		end
	end
	goto(startPar.dump,0,0)
	local c1=0
	local c2=0
	--if select(coal) then
	--	c1=turtle.getSelectedSlot()
	--end
	if select(ref.stone) then
		c2=turtle.getSelectedSlot()
	end
	if getUpChest("dump") then
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				remFromInv(i)
				turtle.dropUp()
			end
		end
	else
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				remFromInv(i)
				turtle.dropDown()
			end
		end
	end
	goto(startPar.start,0,0)
	gotoB(lastpos)
end
function refuelBlocks(...) -- will save position and return to it at the end
	local item=args[1]
	local quant=args[2]
	local isSubRefuel=false
	if #args==3 then
		isSubRefuel=args[3]
	end
	report("refuling "..quant.." of "..item)
	local lastpos={x=relCo.acX,y=relCo.acY,z=relCo.acZ,dir=relCo.acDir}
	if not isSubRefuel then
		isRefueling=true
		goto(startPar.start,0,0)
		unloadBlocks()
	end
	if quant > 64 then
		refuelBlocks(item,quant-64,true)
		quant=64
	end
	local x=getXpos(item)
	goto(x,0,0)
	--todo:get blocks
	if getUpChest(item) then
		selectB(item)
		if turtle.suckUp(quant) then
			addToInv(item,quant)
		else
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckUp(1) then
					read()
				end
				addToInv(item)
			end
		end
	else
		if turtle.suckDown(quant) then
			addToInv(item,quant)
		else
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckDown(1) then
					read()
				end
				addToInv(item)
			end
		end
	end
	if item==coal then
		select(coal)
		turtle.refuel()
		remFromInv(turtle.getSelectedSlot())
	end
	if not isSubRefuel then
		report("refuel complete, returning")
		isRefueling=false
		goto(startPar.start,0,0)
		gotoB(lastpos)
	end
end
function checkFuel()
	--report("checking fuelstate")
	if turtle.getFuelLevel() < getDistanceFromSpawn()*90+50 then
		if select(coal) then
			turtle.refuel()
			remFromInv(turtle.getSelectedSlot())
		else
			refuelBlocks(coal,math.floor(getDistanceFromSpawn()/40)+32)
		end
	end
	if turtle.getFuelLevel()==0 then
		reportError("out of fuel")
		read()
	end
end
-- virtual inventory
function addToInv(...) -- block,[count]
	local args={...}
	if #args<1 then
		reportError("codeErr: not enough arguments for addToInv")
		read()
	end
	local block=args[2]
	local i=turtle.getSelectedSlot()
	if #args==2 then
		if virtualInventory[i]=="" then
			virtualInventory[i]={block,args[2]}
			return true
		else
			virtualInventory[i]={block,virtualInventory[i][2]+args[2]}
			return true
		end
	else
		if virtualInventory[i]=="" then
			virtualInventory[i]={block,1}
			return true
		else
			virtualInventory[i]={block,virtualInventory[i][2]+1}
			return true
		end
	end
	return false
end
function remFromInv(...) --slot,[count]
	local args={...}
	if #args==2 then
		local slot=args[1]
		local count=virtualInventory[slot][2]
		if count==args[2] then
			virtualInventory[slot]=""
			return true
		elseif count>args[2]
			virtualInventory[slot][2]=virtualInventory[slot][2]-args[2]
			return true
		end
	elseif #args==1 then
		local slot=args[1]
		virtualInventory[slot]=""
		return true
	elseif #args==0 then
		virtualInventory[turtle.getSelectedSlot()]=""
		return true
	end
	return false
end
function getNextFromInv(...)
	local args={...}
	if #args==0 then
		for i=1,16 do
			if virtualInventory[i]~="" then
				return i
			end
		end
	else
		for i=1,16 do
			if virtualInventory[i]~="" and virtualInventory[i][1] == args[1]
				then return i
			end
		end
	end
	return false
end
-- virtual template
function addToTemplate(t,x,y,z,r)
	
end

-- ### movement ### --
function getDistanceFromSpawn()
	return math.abs(relCo.acX)+math.abs(relCo.acY)+math.abs(relCo.acZ)
end

function fwd()
	for i=0,50 do
		if turtle.forward() then
			--print("moved forward")
			break
		end
		if prepareComplete and not dig() then
			checkFuel()
			turtle.attack()
		end
		if i==50 then
			reportError("can't move forward")
			read()
			return
		end
	end
	if relCo.acDir==0 then --same direction as original
		relCo.acX=relCo.acX+1
	elseif relCo.acDir==1 then --right of original
		relCo.acZ=relCo.acZ+1
	elseif relCo.acDir==2 then --behind original
		relCo.acX=relCo.acX-1
	else --lastdir==3 --left of original
		relCo.acZ=relCo.acZ-1
	end
	report()
	if prepareComplete and not isRefueling then
		checkFuel()
	end
end
function back()
	if turtle.back() then
		if relCo.acDir==0 then --same direction as original
			relCo.acX=relCo.acX-1
		elseif relCo.acDir==1 then --right of original
			relCo.acZ=relCo.acZ-1
		elseif relCo.acDir==2 then --behind original
			relCo.acX=relCo.acX+1
		else --lastdir==3 --left of original
			relCo.acZ=relCo.acZ+1
		end
		report()
	else
		turnL()
		turnL()
		fwd()
		turnL()
		turnL()
	end
end
function up()
	if x<startPar.start then
		reportError("some weired shit happened")
		read()
	end
	for i=0,50 do
		if turtle.up() then
			--print("moved up")
			relCo.acY=relCo.acY+1
			report()
			return
		end
		report("can't move up, try to dig up")
		if not digUp() then
			reportError("digging up didn't help, checking fuel")
			checkFuel()
		end
	end
	reportError("can't move up")
	read()
end
function down()
	if x<startPar.start then
		reportError("some weired shit happened")
		read()
	end
	for i=0,50 do
		if turtle.down() then
			--print("moved down")
			relCo.acY=relCo.acY-1
			report()
			return
		end
		report("can't move down, try to dig down")
		if not digDown() then
			reportError("digging down didn't help, checking fuel,")
			checkFuel()
		end
	end
	reportError("can't move down")
	read()
end

function turn(dir)
	if relCo.acDir-dir==1 or relCo.acDir-(dir-4)==1 then
		turnL()
	end
	while relCo.acDir~=dir do
		turnR()
	end
end
function turnL()
	if turtle.turnLeft() then
		if relCo.acDir==0 then
			relCo.acDir=3
		else
			relCo.acDir=relCo.acDir-1
		end
	end
	report()
end
function turnR()
	if turtle.turnRight() then
		if relCo.acDir==3 then
			relCo.acDir=0
		else
			relCo.acDir=relCo.acDir+1
		end
	end
	report()
end
--dig and remember stuff in virtual inventory
function dig()
	while not selectB(getBlock()) do
		unloadBlocks()
	end
	if turtle.detect() then
		if not addToInv(getBlock()) then
			return false
		end
		turtle.dig()
		return true
	end
	return false
end
function digUp()
	while not selectB(getBlockUp()) do
		unloadBlocks()
	end
	if turtle.detectUp() then
		if not addToInv(getBlockUp()) then
			return false
		end
		turtle.digUp()
		return true
	end
	return false
end
function digDown()
	while not selectB(getBlockDown()) do
		unloadBlocks()
	end
	if turtle.detectDown() then
		if not addToInv(getBlockDown()) then
			return false
		end
		turtle.digDown()
		return true
	end
	return false
end
--goto position--
function savePos()
	report("saving positions")
	lastX=relCo.acX
	lastY=relCo.acY
	lastZ=relCo.acZ
	lastDir=relCo.acDir
end
function goto(...) -- goto xpos,ypos,zpos[,dir] -> z,y,x
	local Args={...}
	if #Args<1 then
		reportError("codeErr: not enough arguments for gotoB")
	elseif #Args==1 then
		pos=Args[1]
	elseif #Args==3 then
		pos={x=Args[1],y=Args[2],z=Args[3]}
	elseif #Args==4 then
		pos={x=Args[1],y=Args[2],z=Args[3],dir=Args[4]}
	end
	while relCo.acZ<pos.z do
		turn(1)
		fwd()
	end
	while relCo.acZ>pos.z do
		turn(3)
		fwd()
	end
	while relCo.acY>pos.y do
		down()
	end
	while relCo.acY<pos.y do
		up()
	end
	while relCo.acX<pos.x do
		turn(0)
		fwd()
	end
	while relCo.acX>pos.x do
		turn(2)
		fwd()
	end
	if #pos==4 then
		turn(pos.dir)
	end
end
function gotoB(...) -- reverse goto -> x,y,z
	local Args={...}
	local pos
	if #Args<1 then
		reportError("codeErr: not enough arguments for gotoB")
	elseif #Args==1 then
		pos=Args[1]
	elseif #Args==3 then
		pos={x=Args[1],y=Args[2],z=Args[3]}
	elseif #Args==4 then
		pos={x=Args[1],y=Args[2],z=Args[3],dir=Args[4]}
	end
	while relCo.acX<pos.x do
		turn(0)
		fwd()
	end
	while relCo.acX>pos.x do
		turn(2)
		fwd()
	end
	while relCo.acY>pos.y do
		down()
	end
	while relCo.acY<pos.y do
		up()
	end
	while relCo.acZ<pos.z do
		turn(1)
		fwd()
	end
	while relCo.acZ>pos.z do
		turn(3)
		fwd()
	end
	if #pos==4 then
		turn(pos.dir)
	end
end
function reset()
	goto(startPar.start,0,0)
	unloadBlocks()
	goto(0,0,0,0)
end
function repos()
	report("repositioning")
	while relCo.acY>0 do
		down()
	end
	while relCo.acZ>0 do
		turn(3)
		fwd()
	end
	while relCo.acZ<0 do
		turn(1)
		fwd()
	end
	turn(0)
end


-- ### program specific parts ### --
--tunnel program
function wallup()
	fwd()
	local i=0
	while relCo.acY<size.up-1 do
		if compareBlockUp(ref.stone) then
			break
		end
		i=i+1
		up()
	end
	while i>0 do
		down()
		i=i-1
		if select(ref.stone) then
			while not turtle.placeUp() do
				digUp()
			end
		else
			refuelBlocks(ref.stone,64)
			turtle.placeUp()
		end
	end
	back()
	if select(ref.stone) then
		turtle.place()
	else
		refuelBlocks(ref.stone,64)
		turtle.place()
	end
end
function tryPlaceWall()
	if relCo.acZ==0 and relCo.acDir==3 then
		placeStoneIfSolid()
	elseif relCo.acZ==(size.right-1) and relCo.acDir==1 then
		placeStoneIfSolid()
	end
end
function placeLayer()
	-- lay bottom layer with stone
	if relCo.acY==0 and prepareComplete then
		if not compareBlockDown(ref.stone) then
			digDown()
		end
		if select(ref.stone) then
			turtle.placeDown()
		else
			refuelBlocks(ref.stone,64)
			turtle.placeDown()
		end
	end
	if relCo.acY==(size.up-1) then
		if not compareBlockUp(ref.stone) then
			up()
			down()
		end
		if select(ref.stone) then
			turtle.placeUp()
		else
			refuelBlocks(ref.stone,64)
			turtle.placeUp()
		end
	end
end
function placeStoneIfSolid()
	if not compareBlock(ref.stone) and turtle.detect() then
		fwd()
		back()
		if select(ref.stone) then
			turtle.place()
		else
			refuelBlocks(ref.stone,64)
			turtle.place()
		end
	end
end

--build program
function registerAir(x,y,z)

end
function placeDefault(t,x,y,z,dv)--place directly
	gotoB(x+1,y,z,2)
	if slect(t,dv)
		turtle.place()
	--else
	end
end
function placeWithRot(t,x,y,z,r)--use pistons
end
function placeHRot(t,x,y,z,r)--do not use pistons
end
function placeStairs(t,x,y,z,r)--use pistones
end
function placeTorch(t,x,y,z,r)--like redstone, needs other block; blocks placed against depend the rotation
end
function placeRedstone(t,x,y,z,r)--needs block below and has rotation
end
function placeDoor(t,x,y,z,r)--needs block below and has special rotation
end
function placeWater(t,x,y,z,r)--uses buckets
	
	if t=="minecraft:lava" then
		
	
	elseif t=="minecraft:water" then
		
	
	end
	
end
function placeDoor(t,x,y,z,r)
end
function placeSomethingelse(t,x,y,z,r)
end
function placeStandingSign(t,x,y,z,r)
end
function placeWallSign(t,x,y,z,r)
end
function placeDoubleslab(t,x,y,z,r)
end

function placeBlock(block,prio,x,y,z,r)
	local ptype=blockProperties[block]
	if ptype==nil then
		placeDefault(block,x,y,z,r)
	return true
	elseif ptype.priority==-2 then
		return false
	elseif ptype.priority==prio then
		ptype[2](block,x,y,z,r)
	return true
	end
	reportError("wrong arguments for placeBlock "..block.." "..x.." "..y.." "..z.." "..r)
	return false
end

function prepare()
	-- registring already present items
	for i=1,16 do
		turtle.select(i)
		if turtle.getItemCount() >0 then
			virtualInventory[i]={getItem(),turtle.getItemCount()}
		end
	end
	
	-- registring support and dump chests
	repeat
		fwd()
		if isChestAbove() then
			registerChestUp()
		elseif isChestBelow() then
			registerChestDown()
		end
	until (not isChestAbove()) and (not isChestBelow())
	
	if buildTunnel then -- prepare build by 
	-- searching for first indicator block
	--while getBlockDown()~=indicatorBlock do
	--	fwd()
	--end
	--for x=1,size.X do end
	end
	
	prepareComplete=true
	goto((offset+relCo.acX),0,0)
	-- if specified (e.g. digtunnel 1 2 3 f) then search for the first block to start digging
	if findfirst then
		while not turtle.detect() do
			fwd()
		end
	end
	startPar.start=relCo.acX
end
function digtunnel()
	turtle.select(1)
	repos()
	fwd()
	placeLayer()
	turnL()
	while relCo.acY<(size.up-1) do
		if turtle.detect() and (compareBlock(gravel) or compareBlock(sand))then
			wallup()
		end
		tryPlaceWall()
		up()
	end
	tryPlaceWall()
	placeLayer()
	turnR()
	
	local state=true
	while state do
	
		if relCo.acZ==0 or relCo.acZ==1 then
			turn(1)
		end
		
		if relCo.acZ==(size.right-1) then
			while relCo.acDir~=3 do
				tryPlaceWall()
				turnR()
			end
		end
		if relCo.acY==size.up-1 then
			fwd()
		end
		placeLayer()
		for w=1,size.right-2 do
			fwd()
			placeLayer()
		end
		tryPlaceWall()
		if relCo.acY>0 then
			if not (relCo.acZ==1 and relCo.acY==1) then
				down()
				tryPlaceWall()
				placeLayer()
			end
		else
			state=false
		end
	end
	repos()
end


function main()
	term.clear() 
	term.setCursorPos(1,1)
	print("Wellcome to the tunnelbuilder 5000!")
	if #tArgs > 0 then
		if tArgs[1]=="o" then
		--todo: use obsidian as borders for tunnel
		elseif tArgs[1]=="c" then
		--todo: custom pathing
		else
			if #tArgs > 1 then
				if tArgs[2]=="f" then
					findfirst=true
				else
					offset=tArgs[2]
				end
			end
			size.length=tArgs[1]
			print("length= "..size.length.."\n")
		end
	else
		term.write("How wide (right side of turtule)\n is the tunnel?")
		size.right=read()
		term.write("How high is the tunnel?")
		size.up=read()
		term.write("How far should the tunnel reach? ")
		size.length=read()
		term.write("place blocks at ceiling? y/n ")
		if read()=="y" then
			doCeiling=true
		else
			doCeiling=false
		end
	end
	while true do
		print("Enter 's' to start, 'h' for help or 'a' for abort")
		local input=read()
		if input=="s" then
			break
		elseif input =="h" then
			term.clear()
			term.setCursorPos(1,1)
			print("setup:1. the direction the turtle is facing ")
			print("         now is the digging direction")
			print("2. put chests in the same direction above and or")
			print("   below the turtle for input and dump")
			print("3. the digging begins at the first block where")
			print("   there isn't a chest below or above")
			print("4. make sure that the bot is empty and fueled")
			print("   or has at least one coal in it")
		elseif input =="a" then
			return
		end
	end
	term.clear()
	term.setCursorPos(1,1)
	report("startup ...")
	while turtle.getFuelLevel() < 10 do
		if select(coal) then
			turtle.refuel()
		else
			report("please put at least one coal inside the turtle to start")
			report("press any key to continue")
			read()
		end
	end
	term.clear()
	term.setCursorPos(1,1)
	report("preparing ...")
	prepare()
	term.clear()
	term.setCursorPos(1,1)
	report("starting with digging the tunnel")
	while relCo.acX<(startPar.start+size.length) do
		digtunnel()
		completion=(math.floor((relCo.acX-startPar.start)/size.length*100))
		report()
	end
	reset()
	report("End of Program")
end

main()