def moves_available?(board)
  board.uniq.include? "0"
end

def check_for_winner(board:, player: 1, bot: 2)
  #
  # check vertical
  winner = read_rows(board, board[0], [4, 8, 12])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[1], [5, 9, 13])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[2], [6, 10, 14])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[3], [7, 11, 15])
  return winner if winner && winner.to_i > 0

  # check horizontals
  winner = read_rows(board, board[0], [1, 2, 3])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[4], [5, 6, 7])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[8], [9, 10, 11])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[12], [13, 14, 15])
  return winner if winner && winner.to_i > 0

  # check diagonals
  winner = read_rows(board, board[12], [4, 5, 8])
  return winner if winner && winner.to_i > 0
  winner = read_rows(board, board[0], [5, 10, 15])
  return winner if winner && winner.to_i > 0

  # return the winner or zero if none
  0
end

def read_rows(board, cmp, line)
  result = line.collect { |b| board[b].to_i == cmp.to_i }.uniq
  return cmp if result.size == 1 && result.first == true
  nil
end

def bot_makes_move(board)
  # this can be refactored !!!!
  play= nil

  #across
  # imminent win
  [0, 4, 8, 12].each do |i|
    player = [i, i+1, i+2, i+3].collect { |b| board[b] == "1" }
    player_mark, no_mark = player.partition { |m| m == true }
    if player_mark.count == 3 #player is about to win
      1.upto(3) do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
    bot = [i, i+1, i+2, i+3].collect { |b| board[b] == "2" }
    bot_mark, no_mark = bot.partition { |m| m == true }
    if bot_mark.count == 3 # bot is about to win
      1.upto(3) do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
  end
  # distant win
  [0, 4, 8, 12].each do |i|
    player = [i, i+1, i+2, i+3].collect { |b| board[b] == "1" }
    player_mark, no_mark = player.partition { |m| m == true }
    if player_mark.count == 2 #player is about to win
      1.upto(3) do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
    bot = [i, i+1, i+2, i+3].collect { |b| board[b] == "2" }
    bot_mark, no_mark = bot.partition { |m| m == true }
    if bot_mark.count == 2 # bot is about to win
      1.upto(3) do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
  end

  #down
  # imminent win
  [0, 1, 2, 3].each do |i|
    player = [i, i+4, i+8, i+12].collect { |b| board[b] == "1" }
    player_mark, no_mark = player.partition { |m| m == true }
    if player_mark.count == 3 #player is about to win
      [4, 8, 12].each do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
    bot = [i, i+4, i+8, i+12].collect { |b| board[b] == "2" }
    bot_mark, no_mark = bot.partition { |m| m == true }
    if bot_mark.count == 3 # bot is about to win
      [4, 8, 12].each do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
  end
  # distant win
  [0, 1, 2, 3].each do |i|
    player = [i, i+4, i+8, i+12].collect { |b| board[b] == "1" }
    player_mark, no_mark = player.partition { |m| m == true }
    if player_mark.count == 2 #player is about to win
      [4, 8, 12].each do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
    bot = [i, i+4, i+8, i+12].collect { |b| board[b] == "2" }
    bot_mark, no_mark = bot.partition { |m| m == true }
    if bot_mark.count == 3 # bot is about to win
      [4, 8, 12].each do |check|
        play = (check + i) if board[i+check] == "0"  #redis always returns a string
      end
    end
  end

  # diagonally
  player_mark, no_mark = [0, 5, 10, 15].collect { |b| board[b] == "1" }.partition { |m| m == true }
  if player_mark.count == 2 #distant win
    [0, 5, 10, 15].each { |check| play = check if board[check] == "0" }
  end
  if player_mark.count == 3 # immenent win
    [0, 5, 10, 15].each { |check| play = check if board[check] == "0" }
  end

  bot_mark, no_mark = [0, 5, 10, 15].collect { |b| board[b] == "2" }.partition { |m| m == true }
  if bot_mark.count == 2 #distant win
    [0, 5, 10, 15].each { |check| play = check if board[check] == "0" }
  end
  if bot_mark.count == 3 # immenent win
    [0, 5, 10, 15].each { |check| play = check if board[check] == "0" }
  end

  # diagonally
  player_mark, no_mark = [3, 6, 9, 12].collect { |b| board[b] == "1" }.partition { |m| m == true }
  if player_mark.count == 2 #distant win
    [3, 6, 9, 12].each { |check| play = check if board[check] == "0" }
  end
  if player_mark.count == 3 # immenent win
    [3, 6, 9, 12].each { |check| play = check if board[check] == "0" }
  end

  bot_mark, no_mark = [3, 6, 9, 12].collect { |b| board[b] == "2" }.partition { |m| m == true }
  if bot_mark.count == 2 #distant win
    [3, 6, 9, 12].each { |check| play = check if board[check] == "0" }
  end
  if bot_mark.count == 3 # immenent win
    [3, 6, 9, 12].each { |check| play = check if board[check] == "0" }
  end

  return play if play

  # purely random
  loop do
    r = rand(15)
    break r if board[r].to_i == 0
  end
  #implied return of r

end

