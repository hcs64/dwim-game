# general directions
UP = (theta: Math.PI/2, dx: 0, dy: -1)
LEFT = (theta: Math.PI, dx: -1, dy: 0)
RIGHT = (theta: 0, dx: 1, dy: 0)
DOWN = (theta: -Math.PI/2, dx: 0, dy: 1)

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

g = window.dwim_graphics

instruction_names =
  s: 'square'
  c: 'circle'
  d: 'diamond'
  h: 'hex'

board_start = {x: 70, y: 164}
program_start = {x: 20, y: 20}
mapping_start = {x: 70, y: 10}

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

class Dwim
  constructor: (@cnv, @div) ->
    @ctx = @cnv.getContext('2d')
    @W = @cnv.width
    @H = @cnv.height

    @Wi = Math.floor(@W / g.cell_size)
    @Hi = Math.floor(@H / g.cell_size)
  
  start: (level) ->
    @botx = level.startpos.x
    @boty = level.startpos.y
    @botdir = RIGHT.theta

    @Wi = level.dims.w
    @Hi = level.dims.h
    @cnv.width  = @W = board_start.x + @Wi * g.cell_size
    @cnv.height = @H = board_start.y + @Hi * g.cell_size
    @ctx = @cnv.getContext('2d')

    @level = []
    for x in [0...@Wi]
      @level[x] = []
      for y in [0..@Hi]
        @level[x][y] = {type: 'empty'}

    @obstacles = []
    for obstacle in level.obstacles
      id = @obstacles.length
      @obstacles[id] = obstacle

      for {x:x, y:y} in parseRanges(obstacle)
        @level[x][y] = {type: 'obstacle', id: id}

    @programs = []
    for program in level.programs
      id = @programs.length
      @programs[id] = program

      for {x:x, y:y} in parseRanges(program.loc)
        @level[x][y] = {type: 'program', id: id}

    @level[level.exitpos.x][level.exitpos.y] = {type: 'exit'}

    @available_mappings = level.available_mappings

    @active_program = null
    @allowed_move = null
    @mappings = [ new Mapping() ]
    @active_mapping = null
    @next_level_id = level.next_level
    
    @requestRender()
    @startInput()

    @updateProgram()

  requestRender: ->
    requestAnimationFrame(@renderCB)

  startInput: ->
    registerKeyFunction(@keyboardCB)

  setStatus: (status) ->
    @div.innerHTML = status

  setError: (error) ->
    @setStatus('<span class="error">' + error + '</span>')

  nextLevelLink: () ->
    @setStatus("Completed! <a href=\"?#{@next_level_id}\">Next Level</a>")

  renderCB: =>
    g.clear(@ctx, @W, @H)

    @ctx.save()
    @ctx.translate(board_start.x, board_start.y)

    for x in [0...@Wi]
      for y in [0...@Hi]
        switch @level[x][y].type
          when 'empty'
            true
          when 'program'
            @renderProgramCell(x, y)
          when 'obstacle'
            @renderObstacleCell(x, y)
          when 'exit'
            @renderExitCell(x, y)

    bot =
      showxi: @botx
      showyi: @boty
      showdir: @botdir
      render: g.renderBot

    bot.render(@ctx)

    @ctx.translate(-.5,-.5)
    g.border(@ctx, @Wi*g.cell_size, @Hi*g.cell_size)

    @ctx.restore()

    if @active_program?
      @ctx.save()
      @ctx.translate(program_start.x, program_start.y)


      code = @active_program.code
      cs = g.command_size
      ics = g.inner_command_size

      @ctx.save()
      g.setStyle(@ctx, g.thick_lined_style)

      @ctx.translate(cs/2, cs/2 - @pc * cs)

      for idx in [0...code.length]
        g.renderShape(@ctx, instruction_names[code[idx]], ics/2)

        @ctx.translate(0, cs)

      @ctx.restore()

      @ctx.save()
      g.setStyle(@ctx, g.lined_style)
      @ctx.strokeRect(0, 0, cs, cs)
      @ctx.restore()

      @ctx.restore() # end rendering active program

    if @active_mapping?
        @ctx.save()
        @ctx.translate(mapping_start.x, mapping_start.y)

        @active_mapping.render(@ctx, @currentInstruction())

        @ctx.restore()

  keyboardCB: (key) =>
    @requestRender()
    if @stop_running
      return

    if key of keymap
      dir = keymap[key]
      @requestBotMove(dir)

    if key == '<return>'
      @doWhatMustBeDone()

    return

  renderProgramCell: (x, y) ->
    g.renderProgramCell(@ctx, x, y)
  renderObstacleCell: (x, y) ->
    g.renderObstacleCell(@ctx, x, y)
  renderExitCell: (x, y) ->
    g.renderExitCell(@ctx, x, y)

  updateAllowedMove: () ->
    if not @active_program?
      @allowed_move = null
      return

    # set, but invalid, no move possible
    @allowed_move = {x:-1,y:-1}

    action = @translateInstruction(@currentInstruction())
    if action.type == 'move'
      @allowed_move = x: @botx + action.dir.dx, y: @boty + action.dir.dy
    if action.type == 'blank'
      @allowed_move = null

    # otherwise movement is not possible
    return

  isMoveAllowed: (x, y) ->
    # check borders
    if x < 0 or y < 0 or x >= @Wi or y >= @Hi
      return false

    if @level[x][y].type == 'obstacle'
      return false

    if @allowed_move?
      console.log('allowed ' +@allowed_move.x+','+@allowed_move.y)
      if @allowed_move.x != x or @allowed_move.y != y
        return false

    return true

  requestBotMove: (dir) ->
    x = @botx + dir.dx
    y = @boty + dir.dy

    console.log('want ' +x+','+y)
    
    if @isMoveAllowed(x,y)
      if @active_program?
        @execute({type: 'move', dir: dir})
      else
        # free movement
        @botx = x
        @boty = y
        @botdir = dir.theta

        @updateProgram()
    else if not @active_program?
      # at least turn in the desired direction
      @botdir = dir.theta

    return

  doWhatMustBeDone: () ->
    @execute(@translateInstruction(@currentInstruction()))

  currentInstruction: () ->
    return @active_program.code.charAt(@pc)

  translateInstruction: (instruction) ->
    return @active_mapping.mapCode(instruction)

  execute: (requested_action) ->
    ra = requested_action
    if not @active_program?
      return false
    if ra.type == 'blank'
      return false

    action = @translateInstruction(@currentInstruction())

    # check that requested action matches action to execute
    if action.type != 'blank' and action.type != ra.type
      return false

    switch action.type
      when 'move'
        if @isMoveAllowed(ra.dir.dx + @botx, ra.dir.dy + @boty)
          @botx = @allowed_move.x
          @boty = @allowed_move.y
          @botdir = ra.dir.theta
        else
          return false
      when 'mapping'
        if ra.id == action.id
          @active_mapping = @mappings[action.id]
        else
          return false
      when 'blank'
        @installMapping(@active_mapping, requested_action,
                        @currentInstruction())
        @updateProgram()
        # recursively execute the command
        return @execute(requested_action)

    @pc += 1
    if @pc == @active_program.code.length
      # TODO: need to eject from program region if still in one
      @active_program = null
      @active_mapping = null # questionable

    @updateProgram()

    return true

  updateProgram: () ->
    cell = @level[@botx][@boty]
    if cell.type == 'program'
      if @active_program? and
           @active_program.code == @programs[cell.id].code
          true # no change
        else
          # TODO: notify user
          @active_program = @programs[cell.id]
          @active_mapping = @mappings[0] # questionable
          @pc = 0
    if cell.type == 'exit'
      @nextLevelLink()
      @stop_running = true
      return

    @updateAllowedMove()
    @showExecutionStatus()
    return

  showExecutionStatus: () ->
    if @active_program?
      instruction = @currentInstruction()
      action = @translateInstruction(instruction)
      switch action.type
        when 'move'
          if not @isMoveAllowed(action.dir.dx + @botx, action.dir.dy + @boty)
            @setError('No valid move')
          else
            @setStatus('Running Program, Input: &lt;enter&gt; to move')
        when 'mapping'
          @setStatus('Running Program, Input: &lt;enter&gt; to switch mapping')
        when 'blank'
          @setStatus(
            "Need an action for #{instruction_names[instruction]},
            Input: any direction" +
              (if @available_mappings.length > 0
                 ', &quot;m&quot; to switch mapping'
               else
                 ''))
    else
      @setStatus('Free Running, Input: any direction')

  installMapping: (mapping, action, instruction) ->
    new_action = null

    switch action.type
      when 'move'
        console.log('install')
        new_action = new MoveCommand(action.dir)

    mapping.setMapping(instruction, new_action)

