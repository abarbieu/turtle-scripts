--[[
TO USE:

PLACE CHEST BELOW AND ABOVE TURTLE
IN CHEST BELOW PUT TORCH IN FIRST SLOT
THEN PUT ITEMS YOU WANT TO DROP AFTER THAT
IN TOP CHEST PUT FUEL AND TORCHES TO USE
AFTER ITEM IDS ARE GOT DO WHAT YOU LIKE

WILL MAKE MINE BASED ON VARS BELOW
Last used 6/9/2020
--]]

local tArgs = {...}
if #tArgs ~= 2 then
    print("USAGE: mine <num shafts> <shaft length>")
    return
end
 
NUMBER_OF_SHAFTS=tonumber(tArgs[1])
SHAFT_LENGTH=tonumber(tArgs[2])

START_AT_SHAFT=1

TORCH_SPACING = 12

SHAFTS_PER_REFUEL = 2

TORCH_CYCLES = 5

N_EMPTY_TO_DROP = 4

------------------------

nToDropTo=15
nToDrop=1

fuelNeeded=0
fuelPerRefuel=0

torchesNeeded=0
torchesPerRefuel=0

torchID = nil
currNTorches=0
badItems = {}

currShaft=0

currdir = 0

--MAIN---------------------------------------------------------------

function mine(x, y)
	
	fuelNeeded= NUMBER_OF_SHAFTS*6 + 15 + (x+NUMBER_OF_SHAFTS+1)*4 + 10
	fuelPerRefuel=fuelNeeded*SHAFTS_PER_REFUEL
	torchesNeeded=fuelNeeded/TORCH_SPACING
	torchesPerRefuel=torchesNeeded*SHAFTS_PER_REFUEL
	
	if getTorchID() == nil then
		print("\n\tCOULD'T GET A TORCH ID, KMS\n")
		return
	end

	getBad()
	
	if(refuelFromChests(fuelPerRefuel) < fuelPerRefuel) then
		print("NOT ENOUGH FUEL TO GO ON")
		return
	end

	if not getTorches(torchesPerRefuel) then
		print("GIMME MORE TORCHES DICKHEAD\n")
		return
	end

	goToShaft(START_AT_SHAFT)
	for i=1, y do
		mineShaft(x+6*(currShaft-1)+1,3)
		mineShaft(x+6*(currShaft-1)+1,1)
		clearToNextShaft()
		dropAll()

		if i~=y then
			print("go home?")
			if not storeAndRefuel(i) then
				print("FAILED TO GIVE YA YOUR SHIT AND REFUEL\n")
				return
			end
		end
	end
	returnHome()
	storeItems()
end

--INITIALIZATION-----------------------------------------------------------------

function firstEmptySlot()
	for i=1, 16 do
		turtle.select(i)
		if turtle.getItemCount() == 0 then
			return i
		end
	end
	print("turtle full")
	return -1
end

function nextEmptySlot()
	for i=turtle.getSelectedSlot(), 16 do
		turtle.select(i)
		if turtle.getItemCount() == 0 then
			return i
		end
	end
	print("turtle full")
	return -1
end

function organize()
	slot=1
	print("attempting to organize this junk\n")
	for i=1, 16 do
		turtle.select(i)
		turtle.transferTo(slot)
		if turtle.getItemCount() ~= 0 then
			slot = slot +1
		end
	end
end

function getTorchID()
	torchID = getIDFromChest(5)
	if torchID == nil then
		print("WHADDUA WANT ME TO PLACE?\n\t(torch first slot bottom chest dumbass)")
		return false
	end
	dropDir(5,64)
	return true
end

function getIDFromChest(dir)
	turtle.select(firstEmptySlot())
	if not suckDir(dir,64) then
		return nil
	end
	id = turtle.getItemDetail()
	if id == nil then
		print("nil ID, the fuck\n")
		return nil	
	end
	return id.name
end

function getIDSFromChest(dir)
	res={}
	n=0
	for i=1, 16 do
		temp = getIDFromChest(dir)
		if temp == nil then
			returnAll(dir)
			return res, n
		end
		res[i]=temp
		n = n + 1
	end
	returnAll(dir)
	return res, n
end

function getBad()
	print("getting bad IDS")
	turtle.suckDown()
	badItems, nToDrop = getIDSFromChest(5)
	print("dropping this shit: ")
	for i=1, nToDrop do
		print("\t", badItems[i])
	end
end

--FUELING------------------------------------------------------

function refuel()
	print("refueling myself, you're welcome asshat\n")
	for i=2, 16 do
		turtle.select(i)
		if turtle.getItemCount() == 0 then
			break
		end
		turtle.refuel()
	end
	print("Coked up and ready to move ", turtle.getFuelLevel(), " spaces")
	return turtle.getFuelLevel()
