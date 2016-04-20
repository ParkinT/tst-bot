require 'sinatra'
require 'json'
require 'redis'
require 'uri'
require './game_logic'

  # rackup -o 0.0.0.0 -p 3000

  DEBUG = false
  RESPONSE_TYPE_EPHEMERAL = "ephemeral"
  RESPONSE_TYPE_IN_CHANNEL = "in-channel"
  COMMANDS = "\n\ntic [move] *col* 3, *row* 2 - *new* game - *help*"
  SIGLINE = "\n:copyright: Websembly, LLC"
  SPACE = ":white_square:"
  NEW_GAME_TEXT = "Let's Play *Tic-Slack-Toe* :grey_exclamation:"
  INTRO_TEXT = "Welcome\nThis is *not* _Your Father's Tic-Tac-Toe_\nThe grid is *4 BY 4* to present a BIGGER challenge.\nYou will always make the FIRST move.\nI will make a move after you.\nYou can return to the game *at any time* and it will be where we left off; Type `tic` to view the board without making a move.\nType `tic new` for your first game.\nGood Luck :thumbsup:"

  HELP_TEXT = "new game - to start a new game ( you will lose your previous progress)\ncol n row n - to indicate where to play your mark"

  COLS_MAX = 4
  ROWS_MAX = 4

  post '/' do
  #return if params[:token] != ENV['SLACK_TOKEN']

    uri = URI.parse(ENV["REDIS_URL"])
    @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

=begin
    response 'params' include
    - token
    - team_id
    - team_domain
    - service_id
    - channel_id
    - channel_name
    - timestamp
    - user_id
    - user_name
    - text
    - trigger_word
