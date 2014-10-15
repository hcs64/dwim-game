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

mode_keymap =
  '1': 0
  '2': 1
  '3': 2
  '4': 3

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

    if dest_block.type == 'exit'
      @halted = true
      @won = true

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
    symbol = @current_program.shift()
    command = @mappingLookup(@current_mode, symbol)
    if command == null
      @current_program.unshift(symbol)
      return {success: false, move: null}
    
    if command.type == 'move'
      success = @requestBotMove(command.dir)
    else #command.type == 'mode'
      success = true
      @current_mode = @modes[command.idx]

    if not success
      @current_program.unshift(symbol)

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
  constructor: (@parent_div, @level, @level_id) ->
    @state = new DwimState(@level)
    gfx = @gfx = new window.DwimGraphics(@parent_div, @state)

    @bot_sprite = @gfx.makeBotSprite()
    @gfx.sprites.push(@bot_sprite)

    @mode_sprites = @gfx.makeModeSprites()
    @gfx.sprites = @gfx.sprites.concat(@mode_sprites)

  startRender: ->
    registerKeyFunction(@keyboardCB)
    registerMouseFunction(@parent_div, @mouseCB)

    requestAnimationFrame(@render)
    rendering = true

  render: (absolute_t) =>
    if @state.halted
      @gfx.showClue(null)

      if @state.won
        @linkNextLevel()
      else
        @linkSameLevel()

    @gfx.render(absolute_t)

    @processProgram()

    if @gfx.isAnimating()
      requestAnimationFrame(@render)
      @rendering = true
    else
      @rendering = false

  keyboardCB: (key) =>
    if @state.halted
      return

    if key of keymap
      move = keymap[key]
      @processPlayerMove(move)
    else if key of mode_keymap
      mode = mode_keymap[key]
      @processModeChange(mode)

    if not @rendering
      requestAnimationFrame(@render)
      @rendering = true

  mouseCB: (what, where) =>
    @gfx.showClue(where)

    if not @rendering
      requestAnimationFrame(@render)
      @rendering = true

  processPlayerMove: (move) ->
    if @state.current_program.length > 0
      if not @state.insertNeededMapping({type: 'move', dir: move})
        return

      @processProgram()

    else

      old_pos = @bot_sprite.computePos()
      if @state.requestBotMove(move)
        @bot_sprite.animateMove(old_pos, move)
        
        @gfx.addRecordSprite({type: 'move', dir: move})

        if @state.current_program.length > 0
          @gfx.onAnimComplete( => @gfx.addProgramSprites())
      else
        @bot_sprite.animateBump(old_pos, move)

  processModeChange: (mode_idx) ->
    if mode_idx == @state.current_mode.idx
      return

    if mode_idx >= @state.modes.length
      return

    if @state.current_program.length > 0
      if not @state.insertNeededMapping({type: 'mode', idx: mode_idx})
        return

      @processProgram()

    else
      @state.current_mode = @state.modes[mode_idx]
      @gfx.animatePopIn(@mode_sprites[mode_idx].animations, 1, 1)
      @gfx.animatePopIn(@bot_sprite.animations, 1, 1)

      @gfx.addRecordSprite({type: 'mode', idx: mode_idx})

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
          @bot_sprite.animateMove(old_pos, move.dir)
        else if move.type == 'mode'
          @gfx.animatePopIn(@mode_sprites[move.idx].animations, 1, 1)
          @gfx.animatePopIn(@bot_sprite.animations, 1, 1)

        @gfx.replaceNextRecordSprite(move)

        if @state.current_program != old_prog
          @gfx.onAnimComplete( => @gfx.addProgramSprites())
      else if move != null
        @bot_sprite.animateBump(old_pos, move.dir)
        @state.halted = true

  linkNextLevel: ->
    if @linked_next_level
      return
    @linked_next_level = true

    @parent_div.removeChild(@gfx.cnv)
    link = document.createElement('a')
    link.href = "?#{@level.next_level}"
    link.appendChild(@gfx.cnv)
    @parent_div.appendChild(link)
  
  linkSameLevel: ->
    if @linked_same_level
      return
    @linked_same_level = true

    @parent_div.removeChild(@gfx.cnv)
    link = document.createElement('a')
    link.href = "?#{@level_id}"
    link.appendChild(@gfx.cnv)
    @parent_div.appendChild(link)
 
window.Dwim = Dwim