end

function refuelFromChest(dir, toLevel)
	print("refueling from chest ", dir, "\n\tfrom level ", turtle.getFuelLevel(), "\n   to level ", toLevel)

	inventoryFull=false
	for i=1, 16 do
		if firstEmptySlot() == -1 then
			print("CANNOT REFUEL FROM CHEST, TURTLE FULL")
			return turtle.getFuelLevel()
		end
		if not suckDir(dir,64) then
			return turtle.getFuelLevel()
		end
		turtle.refuel()
		if turtle.getFuelLevel() >= toLevel then
			return turtle.getFuelLevel()
		end
	end
	print("chest refuel stopped at: ", turtle.getFuelLevel())
	return turtle.getFuelLevel()
end

function refuelFromChests()
	print("Refueling from home\n")
	turtle.select(1)
	if turtle.getItemCount() ~= 0 then
		print("EMPTY ME BEFORE REFUELING IDIOT (for programming chest refuel)\n")
		return 0
	end
	
	if refuelFromChest(5,fuelPerRefuel) < fuelPerRefuel then
		print("not enough fuel below, checking above, UGH\n")
		returnAll(5)
		if refuelFromChest(4, fuelNeeded*2) < fuelNeeded*2 then
			returnAll(4)
			print("GIVE ME FORE FUEL IN CHESTS\n")
			return 0
		else
			print("running with ", turtle.getFuelLevel(), " fuel\n")
			returnAll(4)
			return turtle.getFuelLevel()
		end
		returnAll(4)
		print("uh oh")
		return 0
	end
	print("running with ", turtle.getFuelLevel(), " fuel\n")
	returnAll(5)
	
	return turtle.getFuelLevel()
end

--TORCH--------------------------------------------------------------------------

function nTorchSelected()
	item=turtle.getItemDetail()
	if item ~= nil and item.name == torchID then
		return turtle.getItemCount()
	end
	return 0
end

function getNTorches()
	nTorches=0
	for i=1, 16 do
		turtle.select(i)
		nTorches = nTorches + nTorchSelected()
	end
	currNTorches=nTorches
	return nTorches
end

function dropAllBut(ID,dir)
	for i=1, 16 do
		turtle.select(i)
		item=turtle.getItemDetail()
		if(item ~= nil and item.name ~= ID) then
			dropDir(dir, 64)
		end
	end
end

function getItemFromChest(ID, dir, count)
	if count <= 0 then
		return 0
	end
	print("getting ", count, " of ", ID)
	nAquired=0
	turtle.select(1)
	for i=1, 16 do
		if nextEmptySlot() == -1 then
			print("filled up while getting ", ID)
			return nAquired
		end
		suckDir(dir,64)
		item=turtle.getItemDetail()
		if(item ~= nil and item.name == ID) then
			nAquired = nAquired + turtle.getItemCount()
		end
		if(nAquired >= count) then
			
			return nAquired
		end
	end
	return nAquired
end
	
function getTorches(desiredTorches)
	print("gettin lit torches XDXD")
	kill=0
	ret=false
	repeat
		print("PUT TORCHES IN CHESTS!!")
		getNTorches()
		if currNTorches < desiredTorches then
			currNTorches = currNTorches + getItemFromChest(torchID,5,desiredTorches-currNTorches)
			dropAllBut(torchID,dir)
			currNTorches = currNTorches + getItemFromChest(torchID,4,desiredTorches-currNTorches)
			dropAllBut(torchID,dir)
		end
		ret=currNTorches >= desiredTorches
		kill=kill+1
	until kill>TORCH_CYCLES or ret

	return ret
end

function torch(x)
	if (x-1) % TORCH_SPACING == 0 then
		
		for i=1, 16 do
			turtle.select(i)
			if nTorchSelected() ~=0 then
				turtle.placeDown()
				return
			end
		end
	end
end

--STORAGE----------------------------------------------------------------------------

function suckDir(dir, n)
	oldDir=currDir
	ret=false
	if n < 4 then
		face(dir)
		ret = turtle.suck(n)
		face(oldDir)
		return ret
	end
	if dir==4 then
		ret = turtle.suckUp(n)
		return ret
	end
	return turtle.suckDown(n)
end

function dropDir(dir, n)
	oldDir=currDir
	ret=false
	if n < 4 then
		face(dir)
		ret=turtle.drop(n)
		face(oldDir)
		return ret
	end
	if dir==4 then
		return turtle.dropUp(n)
	end
	return turtle.dropDown(n)
end

function returnAll(dir)
	for i=1, 16 do
		turtle.select(i)
		if turtle.getItemCount() == 0 then return end
		dropDir(dir, 64)
	end
