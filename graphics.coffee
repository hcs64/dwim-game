class DwimGraphics
  constructor: (@parent_div, @game_state) ->
    # layout constants
    @block = 32

    @mode_dims =
      x: 10
      y: 10
      width: @block*3
      height: @block*11
    @mode_appearance = [
      {x: 0, y: 0, shape: 'circle'}
      {x: @block*2, y: 0, shape: 'diamond'}
      {x: 0, y: @block*6, shape: 'clover'}
      {x: @block*2, y: @block*6, shape: 'pinch'}]
    @board_dims =
      x: @mode_dims.x+@mode_dims.width+@block
      y: 10+@block/2
      width: @block*10
      height: @block*10
    @clues_dims =
      x: 10
      y: @mode_dims.y+@mode_dims.height
      width: @block*14
      height: @block*6
      Wi: 14
      Hi: 6

    @message_pos =
      x: @board_dims.x + @board_dims.width/2
      y: @board_dims.y + @board_dims.height/2

    @program_fill_style = '#404040'
    @program_stroke_style = '#000000'
    @grid_stroke_style = '#404040'

    @fail_fill_style = '#c00000'
    @win_fill_style = '#00c000'
    @message_bg_fill_style = '#000000'

    @computeOutlines()
    @computeProgramLabels()

    @sprites = []
    @anim_complete_callbacks = []

    @clues = []

    # construct the canvas
    @cnv = document.createElement('canvas')
    @cnv.width = @board_dims.x + @board_dims.width + @block
    @cnv.height = @clues_dims.y + @clues_dims.height + @block
    @parent_div.appendChild(@cnv)
    @ctx = @cnv.getContext('2d')

  instruction_names:
    s: 'square'
    c: 'star'
    d: 'diamond'
    h: 'hex'

  instruction_colors:
    r: '#c00000'  # red
    g: '#00c000'  # green
    b: '#0000c0'  # blue
    p: '#c000c0'  # pink/purple/magenta

  label_letters: ['a','b','c','d','e','f']

  computeOutlines: () ->
    @outline_links = []

    for x in [0..@game_state.Wi]
      was_in = true
      for y in [0..@game_state.Hi]
        is_in = @game_state.level[x][y].type == 'obstacle'
        if was_in and not is_in
          @outline_links.push({
              x0: x*@block, y0: y*@block-1,
              x1: (x+1)*@block-1, y1: y*@block-1})
        if not was_in and is_in
          @outline_links.push({
              x0: x*@block, y0: y*@block,
              x1: (x+1)*@block-1, y1: y*@block})

        was_in = is_in

    for y in [0..@game_state.Hi]
      was_in = true
      for x in [0..@game_state.Wi]
        is_in = @game_state.level[x][y].type == 'obstacle'
        if was_in and not is_in
          @outline_links.push({
            x0: x*@block-1, y0: y*@block,
            x1: x*@block-1, y1: (y+1)*@block-1})
        if not was_in and is_in
          @outline_links.push({
            x0: x*@block, y0: y*@block,
            x1: x*@block, y1: (y+1)*@block-1})

        was_in = is_in

  computeProgramLabels: () ->
    assigned = {}
    @program_labels = []

    for y in [0...@game_state.Hi]
      for x in [0...@game_state.Wi]
        b = @game_state.level[x][y]

        if b.type == 'program' and not assigned[b.id]
          @program_labels[b.id] =
            x: x*@block, y: y*@block, id: b.id
            letter: @label_letters[b.id]
          assigned[b.id] = true

