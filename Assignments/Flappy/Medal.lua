--[[
    
]]

Medal = Class{}


function Medal:init(score)
    
    if score == 0 then
        self.MEDAL_IMAGE = love.graphics.newImage(IMAGES_FOLDER..'bronze.png')

    elseif score < 3 then
        self.MEDAL_IMAGE = love.graphics.newImage(IMAGES_FOLDER..'silver.png')

    else
        self.MEDAL_IMAGE = love.graphics.newImage(IMAGES_FOLDER..'gold.png')
    end
end

function Medal:update(dt)
    
end

function Medal:render()

    love.graphics.draw(
        self.MEDAL_IMAGE,
        VIRTUAL_WIDTH/2-self.MEDAL_IMAGE:getWidth()/2,
        VIRTUAL_HEIGHT/2-self.MEDAL_IMAGE:getHeight()/2
    )
end