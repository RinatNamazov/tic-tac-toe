function choose_random_move(board)
    local empty_cells = board:get_empty_cells()
    if #empty_cells > 0 then
        return empty_cells[math.random(1, #empty_cells)]
    end
end

return {
    choose_random_move = choose_random_move
}