################

  render: (t) ->
    @renderBG()
    @animateSprites(t)
    @renderSprites()
    @renderFG()

    if not @isAnimating()
      if @anim_complete_callbacks.length > 0
        fcn = @anim_complete_callbacks.shift()
        fcn()

  renderBG: ->
    @ctx.save()

    # initial clear
    @ctx.fillStyle = 'black'
    @ctx.fillRect(0, 0, @cnv.width, @cnv.height)

    @renderGrid()
    @renderLabels()

    @ctx.restore()

  animateSprites: (absolute_t) ->
    to_keep = []
    for sprite in @sprites
      do_next = true
      remove = false
      while do_next and sprite.animations.length > 0
        do_next = false
        anim = sprite.animations[0]

        # set constant values
        if anim.set?
          for property in anim.set
            sprite[property.name] = property.v

        # track start time
        if not anim.start_t?
          anim.start_t = absolute_t
          if sprite.leftover_t?
            anim.start_t -= sprite.leftover_t
          sprite.leftover_t = 0
        t = (absolute_t - anim.start_t) / anim.duration

        # interpolate
        if t >= 1
          # hit the end of the animation
          sprite.leftover_t = absolute_t - (anim.start_t + anim.duration)
          sprite.animations.shift()

          if anim.remove_on_finish
            remove = true
          else
            do_next = true

          if anim.lerp?
            for property in anim.lerp
              sprite[property.name] = property.v1
        else
          if anim.lerp?
            for property in anim.lerp
              if not property.v0?
                property.v0 = sprite[property.name]
              sprite[property.name] =
                (property.v1 - property.v0) * t + property.v0

      sprite.leftover_t = 0
      if not remove
        to_keep.push(sprite)
    @sprites = to_keep

  isAnimating: () ->
    for sprite in @sprites
      if sprite.animations? and sprite.animations.length > 0
        return true
    return false
 
  renderSprites: ->
    for idx in [@sprites.length-1..0]
      sprite = @sprites[idx]
      @ctx.save()
      @ctx.translate(sprite.x, sprite.y)
      sprite.render(sprite)
      @ctx.restore()

    return

  renderFG: ->
    @ctx.save()

    @renderWalls()

    if @game_state.halted
      if @game_state.won
        @renderMessage(@win_fill_style, 'Click to continue')
      else
        @renderMessage(@fail_fill_style, 'Click to retry')
    else

    @ctx.restore()

