class DwimGraphics
  constructor: (@parent_div, @game_state) ->
    # constants of layout
    @block = 32

    @mode_dims =
      x: 10
      y: 72
      width: @block*3
      height: @block*10
    @mode_appearance = [
      {x: 0, y: 0, invert: false, circle: true},
      {x: @block*2, y: 0, invert: true, circle: true},
      {x: 0, y: @block*6, invert: false, circle: false},
      {x: @block*2, y: @block*6, invert: true, circle: false}]
    @record_dims =
      x: @mode_dims.x + @mode_dims.width + @block
      y: 10
      width: @block*10
      height: @block*2
      Wi: 10
      Hi: 2
    @board_dims =
      x: @mode_dims.x+@mode_dims.width+@block
      y: @record_dims.y+@record_dims.height+@block
      width: @block*10
      height: @block*10
    @clues_dims =
      x: 10
      y: @board_dims.y+@board_dims.height
      width: @block*14
      height: @block*2
      Wi: 14
      Hi: 2

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

    @sprites = []
    @anim_complete_callbacks = []
    @record_sprites = []
    @record_sprite_clock = 0
    @addNextRecordSprite()

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
    s: '#c00000'  # red
    c: '#00c000'  # green
    d: '#0000c0'  # blue
    h: '#c000c0'  # purple

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

    @renderClues()

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
    if mode == @game_state.current_mode and
       @game_state.current_program.length > 0

      current_symbol = @game_state.current_program[0]
      if not (@game_state.current_program[0] in mode.symbols)
        temp_sym = mode.symbols.concat([current_symbol])

    len = temp_sym.length

    @ctx.strokeStyle = 'white'

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

      @ctx.lineWidth = 3
      @ctx.strokeRect(0, 0+idx*ocs, ocs, ocs)

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

  addNextRecordSprite: ->
    nrs = @next_record_sprite =
      xi: 0
      yi: 0
      gfx: this
      computePos: ->
        x: @gfx.record_dims.x + (.5 + @xi) * @gfx.block
        y: @gfx.record_dims.y + (.5 + @yi) * @gfx.block
      render: (sprite) =>
        @ctx.strokeStyle = 'white'
        @ctx.lineWidth = 2
        if sprite.scale > 0
          @ctx.scale(sprite.scale, sprite.scale)
          @renderShape('square', @block*.625)
      scale: 1
      clock: 0
      animations: []
    {x:nrs.x, y:nrs.y} = nrs.computePos()
    @sprites.push(nrs)

  advanceNextRecordSprite: (count) ->
    nrs = @next_record_sprite
    width = @record_dims.Wi
    old_pos = {xi: nrs.xi, yi: nrs.yi}
    nrs.clock += count
    
    nrs.xi = nrs.clock
    nrs.yi = 0
    if @record_sprites.length > 0
      nrs.xi -= @record_sprites[0].clock

    while nrs.xi >= width
      nrs.xi -= width
      nrs.yi += 1

    {x:x, y:y} = nrs.computePos()

    if count == 0
      # everything is scrolling
      @next_record_sprite.animations.push(
        duration: 125
        lerp: [
          {name: 'x', v1: x},
          {name: 'y', v1: y}
        ]
      )
    else
      # wait a bit for pop
      @next_record_sprite.animations.push(
        duration: 50
      )
      @next_record_sprite.animations.push(
        duration: 75
        lerp: [
          {name: 'x', v1: x},
          {name: 'y', v1: y}
        ]
      )

  renderRecordSpriteArrow: (sprite) =>
    if sprite.scale > 0
      @ctx.scale(sprite.scale, sprite.scale)
      if sprite.programmed
        bs = @block * 7/16
        @ctx.fillStyle = @instruction_colors[sprite.command]
        @ctx.fillRect(-bs-.5, -bs-.5, bs*2, bs*2)
      @ctx.strokeStyle = 'white'

      if sprite.dir?
        @renderArrow(sprite.dir.theta, @block)
      else
        @renderBotMode(sprite.mode_idx, @block)

  renderBotMode: (mode, radius) ->
    if radius == 0
      return
    mode_appearance = @mode_appearance[mode]
    if mode_appearance.invert
      @ctx.strokeStyle = 'white'
      @ctx.fillStyle = 'white'
    else
      @ctx.strokeStyle = 'white'
      @ctx.fillStyle = 'black'

    @ctx.lineWidth = 1.5
    if mode_appearance.circle
      @renderShape('circle', radius*.4, true)
    else
      @renderShape('diamond', radius*.4, true)
 
  # record sprite insertion behaviors
  # normal: pop in
  # last column in all-but-last row: pop
  # last column in last row: pop and scroll
  addRecordSprite: (move) ->
    height = @record_dims.Hi
    width = @record_dims.Wi

    sprite =
      x: @record_dims.x + (.5 + @record_sprites.length) * @block + .5
      y: @record_dims.y + .5 * @block + .5
      scale: 0
      render: @renderRecordSpriteArrow
      programmed: false
      clock: @record_sprite_clock
      animations: []

    if move.type == 'move'
      sprite.dir = move.dir
    else
      sprite.mode_idx = move.idx

    while sprite.x > @record_dims.x + @record_dims.width
      sprite.x -= @record_dims.width
      sprite.y += @block

    @record_sprites.push(sprite)
    @record_sprite_clock += 1

    if @record_sprites.length == height * width
      @scrollRecordSprites([sprite])
    else
      @animatePopIn(sprite.animations, 0, 1, {x:sprite.x, y:sprite.y})

    @advanceNextRecordSprite(1)

    @sprites.push(sprite)

  addProgramSprites: () ->
    new_sprites = []
    for command in @game_state.current_program
      height = @record_dims.Hi
      width = @record_dims.Wi

      sprite =
        x: @record_dims.x + (.5 + @record_sprites.length) * @block + .5
        y: @record_dims.y + .5 * @block + .5
        scale: 0
        command: command
        programmed: true
        render: (sprite) =>
          if sprite.scale > 0
            @ctx.scale(sprite.scale, sprite.scale)
            bs = @block * 7/16
            @ctx.fillStyle = @instruction_colors[sprite.command]
            @ctx.fillRect(-bs-.5, -bs-.5, bs*2, bs*2)
        clock: @record_sprite_clock
        animations: []

      while sprite.x > @record_dims.x + @record_dims.width
        sprite.x -= @record_dims.width
        sprite.y += @block

      @record_sprites.push(sprite)
      @record_sprite_clock += 1
      new_sprites.push(sprite)

    if @record_sprites.length >= height * width
      @scrollRecordSprites(new_sprites)
    else
      for sprite in new_sprites
        @animatePopIn(sprite.animations, 0, 1, {x:sprite.x, y:sprite.y})

    @sprites = @sprites.concat(new_sprites)
        
  replaceNextRecordSprite: (move) ->
    for sprite in @record_sprites
      if sprite.clock == @next_record_sprite.clock
        sprite.render = @renderRecordSpriteArrow
        if move.type == 'move'
          sprite.dir = move.dir
        else
          sprite.mode_idx = move.idx
        sprite.programmed = true
        @animatePopIn(sprite.animations, 1, 1)
    @advanceNextRecordSprite(1)

  scrollRecordSprites: (new_sprites) ->
    width = @record_dims.Wi
    for sprite in @record_sprites[0...width]
      sprite.animations.push(
        duration: 125
        lerp: [ {name: 'scale', v0: 1, v1: 0},
                {name: 'y', v1: @record_dims.y-@block} ]
        remove_on_finish: true
      )
      
    @record_sprites = @record_sprites[width..]

    for sprite,i in @record_sprites
      desty = @record_dims.y+(.5  + i//width)*@block + .5
      if sprite in new_sprites
        # this does a mix of pop in and scroll up
        sprite.animations.push(
          duration: 100
          lerp: [ {name: 'y', v1: (desty-sprite.y)*(100/125)+sprite.y},
                  {name: 'scale', v0: 0, v1: 1.25}
                ]
        )
        sprite.animations.push(
          duration: 25
          lerp: [ {name: 'y', v1: desty},
                  {name: 'scale', v1: 1}
                ]
        )
      else
        sprite.animations = [
          duration: 125
          lerp: [ {name: 'y', v1: desty} ]
          set: [ {name: 'scale', v: 1} ]
        ]

    @advanceNextRecordSprite(0)

  showClue: (where) ->
    if where == null
      @clues = []
      return

    xi = (where.x - @board_dims.x)//@block
    yi = (where.y - @board_dims.y)//@block

    if @game_state.level[xi]? and @game_state.level[xi][yi]? and
       @game_state.level[xi][yi].type == 'program'
      @clues = [ @game_state.programs[@game_state.level[xi][yi].id] ]
    else
      @clues = []

  renderClues: ->
    if @clues.length == 0
      return

    @ctx.save()

    clue = @clues[0]

    @ctx.translate(@clues_dims.x+@block*.5, @clues_dims.y+@block*.5)
    bs = @block * .875
    
    xi = 0
    for idx in [0...clue.code.length]
      command = clue.code.charAt(idx)
      @ctx.fillStyle = @instruction_colors[command]
      @ctx.fillRect(0,0,bs,bs)
      @ctx.translate(@block, 0)

      xi += 1
      if xi >= @clues_dims.Wi
        @ctx.translate(-xi*@block, @block)
        xi = 0

    @ctx.restore()

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
  
    if fill
      @ctx.fill()
    @ctx.stroke()
    return

  renderCommand: (command, size) ->
    switch command.type
      when 'move'
        @renderArrow(command.dir.theta, size)
      when 'mode'
        @renderBotMode(command.idx, size)

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

window.DwimGraphics = DwimGraphics