class Mapping
  constructor: () ->
    @instructions = []
    @commands = []

  mapCode: (instruction) ->
    idx = @instructions.indexOf(instruction)

    if idx == -1
      return {type: 'blank'}
    else
      return @commands[idx]

  setMapping: (instruction, command) ->
    idx = @instructions.indexOf(instruction)
    if idx == -1
      idx = @instructions.length
      @instructions[idx] = instruction

    @commands[idx] = command

  render: (ctx, current_instruction) ->
    ocs = g.outer_command_size
    ics = g.inner_command_size

    temp_inst = @instructions
    if current_instruction? and not (current_instruction in @instructions)
      temp_inst = @instructions.concat([current_instruction])

    len = temp_inst.length

    ctx.save()
    g.setStyle(ctx, g.lined_style)

    # container
    ctx.beginPath()
    ctx.moveTo(0,0)
    ctx.lineTo(ocs * 2, 0)
    ctx.lineTo(ocs * 2, ocs * len)
    ctx.lineTo(0, ocs * len)
    ctx.closePath()
    ctx.stroke()

    # vertical divider
    ctx.beginPath()
    ctx.moveTo(ocs, 0)
    ctx.lineTo(ocs, ocs * len)
    ctx.stroke()

    # horizontal dividers
    for idx in [1...len]
      ctx.beginPath()
      ctx.moveTo(0, ocs * idx)
      ctx.lineTo(ocs * 2, ocs * idx)
      ctx.stroke()
    
    # symbols
    ctx.save()
    ctx.translate(ocs/2, ocs/2)
    for char in temp_inst
      g.renderShape(ctx, instruction_names[char], ics/2)
      ctx.translate(0, ocs)
    ctx.restore()

    # commands (if present)
    ctx.translate(ocs*3/2, ocs/2)
    for idx in [0...len]
      if idx of @commands
        @commands[idx].render(ctx)
      else
        ctx.save()
        g.setStyle(ctx, g.lined_style)
        g.renderShape(ctx, 'question', ics/2)
        ctx.restore()

      ctx.translate(0, ocs)

    ctx.restore()

    if current_instruction?
      idx = temp_inst.indexOf(current_instruction)

      ctx.save()
      g.setStyle(ctx, g.lined_style)
      ctx.strokeRect((ocs-ics)/2, (ocs-ics)/2 + ocs*idx, ocs*2-(ocs-ics), ics)
      ctx.restore()

class MoveCommand
  constructor: (@dir) ->

  type: 'move'

  render: (ctx) ->
    ctx.save()
    g.setStyle(ctx, g.lined_style)
    g.renderArrow(ctx, @dir.theta, g.inner_command_size)
    ctx.restore()

window.Dwim = Dwim

