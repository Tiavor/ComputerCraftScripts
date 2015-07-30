# ComputerCraftScripts
Lua scripts for the Minecraft mod ComputerCraft

how to install the script:
place down a mining turtle, create a script by entering "edit something", save the file and exit the console
with the command "id" you can get the number of the computer/turtle
go into your .minecraft\saves\ folder, open your world save, there should be a folder named "computer" and in there are the ids of the computers and the script files with no particular file ending. insert the digtunnel script here, remove any unnecessary symbols, spaces and the file ending .lua or copy the text into the existing file. now you can run the script by simply typing the file name into the console.

digtunnel is a simple tunnel digger script.
setup: put down a mining turtle facing in the direction you want to dig the tunnel. in that direction, place chests with materials (default: coal and stone) above and/or below the path the turtle will go. one of them should be empty, that will be used to empty the turtle inventory. don't let spaces between the chests. the first point when it moves forward where it doesn't find a chest, marks the start.

- version 1.0: stable, 100% working
- version 1.1 (beta): preparing for upgrade, adding a virtual inventory to search faster through it. (will 100% not work correctly ;)
- future plans: player builds a section of a tunnel design, the turtle mines it down and creates copies of it for the whole tunnel.
