local chest= "minecraft:chest"
local chest2="minecraft:trapped_chest"
local stone= "minecraft:stone"
local coal=  "minecraft:coal"
local sand=  "minecraft:sand"
local gravel="minecraft:gravel"
local doCeiling=true
local findfirst=false

--do not change anything below
local tArgs={...}
local acX=0
local acY=0
local acZ=0
local acDir=0 -- 0=ahead, 1=right, 2=behind, 3=left from starting point
local sizeRight
local sizeUp
local sizeLength
local isRefueling=false
local dumpX=0 --only x coordinate, Y and Z are 0 as it should be setup
local dumpSide=true --true=up, false=down
local coalX=0
local coalSide=true
local stoneX=0
local stoneSide=true
local startX=0
local offset=0
local reportText={a="",b="",c="",d=""}
local errorText={a="",b="",c=""}
local completion=0
local prepareComplete=false
local virtualSpace={"","","","",
					"","","","",
					"","","","",
					"","","",""}

-- ### helper functions ### --
function report(...)
	local args={...}
	if #args>0 and args[0]~= nil then
		reportText={a=reportText.b,b=reportText.c,c=reportText.d,d=args[0]}
	end
	term.clear()
	term.setCursorPos(1,1)
	print("X:"..acX.." Z:"..acZ.." Y:"..acY.." dir:"..acDir
	.."\nFuel: "..turtle.getFuelLevel()
	.."\ndistance from spawn: "..getDistanceFromSpawn()
	.."\ncompletion status: "..completion.."%"
	.."\n\n"..reportText.a
	.."\n"..reportText.b
	.."\n"..reportText.c
	.."\n"..reportText.d)
	if errorText.a~="" then
		print("last Errors:"
		.."\n"..errorText.a
		.."\n"..errorText.b
		.."\n"..errorText.c)
	end
end
function reportError(text)
	errorText={a=errorText.b,b=errorText.c,c=text}
	report()
end

function compareItem(name)
	if turtle.getItemCount()==0 then
		return false
	end
	local data=turtle.getItemDetail()
	if data.name==name then
		return true
	else
		return false
	end
end
function compareBlockDown(block)
	local ok,data=turtle.inspectDown()
	if ok then
		if data.name==block then
			return true
		end
	end
	return false
end
function compareBlockUp(block)
	local ok,data=turtle.inspectUp()
	if ok then
		return data.name==block
	end
	return false
end
function compareBlock(block)
	local ok,data=turtle.inspect()
	if ok then
		return data.name==block
	end
	return false
end
function isChestAbove()
	return (compareBlockUp(chest) or compareBlockUp(chest2))
end
function isChestBelow()
	return (compareBlockDown(chest) or compareBlockDown(chest2))
end

function getXpos(item)
	if item==coal then
		report("need pos of coal deposit "..coalX)
		return coalX
	elseif item==stone then
		report("need pos of stone deposit "..stoneX)
		return stoneX
	else
		report("need pos of block dump "..dumpX)
		return dumpX
	end
end
function getUpChest(item)
	if item==coal then
		return coalSide
	elseif item==stone then
		return stoneSide
	else
		return dumpSide
	end
end

function select(name) -- selects the next slot with at least one in it, also full stacks; returns false if nothing found
	--print("selecting slot with "..name)
	local old=turtle.getSelectedSlot()
	for i=1,16 do
		turtle.select(i)
		if (turtle.getItemCount() > 0) and compareItem(name) then
			--print("found at "..i)
			return true
		end
	end
	turtle.select(old)
	--report("no items found")
	return false
end
function selectB(name) -- selects the next not full stack or free slot; returns false if no free space left and no not-full stacks found
	for i=1,16 do
		turtle.select(i)
		if (turtle.getItemCount() > 0) and (turtle.getItemCount() < 64) and compareItem(name) then
			--print("found at "..i)
			return true
		end
	end
	return selectFreeSlot()
end
function selectFreeSlot()
	--print("selecting next free slot")
	for i=1,16 do
		if turtle.getItemCount(i) == 0 then
			turtle.select(i)
			return true
		end
	end
	return false
