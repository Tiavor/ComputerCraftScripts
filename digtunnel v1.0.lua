local chest= "minecraft:chest"
local chest2="minecraft:trapped_chest"
local stone= "minecraft:stone"
local coal=  "minecraft:coal"
local sand=  "minecraft:sand"
local gravel="minecraft:gravel"
local slots={coal=1,cobble=2}

--do not change anything below
local tArgs={...}
local lastX=0
local lastY=0
local lastZ=0
local lastDir=0
local acX=0
local acY=0
local acZ=0
local acDir=0 -- 0=ahead, 1=right, 2=behind, 3=left from starting point
local sizeRight
local sizeUp
local sizeLength
local isRefuling=false
local dumpX=0 --only x coordinate, Y and Z are 0 as it should be setup
local dumpSide=true --true=up, false=down
local coalX=0
local coalSide=true
local stoneX=0
local stoneSide=true
local startX=0
local offset=0
local findfirst=false
local reportText={a="",b="",c="",d=""}
local errorText={a="",b="",c=""}
local completion=0
local prepareComplete=false
local doCeiling=true

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

function select(name)
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
function checkFreeSpace()
	for i=1,16 do
		if turtle.getItemCount(i) == 0 then
			return true
		end
	end
	return false
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

function unloadBlocks()
	report("unloading blocks")
	savePos()
	goto(startX,0,0)
	while select(coal) do
		if turtle.getItemCount() >16 then
			goto(coalX,0,0)
			if getUpChest(coal) then
				turtle.dropUp()
			else
				turtle.dropDown()
			end
		else
			break
		end
	end
	goto(dumpX,0,0)
	local c1=0
	local c2=0
	if select(coal) then
		c1=turtle.getSelectedSlot()
	end
	if select(stone) then
		c2=turtle.getSelectedSlot()
	end
	if getUpChest("dump") then
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				turtle.dropUp()
			end
		end
	else
		for i=1,16 do
			if i~=c1 and i~=c2 then
				turtle.select(i)
				turtle.dropDown()
			end
		end
	end
	goto(startX,0,0)
	gotoB(lastX,lastY,lastZ,lastDir)
end
function refuelBlocks(item,quant)
	report("refuling "..quant.." of "..item)
	savePos()
	local x=getXpos(item)
	goto(x,0,0)
	--todo:get blocks
	if getUpChest(item) then
		if not turtle.suckUp(quant) then
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckUp(1) and i<=16 then
					reset()
					read()
				end
			end
		end
	else
		if not turtle.suckDown(quant) then
			reportError("need more supply of "..item)
			for i=1,quant do
				if not turtle.suckDown(1) and i<=16 then
					reset()
					read()
				end
			end
			-- end program, no fuel
		end
	end
	report("refuel complete, returning")
	isRefuling=false
	goto(startX,0,0)
	gotoB(lastX,lastY,lastZ,lastDir)
end

-- ### movement and fuel ### --
function getDistanceFromSpawn()
	return math.abs(acX)+math.abs(acY)+math.abs(acZ)
end

function fwd()
	for i=0,20 do
		if turtle.forward() then
			--print("moved forward")
			break
		end
		if prepareComplete and not turtle.dig() then
			checkFuel()
			turtle.attack()
		end
		if i==20 then
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
	if prepareComplete and not isRefuling then
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
	for i=0,20 do
		if turtle.up() then
			--print("moved up")
			acY=acY+1
			report()
			return
		end
		report("can't move up, try to dig up")
		if not turtle.digUp() then
			reportError("digging up didn't help, checking fuel")
			checkFuel()
		end
	end
	reportError("can't move up")
	read()
end
function down()
	for i=0,20 do
		if turtle.down() then
			--print("moved down")
			acY=acY-1
			report()
			return
		end
		report("can't move down, try to dig down")
		if not turtle.digDown() then
			reportError("digging down didn't help, checking fuel,")
			checkFuel()
		end
	end
	reportError("can't move down")
	read()
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

--goto position--
function savePos()
	report("saving positions")
	lastX=acX
	lastY=acY
	lastZ=acZ
	lastDir=acDir
