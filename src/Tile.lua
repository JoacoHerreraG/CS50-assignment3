Tile = Class{}

function Tile:init(x, y, color, variety, shiny)
    
    self.gridX = x
    self.gridY = y

    self.x = (self.gridX - 1) * 32
    self.y = (self.gridY - 1) * 32

    self.color = color
    self.variety = variety

    self.shiny = shiny
    self.shinyColors = {
        [1] = {217, 87, 99, 128},
        [2] = {95, 205, 228, 128},
        [3] = {251, 242, 54, 128},
        [4] = {118, 66, 138, 128},
        [5] = {153, 229, 80, 128},
        [6] = {223, 113, 38, 128}
    }

    self.shinyTimer = Timer.every(0.2, function()
        self.shinyColors[0] = self.shinyColors[6]
        for i = 6, 1, -1 do
            self.shinyColors[i] = self.shinyColors[i - 1]
        end
    end)
end

function Tile:render(x, y)
    
    love.graphics.setColor(34, 32, 52, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x + 2, self.y + y + 2)

    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(gTextures['main'], gFrames['tiles'][self.color][self.variety],
        self.x + x, self.y + y)
    if self.shiny then 
        for i = 1, 6 do
            love.graphics.setColor(self.shinyColors[i])
            love.graphics.setLineWidth(2)
            love.graphics.rectangle('line', self.x + x + 4, self.y + y + 4, 24, 24, 3, 3)
        end
    end
end