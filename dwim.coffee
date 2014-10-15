# general directions
window.UP = (theta: Math.PI/2, dx: 0, dy: -1, name: 'up')
window.LEFT = (theta: Math.PI, dx: -1, dy: 0, name: 'left')
window.RIGHT = (theta: 0, dx: 1, dy: 0, name: 'right')
window.DOWN = (theta: -Math.PI/2, dx: 0, dy: 1, name: 'down')

keymap =
  # traditional wasd
  'w': UP
  'a': LEFT
  's': DOWN
  'd': RIGHT
  # arrow keys
  '<up>': UP
  '<left>': LEFT
  '<down>': DOWN
  '<right>': RIGHT

reverseDir = (dir) ->
  switch dir
    when UP
      return DOWN
    when DOWN
      return UP
    when LEFT
      return RIGHT
    when RIGHT
      return LEFT


parseRanges = (ranges_string) ->
  point_list = []

  for range in ranges_string.split(' ')
    [rangex, rangey] =
      for d in range.split(',')
        if d.indexOf('-') == -1
          i = parseInt(d, 10)
          [i, i]
        else
          i = d.split('-')
          [parseInt(i[0], 10), parseInt(i[1], 10)]
    for x in [rangex[0]..rangex[1]]
      for y in [rangey[0]..rangey[1]]
        point_list.push({x:x,y:y})

  point_list


################

class DwimState
  constructor: (level) ->
    @Wi = level.dims.w
    @Hi = level.dims.h

    @bot = {x: level.startpos.x, y: level.startpos.y}

    @level = {}
    for x in [-1..@Wi]
      @level[x] = {}
      for y in [-1..@Hi]
        @level[x][y] = {type: 'empty'}

    # border
    for x in [-1..@Wi]
      @level[x][-1] = {type: 'obstacle', id: 0}
      @level[x][@Hi] = {type: 'obstacle', id: 0}
    for y in [-1..@Hi]
      @level[-1][y] = {type: 'obstacle', id: 0}
      @level[@Wi][y] = {type: 'obstacle', id: 0}

    # general obstacles
    @obstacles = [{}]
    for obstacle in level.obstacles
      id = @obstacles.length
      @obstacles[id] = obstacle

      for {x:x, y:y} in parseRanges(obstacle)
        if @level[x][y].type == 'obstacle' and @level[x][y].id == 0
          throw 'overwriting border with lesser obstacle'
        @level[x][y] = {type: 'obstacle', id: id}

    # programs
    @programs = []
    for program in level.programs
      id = @programs.length
      @programs[id] = program

      for {x:x, y:y} in parseRanges(program.loc)
        if @level[x][y].type == 'obstacle' and @level[x][y].id == 0
          throw 'overwriting border with program'
        @level[x][y] = {type: 'program', id: id}

    # exit
    if @level[level.exitpos.x][level.exitpos.y].type == 'obstacle' and
       @level[level.exitpos.x][level.exitpos.y].id == 0
      throw 'overwriting border with exit'
    @level[level.exitpos.x][level.exitpos.y] = {type: 'exit'}

    @modes = level.mappings
    for mode, idx in @modes
      mode.idx = idx
    @current_mode = @modes[0]
    @current_program = []

  requestBotMove: (dir) ->
    dest = {x: @bot.x + dir.dx, y: @bot.y + dir.dy}
    dest_block = @level[dest.x][dest.y]
    if dest_block.type == 'obstacle'
      return false

    @bot.x = dest.x
    @bot.y = dest.y

    if dest_block.type == 'program'
      if @current_program.length == 0
        @current_program = @programs[dest_block.id].code.split('')

    return true

  mappingLookup: (mode, symbol) ->
    if symbol of mode.lookup
      return mode.lookup[symbol]
    else
      return null

  mappingInsert: (mode, symbol, command) ->
    mode.lookup[symbol] = command
    if not (symbol in mode.symbols)
      mode.symbols.push(symbol)
    
  doWhatMustBeDone: () ->
    if @current_program.length == 0
      return {success: false, move: null}
    symbol = @current_program[0]
    command = @mappingLookup(@current_mode, symbol)
    if command == null
      return {success: false, move: null}
    
    # TODO: not if mode switch
    success = @requestBotMove(command)
    if success
      @current_program.shift()

    return {success: success, move: command}

  insertNeededMapping: (new_command) ->
    if @current_program.length == 0
      return false
    symbol = @current_program[0]
    command = @mappingLookup(@current_mode, symbol)

    if command != null
      return false

    @mappingInsert(@current_mode, symbol, new_command)

    return true

################

class Dwim
  constructor: (@parent_div, @level) ->
    @state = new DwimState(@level)
    gfx = @gfx = new window.DwimGraphics(@parent_div, @state)

    @bot_sprite = @gfx.makeBotSprite()
    @gfx.sprites.push(@bot_sprite)

    @mode_sprites = @gfx.makeModeSprites()
    @gfx.sprites = @gfx.sprites.concat(@mode_sprites)

  startRender: ->
    requestAnimationFrame(@render)
    rendering = true

  render: (absolute_t) =>
    @gfx.render(absolute_t)

    @processProgram()

    if @gfx.isAnimating()
      requestAnimationFrame(@render)
      @rendering = true
    else
      @rendering = false

  keyboardCB: (key) =>
    t = Date.now()
    if key of keymap
      move = keymap[key]
      @processPlayerMove(move)

    if not @rendering and @gfx.isAnimating()
      requestAnimationFrame(@render)
      @rendering = true

  processPlayerMove: (move) ->
    if @state.current_program.length > 0
      if not @state.insertNeededMapping(move)
        return

      @processProgram()

    else

      old_pos = @bot_sprite.computePos()
      if @state.requestBotMove(move)
        @bot_sprite.animateMove(old_pos, move)
        
        @gfx.addRecordSprite(move)

        if @state.current_program.length > 0
          @gfx.onAnimComplete( => @gfx.addProgramSprites())
      else
        @bot_sprite.animateBump(old_pos, move)

  processProgram: ->
    if @bot_sprite.animations.length == 0 and
       @state.current_program.length > 0 and
       not @state.halted
      old_pos = @bot_sprite.computePos()
      old_prog = @state.current_program
      {success: success, move: move} = @state.doWhatMustBeDone()
      if success
        new_pos = @bot_sprite.computePos()
        if old_pos.x != new_pos.x or old_pos.y != new_pos.y
          @bot_sprite.animateMove(old_pos, move)
        @gfx.replaceNextRecordSprite(move)

        if @state.current_program != old_prog
          @gfx.onAnimComplete( => @gfx.addProgramSprites())
      else if move != null
        @bot_sprite.animateBump(old_pos, move)
        @state.halted = true


window.Dwim = Dwim
