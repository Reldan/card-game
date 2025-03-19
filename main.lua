local Game = require("game") -- Подключаем основной модуль игры

function love.load() -- Функция загрузки, вызывается один раз при старте игры
    love.window.setTitle("Card Deck Adventure") -- Устанавливаем заголовок окна игры
    love.window.setFullscreen(true) -- Включаем полноэкранный режим
    love.graphics.setBackgroundColor(0.1, 0.1, 0.2) -- Задаём фоновый цвет
    Game:load() -- Вызываем метод загрузки данных игры
end

function love.update(dt) -- Функция обновления, вызывается каждый кадр
    Game:update(dt) -- Обновляем состояние игры
end

function love.draw() -- Функция отрисовки, вызывается каждый кадр
    Game:draw() -- Отрисовываем текущий экран игры
end

function love.mousepressed(x, y, button) -- Обработчик нажатия мыши
    Game:mousepressed(x, y, button) -- Передаём событие в логику игры
end

function love.keypressed(key) -- Обработчик нажатия клавиши
    Game:keypressed(key) -- Передаём событие в логику игры
end

function love.textinput(t) -- Обработчик ввода текста
    Game:textinput(t) -- Передаём введённый текст в логику игры
end