end
function checkFreeSpace(block)
	for i=1,16 do
		if virtualSpace[i][2] == "" or (virtualSpace[i][1]==block and virtualSpace[i][2]<64) then
			return true
		end
	end
	return false
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
		if compareItem(coal) then
			report("coal "..acX)
			coalX=acX
			coalSide=true
		elseif compareItem(stone) then
			report("stone "..acX)
			stoneX=acX
			stoneSide=true
		else
			report("dump "..acX)
			dumpX=acX
			dumpSide=true
			report("unknown=>dump")
		end
		turtle.dropUp(1)
	else
		report("dump "..acX)
		dumpX=acX
		dumpSide=true
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
		if compareItem(coal) then
			report("coal "..acX)
			coalX=acX
			coalSide=false
		elseif compareItem(stone) then
			report("stone "..acX)
			stoneX=acX
			stoneSide=false
		else
			report("dump "..acX)
			dumpX=acX
			dumpSide=false
			report("unknown")
		end
		turtle.dropDown(1)
	else
		report("dump "..acX)
		dumpX=acX
		dumpSide=false
	end
end
-- unloading and refuel
function unloadBlocks() -- will save position and return to it at the end
	report("unloading blocks")
	local lastpos={x=acX,y=acY,z=acZ,dir=acDir}
	goto(startX,0,0)
	while select(coal) do
		if turtle.getFuelLevel() < getDistanceFromSpawn(lastX)*40+1500 then
			turtle.refuel()
			removeFromVirtual(turtle.getSelectedSlot())
		else
			goto(coalX,0,0)
			if getUpChest(coal) then
				removeFromVirtual(i)
				turtle.dropUp()
			else
				removeFromVirtual(i)
				turtle.dropDown()
			end
		end
	end
	goto(dumpX,0,0)
	local c1=0
	local c2=0
	--if select(coal) then
	--	c1=turtle.getSelectedSlot()
	--end
	if select(stone) then
		c2=turtle.getSelectedSlot()
	end
	if getUpChest("dump") then
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				removeFromVirtual(i)
				turtle.dropUp()
			end
		end
	else
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				removeFromVirtual(i)
				turtle.dropDown()
			end
		end
	end
	goto(startX,0,0)
	gotoB(lastpos)
end
function refuelBlocks(item,quant) -- will save position and return to it at the end
	report("refuling "..quant.." of "..item)
	isRefueling=true
	local lastpos={x=acX,y=acY,z=acZ,dir=acDir}
	goto(startX,0,0)
	unloadBlocks()
	if quant > 64 then
		refuelBlocks(item,quant-64)
	end
	local x=getXpos(item)
	goto(x,0,0)
	--todo:get blocks
	if getUpChest(item) then
		selectB(item)
		if turtle.suckUp(quant) then
			addToVirtual(item,quant)
		else
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckUp(1) then
					read()
				end
				addToVirtual(item)
			end
		end
	else
		if turtle.suckDown(quant) then
			addToVirtual(item,quant)
		else
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckDown(1) then
					read()
				end
				addToVirtual(item)
			end
		end
	end
	if item==coal then
		select(coal)
		turtle.refuel()
		removeFromVirtual(turtle.getSelectedSlot())
	end
	report("refuel complete, returning")
	isRefueling=false
	goto(startX,0,0)
	gotoB(lastpos)
end
function checkFuel()
	--report("checking fuelstate")
	if turtle.getFuelLevel() < getDistanceFromSpawn()*90+50 then
		if select(coal) then
			turtle.refuel()
			removeFromVirtual(turtle.getSelectedSlot())
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
function addToVirtual(...) -- block,[count]
	local args={...}
	if #args<2 then
		reportError("codeErr: not enough arguments for addToVirtual")
		read()
	end
	local block=args[2]
	local i=turtle.getSelectedSlot()
	if #args==2 then
		if virtualSpace[i]=="" then
			virtualSpace[i]={block,args[2]}
		else
			virtualSpace[i]={block,virtualSpace[i][2]+args[2]}
		end
	else
		if virtualSpace[i]=="" then
			virtualSpace[i]={block,1}
		else
			virtualSpace[i]={block,virtualSpace[i][2]+1}
		end
	end