################

  renderWalls: ->
    @ctx.save()
    @ctx.translate(@board_dims.x, @board_dims.y)
    @ctx.lineWidth = 2
    @ctx.lineCap = 'round'
    @ctx.strokeStyle = 'white'
    @ctx.beginPath()
    for {x0:x0,y0:y0,x1:x1,y1:y1} in @outline_links
      @ctx.moveTo(x0,y0)
      @ctx.lineTo(x1,y1)
    @ctx.stroke()
    @ctx.restore()

  renderGrid: ->
    @ctx.save()
    @ctx.translate(@board_dims.x, @board_dims.y)
    @ctx.strokeStyle = @grid_stroke_style
    @ctx.lineWidth = 1
    for x in [0...@game_state.Wi]
      for y in [0...@game_state.Hi]
        switch @game_state.level[x][y].type
          when 'empty'
            @ctx.strokeRect(x*@block-.5, y*@block-.5, @block, @block)
    @ctx.strokeStyle = @program_stroke_style
    @ctx.fillStyle = @program_fill_style
    for x in [0...@game_state.Wi]
      for y in [0...@game_state.Hi]
        switch @game_state.level[x][y].type
          when 'program'
            @ctx.fillRect(x*@block-.5, y*@block-.5, @block, @block)
            @ctx.strokeRect(x*@block-.5, y*@block-.5, @block, @block)
    @ctx.strokeStyle = 'white'
    @ctx.lineWidth = 1.5
    for x in [0...@game_state.Wi]
      for y in [0...@game_state.Hi]
        switch @game_state.level[x][y].type
          when 'exit'
            @ctx.save()
            @ctx.translate((x+.5)*@block-.5, (y+.5)*@block-.5)
            @renderShape('star5', @block*.375)
            @ctx.restore()
    @ctx.restore()

  renderBot: (sprite) =>
    stretch = 2*(1-Math.abs(sprite.t-.5))
    switch sprite.dir.name
      when 'up', 'down'
        @ctx.scale(1/stretch, stretch)
      else
        @ctx.scale(stretch, 1/stretch)
    @renderBotMode(@game_state.current_mode.idx, sprite.scale*@block)

  makeBotSprite: ->
    gfx = this
    bot =
      computePos: =>
        x: (@game_state.bot.x+.5)*@block+@board_dims.x-.5
        y: (@game_state.bot.y+.5)*@block+@board_dims.y-.5
      render: @renderBot
      animations: []
      t: 0
      scale: 1
      leftover_t: 0
      dir: {name: 'down'}
      animateMove: (old_pos, dir) ->
        new_pos = @computePos()
        @animations.push(
          duration: 150
          lerp: [ {name: 't', v0: 0, v1: 1},
                  {name: 'x', v0: old_pos.x, v1: new_pos.x},
                  {name: 'y', v0: old_pos.y, v1: new_pos.y}
                ]
          set: [ {name: 'dir', v: dir} ]
        )
      animateBump: (old_pos, dir) ->
        howfar = .15*gfx.block
        new_pos = x: old_pos.x+dir.dx*howfar, y: old_pos.y+dir.dy*howfar
        @animations.push(
          duration: 15
          lerp: [{name: 't', v0: 0, v1: .1},
                 {name: 'x', v0: old_pos.x, v1: new_pos.x},
                 {name: 'y', v0: old_pos.y, v1: new_pos.y}
                ]
          set: [ {name: 'dir', v: dir} ]
        )
        @animations.push(
          duration: 50
          lerp: [{name: 't', v0: .1, v1: 0}]
        )
        @animations.push(
          duration: 50
          lerp: [{name: 't', v0: 0, v1: .1},
                 {name: 'x', v0: new_pos.x, v1: (new_pos.x+old_pos.x)/2},
                 {name: 'y', v0: new_pos.y, v1: (new_pos.y+old_pos.y)/2}
                ]
        )
        @animations.push(
          duration: 50
          lerp: [{name: 't', v0: .1, v1: 0},
                {name: 'x', v0: (new_pos.x+old_pos.x)/2, v1: old_pos.x},
                {name: 'y', v0: (new_pos.y+old_pos.y)/2, v1: old_pos.y}
               ]
        )

    {x:bot.x, y:bot.y} = bot.computePos()

    return bot

  makeModeSprites: ->
    mode_sprites = []
    for mode,i in @game_state.modes
      sprite =
        x: @mode_dims.x+.5+@mode_appearance[i].x
        y: @mode_dims.y+.5+@mode_appearance[i].y
        mode: mode
        render: @renderModeSprite
        scale: 1
        animations: []
      mode_sprites.push(sprite)

    return mode_sprites


  renderModeSprite: (sprite) =>
    mode = sprite.mode
    ocs = @block
    ics = @block*.875

    temp_sym = mode.symbols
    current_symbol = null

    @ctx.strokeStyle = 'white'

    if mode == @game_state.current_mode
      @ctx.save()

      @ctx.lineWidth = 2.5*sprite.scale
      @ctx.strokeRect(-@block*.25,-@block*.25,@block*1.75,@block*5.5)

      @ctx.restore()
      
      if @game_state.current_program.length > 0

        current_symbol = @game_state.current_program[0]
        if not (@game_state.current_program[0] in mode.symbols)
          temp_sym = mode.symbols.concat([current_symbol])

    len = temp_sym.length

    # idx
    @renderNumber(mode.idx+1)

    # bot version
    @ctx.save()
    @ctx.translate(@block+.5, @block*.25+.5)

    @renderBotMode(mode.idx, @block*sprite.scale)
    @ctx.restore()

    @ctx.translate(@block*.125,@block)

    # commands (if present)
    @ctx.save()
    @ctx.translate(ocs/2, ocs/2)
    for sym in temp_sym
      @ctx.fillStyle = @instruction_colors[sym]
      @ctx.fillRect(-ocs/2-.5, -ocs/2-.5, ocs, ocs)
      @ctx.strokeRect(-ocs/2, -ocs/2, ocs, ocs)
      if sym of mode.lookup
        @renderCommand(mode.lookup[sym], ocs)
      else
        @renderShape('question', ocs/2)

      @ctx.translate(0, ocs)
    @ctx.restore()

    if current_symbol?
      idx = temp_sym.indexOf(current_symbol)

      @ctx.save()
      @ctx.strokeStyle = 'yellow'
      @ctx.lineWidth = 4
      @ctx.strokeRect(-.5, -.5+idx*ocs, ocs, ocs)
      @ctx.restore()

  animatePopIn: (anims, low_scale, scale, pos) ->
    pop_0 =
      duration: 100
      lerp: [{name: 'scale', v0: low_scale, v1: scale*1.25}]
    if pos?
      pop_0.set = [{name: 'x', v: pos.x}, {name: 'y', v: pos.y}]

    pop_1 =
      duration: 25
      lerp: [{name: 'scale', v0: scale*1.25, v1: scale}]

    anims.push(pop_0)
    anims.push(pop_1)

  renderBotMode: (mode, radius) ->
    if radius == 0
      return
    mode_appearance = @mode_appearance[mode]

    @ctx.strokeStyle = 'white'
    @ctx.fillStyle = 'black'

    @ctx.lineWidth = 1.5
    @renderShape(mode_appearance.shape, radius*.4, true)
 
  renderLabels: ->
    @ctx.save()

    @ctx.translate(@board_dims.x+.5+@block/16, @board_dims.y+.5+@block/16)
    @ctx.strokeStyle = 'white'
    @ctx.lineWidth = 1

    for label in @program_labels
      @ctx.save()
      @ctx.translate(label.x, label.y)
      @renderLetter(label.letter)
      @ctx.restore()

  makeCluesSprite: ->
    x: @clues_dims.x+@block*.5
    y: @clues_dims.y+@block*.5
    program_id: -1
    program_idx: 0
    render: @renderClues
    animations: []

  renderClues: (sprite) =>
    bs = @block * .875
    
    xi = 0
    yi = 0

    for label in @program_labels
      program = @game_state.programs[label.id]
      if xi + program.code.length + 2 >= @clues_dims.Wi
        @ctx.translate(-xi*@block, @block*1.5)
        xi = 0
        yi += 1.5

      @ctx.strokeStyle = 'white'

      @ctx.save()
      @ctx.translate(.5, .5+@block*.125)
      @renderLetter(label.letter, @block*.75)
      @ctx.restore()

      @ctx.translate(@block, 0)
      xi += 1

      pid = sprite.program_id
      highlight = xi + sprite.program_idx

      if pid == label.id
        mode = 'unknown'
      else
        mode = @game_state.current_mode

      for idx in [0...program.code.length]
        command = program.code.charAt(idx)
        @ctx.fillStyle = @instruction_colors[command]
        @ctx.fillRect(0,0,bs,bs)
        
        if mode != 'unknown'
          action = mode.lookup[command]

          @ctx.translate(bs/2+.5, bs/2+.5)
          if action?
            @renderCommand(mode.lookup[command], @block)

            if action.type == 'mode'
              mode = @game_state.modes[action.idx]
          else
            @renderShape('question', @block/2)
            mode = 'unknown'
          @ctx.translate(-bs/2-.5, -bs/2-.5)

        @ctx.translate(@block, 0)
        xi += 1

      if pid == label.id
        @ctx.save()
        @ctx.translate(-(xi-highlight)*@block, 0)
        @ctx.strokeStyle = 'yellow'
        @ctx.lineWidth = 4
        @ctx.strokeRect(0,0,bs,bs)
        @ctx.restore()

      @ctx.translate(@block, 0)
      xi += 1

  renderMessage: (fill_style, message) ->
    @ctx.save()
    @ctx.font = 'bold 16px monospace'
    @ctx.textAlign = 'center'
    @ctx.textBaseline = 'middle'

    @ctx.fillStyle = @message_bg_fill_style
    width = @ctx.measureText(message).width
    @ctx.fillRect(@message_pos.x-width/2-16, @message_pos.y-16, width+32, 32)

    @ctx.fillStyle = fill_style
    @ctx.fillText(message, @message_pos.x, @message_pos.y)
    @ctx.restore()

  onAnimComplete: (fcn) ->
    @anim_complete_callbacks.push(fcn)