=end

    # use the user_name to 'personalize' the responses
    user_name = params.fetch("user_name", "Worthy Opponent")
    # match user_id and channel_id to uniquely identify the game in progress
    # the user_id and channel_id form a unique key in Redis where the current state of the game is stored

    user_identity = "#{params.fetch('channel_id', 0)}:#{params.fetch('user_id', 0)}"  #Redis key
    user_wins = "#{user_identity}_wins"
    user_loss = "#{user_identity}_loss"

    if (@redis.LRANGE user_identity, 0, -1).empty?  #NEW PLAYER
      puts "NEW PLAYER" if DEBUG  # first time for this player
      #setup the player
      @redis.LPUSH user_identity, "0","0", "0", "0", "0","0", "0", "0", "0","0", "0", "0", "0","0", "0", "0"
      return {:username => 'Tic-Slack-Toe', :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "#{INTRO_TEXT}" }.to_json
    end

    new_game = false  #flag to prevent bot from making a move on the first turn
    user_emoji = ":x:"  #this will be customizable in the future
    bot_emoji = ":o:"
    emoji_set = [SPACE, user_emoji, bot_emoji]
    # each 'cell' is uniquely labelled but not in the expected pattern.  The 'weight' of the cell is encoded in its value.
    #   The center cell is the most valuable, followed by the corners
    #   If a mark can be placed in a cell adjacent to one of our own, that is preferred.  Secondly, it is desireable to place a mark in a cell adjacent to an existing mark of our own.

    trigger_word = params[:trigger_word].strip # we don't need to check this for any reason, but it is here for troubleshooting
    keywords = params[:text].strip.gsub(trigger_word, '')

    #evaluate commands
    commands = /(\S{3,7})\s+\d{1}[,|\s]+(\S{3,7})\s+\d{1}/.match(keywords)
    values = /\S{3,7}\s+(\d{1})[,|\s]+\S{3,7}\s+(\d{1})/.match(keywords)

    show_board_only = false
    marks = {}
    content_type :json
    if keywords.size > 2 #keywords identified
      first_keyword = (keywords.split(' '))[0]
      case first_keyword[0..2].downcase
      when "new"
        new_game = true
        @redis.DEL user_identity
      when "mov", "col", "row"
        if commands.nil? || values.nil?
          return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "Incorrect or incomplete command\n#{HELP_TEXT}" }.to_json
        elsif commands.size == 3 && values.size == 3
          commands[0..-1].each_with_index do |command, idx|
            marks.store((command[0,3].downcase).to_sym, values[idx].to_i)
          end
          return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "Incorrect or incomplete command\n#{HELP_TEXT}" }.to_json if marks.empty? || marks.size != 2
          return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "Incorrect or incomplete command\n#{HELP_TEXT}" }.to_json if marks[:col].abs > COLS_MAX || marks[:row].abs > ROWS_MAX
        else
          return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => ":interrobang:\n#{HELP_TEXT}" }.to_json
        end
      when "hel"
        return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => ":question:\n#{HELP_TEXT}" }.to_json
      end
    else
      show_board_only = true
    end
    # ==================
      # commands validated - we can proceed

    # get user board
    user_board = "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0" # create an empty user board if there is not one
    if new_game
      pre_text = NEW_GAME_TEXT +  "\nYou are #{user_emoji}  "
    else
      16.times do |i|
        user_board[i] = (@redis.lpop user_identity).to_s
      end
    end

    if DEBUG
      board_output = ""
      user_board.each_with_index { |u, idx| board_output << "#{u} | "; board_output << "\n" if (idx + 1) % 4 == 0 }
      puts "User Statistics:"
      puts @redis.GET user_wins
      puts @redis.GET user_loss
    end

    # if commands to add a mark, do so
    begin
      mark_at = ((marks[:row] - 1) * 4 + marks[:col]) -1  #zero-indexed
      if user_board[mark_at].to_i != 0 # but ONLY if it is empty
         @redis.RPUSH user_identity, user_board #save the board because we are about to bail out
         @redis.LTRIM user_identity, "0", 15  #maintain only the most recent 16 items
         return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "Invalid Space\nRow: #{marks[:row]}/Col: #{marks[:col]} already occupied\nTry again\nrow n col n" }.to_json
      end
      user_board[mark_at] = "1"  #user emoji
    end unless marks.empty?

    # bot makes a move !!!!!
    bot_move = bot_makes_move(user_board)
    user_board[bot_move] = "2" unless new_game || show_board_only


    if DEBUG
      board_output = ""
      user_board.each_with_index { |u, idx| board_output << "#{u} | "; board_output << "\n" if (idx + 1) % 4 == 0 }
      puts "\n\n"
      puts board_output
    end

    # ==============

   @redis.RPUSH user_identity, user_board
   @redis.LTRIM user_identity, "0", 15  #maintain only the most recent 16 items

    winner = check_for_winner(board: user_board).to_i
    @redis.INCR user_wins if winner == 1 && !new_game
    @redis.INCR user_loss if winner == 2 && !new_game

    #check for no more moves
    continue_game = moves_available?(user_board)

    cell_dd, cell_dc, cell_db, cell_da,
      cell_cd, cell_cc, cell_cb, cell_ca,
      cell_bd, cell_bc, cell_bb, cell_ba,
      cell_ad, cell_ac, cell_ab, cell_aa = emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i],
      emoji_set[user_board.pop.to_i]

    horizontal_break = ":heavy_minus_sign::heavy_plus_sign::heavy_minus_sign::heavy_plus_sign::heavy_minus_sign::heavy_plus_sign::heavy_minus_sign:"
    #vertical_break = ":grey_exclamation:"
    vertical_break = ":thermometer:"
    board_grid = "#{cell_aa}#{vertical_break}#{cell_ab}#{vertical_break}#{cell_ac}#{vertical_break}#{cell_ad}\n#{horizontal_break}\n#{cell_ba}#{vertical_break}#{cell_bb}#{vertical_break}#{cell_bc}#{vertical_break}#{cell_bd}\n#{horizontal_break}\n#{cell_ca}#{vertical_break}#{cell_cb}#{vertical_break}#{cell_cc}#{vertical_break}#{cell_cd}\n#{horizontal_break}\n#{cell_da}#{vertical_break}#{cell_db}#{vertical_break}#{cell_dc}#{vertical_break}#{cell_dd}\n"


    return {:username => "Tic-Slack-Toe", :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "The game is a *DRAW*\nGood work #{user_name}\n#{board_grid}#{COMMANDS}#{SIGLINE}" }.to_json unless continue_game #check for a draw

    @redis.RPUSH( user_identity, "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0") unless winner == 0 # create an empty user board if there was a win
    case winner
    when 1
      return {:username => 'Tic-Slack-Toe', :response_type => RESPONSE_TYPE_IN_CHANNEL, :text => "\n---\nYou have WON #{user_name}!:medal:\n\n---\n\n#{board_grid}#{COMMANDS}#{SIGLINE}" }.to_json if winner == 1
    when 2
      return {:username => 'Tic-Slack-Toe', :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "I won.  But it was *very* close,#{user_name}!:chart_with_upward_trend:\n#{board_grid}#{COMMANDS}#{SIGLINE}" }.to_json
    else
      return {:username => 'Tic-Slack-Toe', :response_type => RESPONSE_TYPE_EPHEMERAL, :text => "#{pre_text}\nYour move: #{user_name}\n#{board_grid}#{COMMANDS}#{SIGLINE}" }.to_json
    end

end
