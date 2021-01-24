--[[
    
]]

PauseState = Class{__includes = BaseState}

function PauseState:update(dt)
    if love.keyboard.wasPressed('p') then
        gStateMachine:change('play', {savedPlayState = savedPlayState})
    end
end

function PauseState:render()
    -- simple UI code

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Press P to resume', 0, 40, VIRTUAL_WIDTH, 'center')

    
    self.pause_image = love.graphics.newImage(IMAGES_FOLDER..'pause.png')
    love.graphics.draw(
        self.pause_image,
        VIRTUAL_WIDTH/2-self.pause_image:getWidth()/2,
        VIRTUAL_HEIGHT/2-self.pause_image:getHeight()/2
    )

end

function PauseState:enter(params)
    sounds['music']:pause()
    self.savedPlayState = params.savedPlayState
end

--[[
    Called when this state changes to another state.
]]
function PauseState:exit()
    sounds['music']:play()
end