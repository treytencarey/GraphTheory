# GraphTheory
Introduced as a Graph Theory topic, virtual sensors can be implemented in simple code to show how a sensor may be able to determine which sensors it can communicate with without complex algorithms. 

# Engine
This project uses the World of Hello engine (https://www.worldofhello.org/) which is an engine developed solely by me.
To reproduce this development environment, simply download the engine from the Download tab (Windows-only), clone this repository, and upload the files in the downloaded repository to the Hello secure server.

# Folder Structure
Tilesets -> Contains the grid image for displaying the graph background.
Players -> Contains the node image.
Scripts -> Contains the code for this project.

# Script Overview
main.lua: The Hello engine starts with the main.lua script, which tells what other scripts to include. 
player.lua: Contains relevant code to a player (node) and all other nodes.
world.lua: Contains relevant code to determining world-grid positions.