end
function goto(...) -- goto xpos,ypos,zpos[,dir] -> y,z,x
	local Args={...}
	local xpos=Args[1]
	local ypos=Args[2]
	local zpos=Args[3]
	while acY>ypos do
		down()
	end
	while acY<ypos do
		up()
	end
	while acZ<zpos do
		while acDir~=1 do
			turnR()
		end
		fwd()
	end
	while acZ>zpos do
		while acDir~=3 do
			turnR()
		end
		fwd()
	end
	while acX<xpos do
		while acDir~=0 do
			turnR()
		end
		fwd()
	end
	while acX>xpos do
		while acDir~=2 do
			turnR()
		end
		fwd()
	end
	if #Args>3 then
		dir=Args[4]
		while acDir~=dir do
			turnR()
		end
	end
end
function gotoB(...) -- reverse goto -> x,z,y
	local Args={...}
	local xpos=Args[1]
	local ypos=Args[2]
	local zpos=Args[3]
	while acX<xpos do
		while acDir~=0 do
			turnR()
		end
		fwd()
	end
	while acX>xpos do
		while acDir~=2 do
			turnR()
		end
		fwd()
	end
	while acZ<zpos do
		while acDir~=1 do
			turnR()
		end
		fwd()
	end
	while acZ>zpos do
		while acDir~=3 do
			turnR()
		end
		fwd()
	end
	while acY>ypos do
		down()
	end
	while acY<ypos do
		up()
	end
	if #Args>3 then
		dir=Args[4]
		while acDir~=dir do
			turnR()
		end
	end
end
function reset()
	goto(0,0,0,0)
end
function repos()
	report("repositioning")
	while acY>0 do
		down()
	end
	while acZ>0 do
		while acDir~=3 do
			turnR()
		end
		fwd()
	end
	while acZ<0 do
		while acDir~=1 do
			turnR()
		end
		fwd()
	end
	while acDir~=0 do
		turnR()
	end
end

--check fuel state--
function checkFuel()
	--report("checking fuelstate")
	if turtle.getFuelLevel() < getDistanceFromSpawn()+100 then
		if select(coal) then
			turtle.refuel()
			if turtle.getItemCount() <5 and not isRefuling then
				getCoal()
			end
		else
			if not isRefuling then
				getCoal()
			end
		end
	end
	if turtle.getFuelLevel()==0 then
		reportError("out of fuel")
		read()
	end
end
function getCoal()
	if not isRefuling then
		isRefuling=true;
		report("starting with refueling coal")
		if select(coal) then
			report("coal found but not much left")
			refuelBlocks(coal,turtle.getItemSpace())
		else
			report("no coal found")
			refuelBlocks(coal,64)
		end
	end
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
				turtle.digUp()
			end
		else
			refuelBlocks(stone,64)
			if select(stone) then
				while not turtle.placeUp() do
					turtle.digUp()
				end
			else
				report("can't place blocks after refuel somehow")
				read()
			end
		end
	end
	back()
	if select(stone) then
		turtle.place()
	else
		refuelBlocks(stone,64)
		if select(stone) then
			turtle.place()
		else
			report("can't place blocks after refuel somehow")
			read()
		end
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
	if acY==0 then
		if not compareBlockDown(stone) then
			turtle.digDown()
		end
		if select(stone) then
			turtle.placeDown()
		else
			refuelBlocks(stone,64)
			if select(stone) then
				turtle.placeDown()
			else
			report("can't place blocks after refuel somehow")
			read()
			--nothing changed, end of programm, some error
			end
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
			if select(stone) then
				turtle.placeUp()
			else
			reportError("can't place blocks after refuel somehow")
			read()
			--nothing changed, end of programm, some error
			end
		end
	end
end
function placeStoneIfSolid()
	if not compareBlock(stone) and turtle.detect() then
		fwd()
		back()
		if select(stone) and (turtle.getItemCount() > 2) then
			turtle.place()
		else
			if select(stone) then
				refuelBlocks(stone,turtle.getItemSpace())
			else
				refuelBlocks(stone,64)
				
				if select(stone) and (turtle.getItemCount() > 2) then
					turtle.place()
				else
					reportError("can't place blocks after refuel somehow")
					read()
					--nothing changed, end of programm, some error
				end
			end
		end
	end
end

function prepare()
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
	if findfirst then
		while not turtle.detect() do
			fwd()
		end
	end
end
function dig()
	if not checkFreeSpace() then
		unloadBlocks()
	end
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
			while acDir~=1 do
				turnR()
			end
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
		dig()
		completion=(math.floor((acX-startX)/sizeLength*100))
		report()
	end
	goto(startX,0,0)
	unloadBlocks()
	goto(0,0,0,0)
	report("End of Program")
end

main()