end

function dropAll()
	for i=1, 16 do
		turtle.select(i)
		if turtle.getItemCount() == 0 then
			return
		end
		tmpName = turtle.getItemDetail()
		if tmpName ~= nil then
			for i=1, nToDrop do
				if tmpName.name == badItems[i] then
					turtle.drop()
					break
				end
			end
		end
	end
end

function storeItems()
	print("storing items\n")
	for i=1, 16 do
		turtle.select(i)
		if turtle.getItemCount() >0 and nTorchSelected() == 0 then
			while(not turtle.dropUp())do end
		end
	end
end

function getNEmpty()
	nEmpty=0
	for i=1, 16 do
		select(i)
		if turtle.getItemCount() == 0 then
			nEmpty = nEmpty + 1
		end
	end
	return nEmpty
end

function storeAndRefuel(n)
	print("checking storage: \n\tempty slots: ", getNEmpty(),
	"\n\ttorches:  ", getNTorches(),
	"\n\ttorches Needed: ", torchesNeeded,
	"\n\tfuel needed: ", fuelNeeded)

	fromShaft=currShaft

	if refuel() < fuelNeeded or getNEmpty() < N_EMPTY_TO_DROP or getNTorches() < torchesNeeded then
		print("giving you your stuff and fillin up\n")
		if not returnHome() then
			return false
		end
		storeItems()
		if(refuel() < fuelPerRefuel) then
 			refuelFromChests()
		end
			
		return getTorches(torchesNeeded) and goToShaft(fromShaft)
	end
	return true
end

--DIGGING--------------------------------------------------------------------------------

function mineShaft(length, dir)
	for i=0, length-1 do
		digdir(dir, 1)
		torch(i)
	end
	torch(2)
	digdir((dir+1)%4,3)
	
	for i=0, length-1 do
		digdir((dir+2)%4, 1)
		torch(i)
	end
	torch(2)
end

function clearToNextShaft()
    digdir(1,1)
	digdir(0,1)

	digdir(3,2)
	digdir(0,1)
	digdir(1,2)

	digdir(0,2)

	digdir(3,2)
	digdir(0,1)
	digdir(1,2)
	digdir(0,1)
	digdir(3,1)
	
	currShaft = currShaft + 1
	print("now at shaft ", currShaft)
end

function dig(n)
	turtle.select(1)
	for i=0, n-1 do
		while(turtle.detect()) do
			turtle.dig()
		end
		while(not turtle.forward()) do end
		while(turtle.detectDown()) do
			turtle.digDown()
		end
		while(turtle.detectUp()) do
			turtle.digUp()
		end
	end
end

--DIRECTIONAL----------------------------------------------------------------------

function nextShaft()
	if currShaft == 0 then
		digdir(0,1)
		currShaft=1
		return
	end
	if currShaft == -1 then
		face(0)
		while not turtle.forward() do end
		curShaft=0
		return
	end
	digdir(0,6)
	currShaft = currShaft+1
end

function prevShaft()
	if currShaft==0 then
		digdir(2,1)
		currShaft=-1
		return
	end
	if currShaft == 1 then
		face(2)
		while not turtle.forward() do end
		currShaft=0
		return
	end
	digdir(2,6)
	currShaft = currShaft-1
end

function goToShaft(n)
	print("ugh going to shaft ", n, " from shaft ", currShaft, "\n")
	dir=0

	if n < currShaft then
		dir=2
	end

	for i=1, math.abs(currShaft-n) do
		if dir==0 then
			nextShaft()
		else
			prevShaft()
		end
	end
	if n ~= currShaft then
		print("FAILED TO GO TO SHAFT: ", n, " \n\t GET ME AT SHAFT: ", currShaft)
		return false
	else
		print("successfully made it to (your) shaft: ", currShaft)
	end
	atHome=false
	return true
end

function returnHome()
	print("returning home to you baby: ", currShaft)
	return goToShaft(0)
end

function face(dir)
	if currdir==0 and dir == 3 then
		turtle.turnLeft()
		currdir=3
		return
	end
	if currdir==3 and dir == 0 then
		turtle.turnRight()
		currdir=0
		return
	end
	if dir > currdir then
		while(currdir ~= dir % 4) do
			turtle.turnRight()
			currdir = (currdir+1) % 4
		end
	else
		while(currdir ~= dir % 4) do
			turtle.turnLeft()
			currdir = (currdir-1) % 4
		end
	end
	
end

function digdir(dir, length)
	face(dir)
	dig(length)
end

-----------------RUN-----------------------

mine(SHAFT_LENGTH,NUMBER_OF_SHAFTS)