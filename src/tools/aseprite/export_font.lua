-- F256 Font exporter for aseprite

local version = "0.0.1"
local spr = app.activeSprite

if not spr then
	app.alert("There is no sprite to export")
	return false
end

if spr.colorMode ~= ColorMode.INDEXED then
	app.alert("The sprite should use indexed color mode!")
	return false
end

local fileOutput = ""
function put(data)
	fileOutput = fileOutput .. string.char(data)
end


local outputFilename = ""

if string.find(spr.filename, ".png") then
	outputFilename = string.gsub(spr.filename, ".png", ".bin")
elseif string.find(spr.filename, ".aseprite") then
	outputFilename = string.gsub(spr.filename, ".aseprite", ".bin")
else
	outputFilename = spr.filename .. ".bin"
end

local spriteWidth = 8
local spriteHeight = 8

local d = Dialog("Export F256 Font " .. version)


d:file {id="fileName", label="Save as:", save=true, filename=outputFilename, focus=true}
 :separator {text="Sprites"}
 :number {id="spriteWidth", label="Width:", text=tostring(spriteWidth), decimals=0}
 :number {id="spriteHeight", label="Height:", text=tostring(spriteHeight), decimals=0}
 :button {id="ok", text="&OK", focus=true}
 :button {text="&Cancel"}:show()

local data = d.data
if not data.ok then
	return false
end

outputFilename = data.fileName
spriteWidth = data.spriteWidth
spriteHeight = data.spriteHeight

print(spriteWidth)
print(spriteHeight)


local img = Image(spr.spec)
img:drawSprite(spr, app.activeFrame)

local pal = spr.palettes[1]
local width = img.width
local height = img.height


-- Save image data
local spriteBytes = ""
local byteCount = 0

local total = 0
local cols = math.floor(width / spriteWidth)
local rows = math.floor(height / spriteHeight)

if #pal > 128 then
	app.alert("We only supports up to 128 different color values")
	return false
end

local pixels = {}

-- Extract image pixels
for row = 0, rows - 1 do
	for col = 0, cols - 1 do
		for y = 0, spriteHeight - 1 do
			local data = 0

			for x = 0, spriteWidth - 1 do
				local px = img:getPixel((col * spriteWidth) + x, (row * spriteHeight) + y)
				if px > 0 then
					data = data | (0x01 << (spriteWidth - x - 1))
				end
			end

			put(data)
		end
	end
end

local f = io.open(outputFilename, "wb")
io.output(f)
io.write(fileOutput)
io.close(f)


app.alert("Exported ok!")

