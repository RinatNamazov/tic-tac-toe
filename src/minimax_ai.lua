local Board = require('board')
local TIE, CELL_X, CELL_O = Board.TIE, Board.CELL_X, Board.CELL_O

function choose_best_move(board, current_player)
    local best_move
    local best_score = -math.huge
    local empty_cells = board:get_empty_cells()

    for i = 1, #empty_cells do
        local cell = empty_cells[i]

        board:set_cell(cell.x, cell.y, current_player)
        local score = minimax_alpha_beta_pruning(board, current_player, false, 5, -math.huge, math.huge)
        board:set_cell(cell.x, cell.y, nil)

        if score > best_score then
            best_score = score
            best_move = {x = cell.x, y = cell.y}
        end
    end
    return best_move
end

function minimax_alpha_beta_pruning(board, current_player, is_maximizing, depth, alpha, beta)
    local winner = board:get_winner()
    if winner ~= nil then
        if winner == TIE then
            return 0
        elseif winner == current_player then
            return 1
        else
            return -1
        end
    end

    if depth == 0 then
        return
    end

    local best_score
    local empty_cells = board:get_empty_cells()

    if is_maximizing then
        best_score = -math.huge
        for i = 1, #empty_cells do
            local cell = empty_cells[i]
            board:set_cell(cell.x, cell.y, current_player)
            local score = minimax_alpha_beta_pruning(board, current_player, false, depth - 1, alpha, beta)
            board:set_cell(cell.x, cell.y, nil)
            if score ~= nil then
                best_score = math.max(score, best_score)
                alpha = math.max(score, alpha)
                if best_score >= beta then
                    break
                end
            end
        end
    else
        best_score = math.huge
        for i = 1, #empty_cells do
            local cell = empty_cells[i]
            board:set_cell(cell.x, cell.y, get_opponent(current_player))
            local score = minimax_alpha_beta_pruning(board, current_player, true, depth - 1, alpha, beta)
            board:set_cell(cell.x, cell.y, nil)
            if score ~= nil then
                best_score = math.min(score, best_score)
                beta = math.min(score, beta)
                if best_score <= alpha then
                    break
                end
            end
        end
    end

    return best_score
end

function get_opponent(cell)
    if cell == CELL_X then
        return CELL_O
    elseif cell == CELL_O then
        return CELL_X
    end
end

return {
    choose_best_move = choose_best_move
}