end
function removeFromVirtual(...) --slot,[count]
	local args={...}
	if #args<1 then
		reportError("codeErr: not enough arguments for removeFromVirtual")
		return
	end
	local slot=args[1]
	if #args==2 then
		if virtualSpace[slot][2]==1 then
			virtualSpace[slot]=""
		else
			virtualSpace[slot][2]=virtualSpace[slot][2]-args[2]
		end
	else
		virtualSpace[slot]=""
	end
end


-- ### movement ### --
function getDistanceFromSpawn()
	return math.abs(acX)+math.abs(acY)+math.abs(acZ)
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
	if acDir==0 then --same direction as original
		acX=acX+1
	elseif acDir==1 then --right of original
		acZ=acZ+1
	elseif acDir==2 then --behind original
		acX=acX-1
	else --lastdir==3 --left of original
		acZ=acZ-1
	end
	report()
	if prepareComplete and not isRefueling then
		checkFuel()
	end
end
function back()
	if turtle.back() then
		if acDir==0 then --same direction as original
			acX=acX-1
		elseif acDir==1 then --right of original
			acZ=acZ-1
		elseif acDir==2 then --behind original
			acX=acX+1
		else --lastdir==3 --left of original
			acZ=acZ+1
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
	if x<startX then
		reportError("some weired shit happened")
		read()
	end
	for i=0,50 do
		if turtle.up() then
			--print("moved up")
			acY=acY+1
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
	if x<startX then
		reportError("some weired shit happened")
		read()
	end
	for i=0,50 do
		if turtle.down() then
			--print("moved down")
			acY=acY-1
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
	if acDir-dir==1 or acDir-(dir-4)==1 then
		turnL()
	end
	while acDir~=dir do
		turnR()
	end
end
function turnL()
	if turtle.turnLeft() then
		if acDir==0 then
			acDir=3
		else
			acDir=acDir-1
		end
	end
	report()
end
function turnR()
	if turtle.turnRight() then
		if acDir==3 then
			acDir=0
		else
			acDir=acDir+1
		end
	end
	report()
end
--dig and remember stuff in virtual inventory
function dig()
	if not checkFreeSpace(getBlock()) then
		unloadBlocks()
	end
	if turtle.detect() and selectB(block) then
		if not addToVirtual(getBlock()) then
			return false
		end
		turtle.dig()
		return true
	end
	return false
end
function digUp()
	if not checkFreeSpace(getBlockUp()) then
		unloadBlocks()
	end
	if turtle.detectUp() and selectB(block) then
		if not addToVirtual(getBlockUp()) then
			return false
		end
		turtle.digUp()
		return true
	end
	return false
end
function digDown()
	if not checkFreeSpace(getBlockDown()) then
		unloadBlocks()
	end
	if turtle.detectDown() and selectB(block) then
		if not addToVirtual(getBlockDown()) then
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
	lastX=acX
	lastY=acY
	lastZ=acZ
	lastDir=acDir
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
	while acZ<pos.z do
		turn(1)
		fwd()
	end
	while acZ>pos.z do
		turn(3)
		fwd()
	end
	while acY>pos.y do
		down()
	end
	while acY<pos.y do
		up()
	end
	while acX<pos.x do
		turn(0)
		fwd()
	end
	while acX>pos.x do
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
	while acX<pos.x do
		turn(0)
		fwd()
	end
	while acX>pos.x do
		turn(2)
		fwd()
	end
	while acY>pos.y do
		down()
	end
	while acY<pos.y do
		up()
	end
	while acZ<pos.z do
		turn(1)
		fwd()
	end
	while acZ>pos.z do
		turn(3)
		fwd()
	end
	if #pos==4 then
		turn(pos.dir)
	end
end
function reset()
	goto(startX,0,0)
	unloadBlocks()
	goto(0,0,0,0)
