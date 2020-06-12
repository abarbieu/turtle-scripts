----TO USE----
--BUILDING MATERIAL SLOT 1
--LADDERS SLOT 2
--FUEL SLOT 3+
----SETTINGS----

startY = 20
endY = 10

-----------------
ladderDir=5

if startY>endY then
	ladderDir=5
else
	ladderDir=4
end
length=math.abs(endY-startY)

currdir=0

--MAIN-------------------------------------------------------

function refuel()
    for i=3, 16 do
        turtle.select(i)
        if turtle.getItemCount() == 0 then
            break
        end
        turtle.refuel()
    end
    return turtle.getFuelLevel()
end
function makeShaft(dir)
	for i=0, length do
		turtle.dig()
		placeSlot(1)
		if(dir==5) then
			while not turtle.down() do
				turtle.digDown()
			end
		else
			while not turtle.up() do
				turtle.digUp()
			end
		end
	end
end

function placeLadders(dir)
	for i=0, length do
		if(dir==4) then
			while not turtle.down() do
				turtle.digDown()
			end
		else
			while not turtle.up() do
				turtle.digUp()
			end
		end
		placeSlot(2)
	end
end
	
	
function makeLadder()
	if turtle.getFuelLevel() < length * 2 and refuel() < length * 2 then
		print("GIVE ME MORE FUEL(slot 3+)!!!!!!\n")
		while(refuel() < length * 2) do end
	end
	turtle.select(2)
	if turtle.getItemCount() < length then
		print("GIVE ME MORE LADDERS(slot 2)!!!!!\n")
		while(turtle.getItemCount() < length*2) do end
	end
	turtle.select(1)
	if turtle.getItemCount() < length then
		print("GIVE ME MORE BUILDING MATERIAL(slot 1)!!!!!\n")
		while(turtle.getItemCount() < length*2) do end
	end

	makeShaft(ladderDir)
	digdir(2,1)
	face(0)
	turtle.back()
	placeLadders(ladderDir)
end

--HELPER----------------------------------------------------

function placeSlot(x)
	turtle.select(x)
	turtle.place()
end

--DIRECTIONAL-----------------------------------------------

function dig(n)
    for i=0, n-1 do
        while(turtle.detect()) do
            turtle.dig()
        end
    end
end

function face(dir)
    if currdir==0 and dir == 3 then
        print("AA")
        turtle.turnLeft()
        currdir=3
        return
    end
    if currdir==3 and dir == 0 then
        print("BB")
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

makeLadder()