################

  renderArrow: (dir, size) ->
    as = size*.75  # arrow size
    ahs = size*.2 # arrowhead size

    @ctx.rotate(-dir)

    @ctx.beginPath()
    @ctx.moveTo(-as/2, 0)
    @ctx.lineTo(as/2, 0)
    @ctx.lineTo(as/2-ahs,ahs)
    @ctx.moveTo(as/2,0)
    @ctx.lineTo(as/2-ahs,-ahs)
    @ctx.stroke()

    @ctx.rotate(dir)

    return

  renderShape: (shape, radius, fill=false) ->
    @ctx.beginPath()
    switch shape
      when 'circle'
        @ctx.arc(0,0,radius*.8,0,Math.PI*2)
      when 'star8', 'star5'
        sides = if shape == 'star8' then 8 else 5
        inner = radius*.5
        @ctx.moveTo(0, -radius)
        @ctx.save()
        for i in [0...sides]
          @ctx.rotate(Math.PI/sides)
          @ctx.lineTo(0, -inner)
          @ctx.rotate(Math.PI/sides)
          @ctx.lineTo(0, -radius)
        @ctx.restore()
      when 'square'
        r = radius*.75
        @ctx.moveTo(-r,-r)
        @ctx.lineTo(-r,+r)
        @ctx.lineTo(+r,+r)
        @ctx.lineTo(+r,-r)
        @ctx.closePath()
      when 'diamond'
        r = radius*Math.SQRT1_2*1.125
        @ctx.moveTo(-r,0)
        @ctx.lineTo(0,+r)
        @ctx.lineTo(+r,0)
        @ctx.lineTo(0,-r)
        @ctx.closePath()
      when 'hex'
        r = radius * .8
        r2 = r/2
        @ctx.moveTo(-r,0)
        @ctx.lineTo(-r2,-r)
        @ctx.lineTo(+r2,-r)
        @ctx.lineTo(+r,0)
        @ctx.lineTo(+r2,+r)
        @ctx.lineTo(-r2,+r)
        @ctx.closePath()
      when 'question'
        r = radius*.75
        @ctx.moveTo(-r*.75, -.5*r)
        @ctx.lineTo(-r*.75, -r)
        @ctx.lineTo(+r*.75, -r)
        @ctx.lineTo(+r*.75, 0)
        @ctx.lineTo(0, 0)
        @ctx.lineTo(0, .625*r)
        @ctx.moveTo(0, .75*r)
        @ctx.lineTo(0, r)
      when 'octagon'
        ics = radius*1.75
        cb = radius*.5  #bevel
        ox = -ics/2
        oy = -ics/2
        @ctx.translate(ox,oy)
        @ctx.beginPath()
        @ctx.moveTo(0, cb)
        @ctx.lineTo(cb, 0)
        @ctx.lineTo(ics-cb, 0)
        @ctx.lineTo(ics, cb)
        @ctx.lineTo(ics, ics-cb)
        @ctx.lineTo(ics-cb, ics)
        @ctx.lineTo(cb, ics)
        @ctx.lineTo(0, ics-cb)
        @ctx.closePath()
      when 'clover'
        r = radius*.75
        r2 = r/2
        @ctx.moveTo(0,-r2)
        @ctx.arc( r2,-r2, r2,     Math.PI, -1.5*Math.PI)
        @ctx.arc( r2, r2, r2, -.5*Math.PI,      Math.PI)
        @ctx.arc(-r2, r2, r2,           0,  -.5*Math.PI)
        @ctx.arc(-r2,-r2, r2,-1.5*Math.PI,    0)
      when 'pinch'
        r = radius*.75
        @ctx.moveTo(-r,-r)
        @ctx.quadraticCurveTo(0,0, r,-r)
        @ctx.quadraticCurveTo(0,0, r, r)
        @ctx.quadraticCurveTo(0,0,-r, r)
        @ctx.quadraticCurveTo(0,0,-r,-r)
  
    if fill
      @ctx.fill()
    @ctx.stroke()
    return

  renderCommand: (command, size) ->
    @ctx.save()
    switch command.type
      when 'move'
        @renderArrow(command.dir.theta, size)
      when 'mode'
        @renderBotMode(command.idx, size)
    @ctx.restore()

  digit_graphics: [
    # 0
    [ [[0,0],[4,0],[4,4],[0,4],[0,0]] ],
    # 1
    [ [[2,0],[2,4]] ],
    # 2
    [ [[0,0],[4,0],[4,2],[0,2],[0,4],[4,4]] ],
    # 3
    [ [[0,0],[4,0],[4,4],[0,4]],
      [[0,2],[4,2]] ],
    # 4
    [ [[0,0],[0,2],[4,2]],
      [[4,0],[4,4]] ],
    # 5
    [ [[4,0],[0,0],[0,2],[4,2],[4,4],[0,4]] ],
    # 6
    [ [[4,0],[0,0],[0,4],[4,4],[4,2],[0,2]] ],
    # 7
    [ [[0,0],[4,0],[4,4]] ],
    # 8
    [ [[0,0],[0,4],[4,4],[4,0],[0,0]],
      [[0,2],[4,2]] ],
    # 9
    [ [[0,4],[4,4],[4,0],[0,0],[0,2],[4,2]] ]
  ]

  renderNumber: (n, scale = 4) ->
    s = []
    if n < 0 or n != Math.floor(n)
      console.log("tried to render #{number}, only nonnegative integers supported")
    if n == 0
      s = [0]
    while n > 0
      s[s.length] = n % 10
      n = Math.floor(n / 10)

    @ctx.save()

    for i in [s.length-1..0] by -1
      @ctx.beginPath()
      for line in @digit_graphics[s[i]]
        @ctx.moveTo(line[0][0]*scale, line[0][1]*scale)
        for point in line[1..]
          @ctx.lineTo(point[0]*scale, point[1]*scale)
      @ctx.stroke()

      @ctx.translate(5*scale, 0)

    @ctx.restore()

  letterGraphics: {
    a: [ [[0,1],[1.5,1],[1.5,3],[0,3],[0,2],[1.5,2]] ]
    b: [ [[0,0],[0,3],[1.5,3],[1.5,1.5],[0,1.5]] ]
    c: [ [[1.5,1],[0,1],[0,3],[1.5,3]] ]
    d: [ [[2,0],[2,3],[.5,3],[.5,1.5],[2,1.5]] ]
    e: [ [[0,2],[1.5,2],[1.5,1],[0,1],[0,3],[1.5,3]] ]
    f: [ [[.5,1.5],[1.5,1.5]], [[2,0],[1,0],[1,3]] ]
  }

  renderLetter: (l, scale = @block/2) ->

    g = @letterGraphics[l]
    if not g?
      return

    @ctx.beginPath()
    for line in g
      @ctx.moveTo(line[0][0]/4*scale, line[0][1]/4*scale)
      for point in line[1..]
        @ctx.lineTo(point[0]/4*scale, point[1]/4*scale)
    @ctx.stroke()

window.DwimGraphics = DwimGraphics