end
function repos()
	report("repositioning")
	while acY>0 do
		down()
	end
	while acZ>0 do
		turn(3)
		fwd()
	end
	while acZ<0 do
		turn(1)
		fwd()
	end
	turn(0)
end


-- ### program specific parts ### --
function wallup()
	fwd()
	local i=0
	while acY<sizeUp-1 do
		if compareBlockUp(stone) then
			break
		end
		i=i+1
		up()
	end
	while i>0 do
		down()
		i=i-1
		if select(stone) then
			while not turtle.placeUp() do
				digUp()
			end
		else
			refuelBlocks(stone,64)
			turtle.placeUp()
		end
	end
	back()
	if select(stone) then
		turtle.place()
	else
		refuelBlocks(stone,64)
		turtle.place()
	end
end
function tryPlaceWall()
	if acZ==0 and acDir==3 then
		placeStoneIfSolid()
	elseif acZ==(sizeRight-1) and acDir==1 then
		placeStoneIfSolid()
	end
end
function placeLayer()
	-- lay bottom layer with stone
	if acY==0 and prepareComplete then
		if not compareBlockDown(stone) then
			digDown()
		end
		if select(stone) then
			turtle.placeDown()
		else
			refuelBlocks(stone,64)
			turtle.placeDown()
		end
	end
	if acY==(sizeUp-1) then
		if not compareBlockUp(stone) then
			up()
			down()
		end
		if select(stone) then
			turtle.placeUp()
		else
			refuelBlocks(stone,64)
			turtle.placeUp()
		end
	end
end
function placeStoneIfSolid()
	if not compareBlock(stone) and turtle.detect() then
		fwd()
		back()
		if select(stone) then
			turtle.place()
		else
			refuelBlocks(stone,64)
			turtle.place()
		end
	end
end

function prepare()
	-- registring already present items
	for i=1,16 do
		turtle.select(i)
		if turtle.getItemCount() >0 then
			virtualSpace[i]={getItem(),turtle.getItemCount()}
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
	
	startX=acX
	prepareComplete=true
	goto((offset+startX),0,0)
	-- if specified (e.g. digtunnel 1 2 3 f) then search for the first block to start digging
	if findfirst then
		while not turtle.detect() do
			fwd()
		end
		if acX>startX then
			back()
		end
	end
end
function digtunnel()
	turtle.select(1)
	repos()
	fwd()
	placeLayer()
	turnL()
	while acY<(sizeUp-1) do
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
	
		if acZ==0 or acZ==1 then
			turn(1)
		end
		
		if acZ==(sizeRight-1) then
			while acDir~=3 do
				tryPlaceWall()
				turnR()
			end
		end
		if acY==sizeUp-1 then
			fwd()
		end
		placeLayer()
		for w=1,sizeRight-2 do
			fwd()
			placeLayer()
		end
		tryPlaceWall()
		if acY>0 then
			if not (acZ==1 and acY==1) then
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
	print("Wellcome to the dig-master 5000!")
	if #tArgs > 0 then
		if tArgs[1]=="o" then
		--todo: use obsidian as borders for tunnel
		elseif tArgs[1]=="c" then
		--todo: custom pathing
		else
			if #tArgs > 3 then
				if tArgs[4]=="f" then
					findfirst=true
				else
					offset=tArgs[4]
				end
			end
			sizeRight=tArgs[1]
			sizeUp=tArgs[2]
			sizeLength=tArgs[3]
			print("\nwidth= "..sizeRight)
			print("height= "..sizeUp)
			print("length= "..sizeLength.."\n")
		end
	else
		term.write("How wide (right side of turtule)\n is the tunnel?")
		sizeRight=read()
		term.write("How high is the tunnel?")
		sizeUp=read()
		term.write("How far should the tunnel reach? ")
		sizeLength=read()
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
	while acX<(startX+sizeLength) do
		digtunnel()
		completion=(math.floor((acX-startX)/sizeLength*100))
		report()
	end
	reset()
	report("End of Program")
end

main()