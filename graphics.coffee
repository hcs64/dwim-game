class DwimGraphics
  constructor: (@parent_div, @game_state) ->
    # constants of layout
    @block = 32

    @record_dims =
      x: 10
      y: 10
      width: @block*10
      height: @block*3
    @mapping_dims =
      x: 10
      y: @record_dims.x+@record_dims.height+@block,
      width: @block*3
      height: @block*10
    @board_dims =
      x: @mapping_dims.x+@mapping_dims.width+@block
      y: @record_dims.y+@record_dims.height+@block
      width: @block*10
      height: @block*10

    @program_fill_style = '#0000c0'
    @grid_stroke_style = '#404040'

    @computeOutlines()

    @sprites = []
    @record_sprites = []
    @addNextRecordSprite()

    # construct the canvas
    @cnv = document.createElement('canvas')
    @cnv.width = @board_dims.x + @board_dims.width + @block
    @cnv.height = @board_dims.y + @board_dims.height + @block
    @parent_div.appendChild(@cnv)
    @ctx = @cnv.getContext('2d')

  instruction_names:
    s: 'square'
    c: 'star'
    d: 'diamond'
    h: 'hex'

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
    for sprite in @sprites
      @ctx.save()
      @ctx.translate(sprite.x, sprite.y)
      sprite.render(sprite)
      @ctx.restore()

    return

  renderFG: ->
    @ctx.save()

    @renderWalls()

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
    @ctx.fillStyle = @program_fill_style
    @ctx.lineWidth = 1
    for x in [0...@game_state.Wi]
      for y in [0...@game_state.Hi]
        switch @game_state.level[x][y].type
          when 'empty'
            @ctx.strokeRect(x*@block-.5, y*@block-.5, @block, @block)
          when 'program'
            @ctx.fillRect(x*@block-.5, y*@block-.5, @block, @block)
            @ctx.strokeRect(x*@block-.5, y*@block-.5, @block, @block)
    @ctx.restore()

  renderBot: (sprite) =>
    @ctx.strokeStyle = 'white'
    @ctx.fillStyle = 'black'
    stretch = 2*(1-Math.abs(sprite.t-.5))
    switch sprite.dir.name
      when 'up', 'down'
        @ctx.scale(1/stretch, stretch)
      else
        @ctx.scale(stretch, 1/stretch)
    @ctx.lineWidth = 1.5
    @renderShape('circle', @block*.4, true)

  makeBotSprite: ->
    gfx = this
    bot =
      computePos: =>
        x: (@game_state.bot.x+.5)*@block+@board_dims.x-.5
        y: (@game_state.bot.y+.5)*@block+@board_dims.y-.5
      render: @renderBot
      animations: []
      t: 0
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

  renderMode: (mode) =>
    ocs = @block
    ics = @block*.75

    temp_inst = mode.instructions
    if @game_state.current_instruction? and
       not (@game_state.current_instruction in mode.instructions)
      temp_inst = mode.instructions.concat([@game_state.current_instruction])

    len = temp_inst.length

    @ctx.strokeStyle = 'white'

    # container
    @ctx.beginPath()
    @ctx.moveTo(0,0)
    @ctx.lineTo(ocs * 2, 0)
    @ctx.lineTo(ocs * 2, ocs * len)
    @ctx.lineTo(0, ocs * len)
    @ctx.closePath()
    @ctx.stroke()

    # vertical divider
    @ctx.beginPath()
    @ctx.moveTo(ocs, 0)
    @ctx.lineTo(ocs, ocs * len)
    @ctx.stroke()

    # horizontal dividers
    for idx in [1...len]
      @ctx.beginPath()
      @ctx.moveTo(0, ocs * idx)
      @ctx.lineTo(ocs * 2, ocs * idx)
      @ctx.stroke()
    
    # symbols
    @ctx.save()
    @ctx.translate(ocs/2, ocs/2)
    for char in temp_inst
      @renderShape(@instruction_names[char], ics/2)
      @ctx.translate(0, ocs)
    @ctx.restore()

    # commands (if present)
    @ctx.save()
    @ctx.translate(ocs*3/2, ocs/2)
    for idx in [0...len]
      if idx of mode.commands
        @renderCommand(mode.commands[idx], ics)
      else
        @renderShape('question', ics/2)

      @ctx.translate(0, ocs)
    @ctx.restore()

    if @game_state.current_instruction?
      idx = temp_inst.indexOf(@game_state.current_instruction)

      @ctx.strokeRect((ocs-ics)/2, (ocs-ics)/2 + ocs*idx, ocs*2-(ocs-ics), ics)

    # id
    @ctx.save()
    @ctx.translate(0,-@block)
    @renderNumber(mode.id)
    @ctx.restore()

  animatePopIn: (scale, pos) ->
    return [ {
      duration: 100
      lerp: [{name: 'scale', v0: 0, v1: scale*1.25}]
      set: [{name: 'x', v: pos.x}, {name: 'y', v: pos.y}]}

      {duration: 25
      lerp: [{name: 'scale', v0: scale*1.25, v1: scale}]}
    ]
  animatePopOut: ->
    return [ { duration: 100, lerp: [{name: 'scale', v0: 1, v1: 0}] } ]

  addNextRecordSprite: ->
    @next_record_sprite =
      x: @record_dims.x + .5 * @block + .5
      y: @record_dims.y + .5 * @block + .5
      render: (sprite) =>
        @ctx.strokeStyle = 'white'
        @ctx.scale(sprite.scale, sprite.scale)
        @renderShape('square', @block*.625)
      scale: 1
      animations: []
    @sprites.push(@next_record_sprite)
  advanceNextRecordSprite: (count) ->
    width = @record_dims.width/@block
    x = @record_dims.x + (.5 + @record_sprites.length%width) * @block + .5
    y = @record_dims.y + (.5 + @record_sprites.length//width) * @block + .5

    if @record_sprites.length%width == 0
      # avoid diagonal flight
      @next_record_sprite.animations.push(
        duration: 75
        lerp: [
          {name: 'x', v1: @record_dims.x + .5*@block + @record_dims.width + .5}
          {name: 'scale', v0: 1, v1: 0}]
      )
      @next_record_sprite.animations.push(
        duration: 50
        set: [ {name: 'y', v: y}, {name: 'scale', v: 1} ]
        lerp: [ {name: 'x', v0: @record_dims.x - @block, v1: x} ]
      )

    else
      @next_record_sprite.animations.push(
        duration: 75
      )
      @next_record_sprite.animations.push(
        duration: 50
        lerp: [
          {name: 'x', v1: x},
          {name: 'y', v1: y}
        ]
      )


  addRecordSprite: (dir) ->
    height = @record_dims.height/@block
    width = @record_dims.width/@block

    sprite =
      x: @record_dims.x + (.5 + @record_sprites.length) * @block + .5
      y: @record_dims.y + .5 * @block + .5
      scale: 0
      render: =>
        if sprite.scale > 0
          @ctx.scale(sprite.scale, sprite.scale)
          @ctx.strokeStyle = 'white'
          @renderArrow(dir.theta, @block)
      animations: []

    while sprite.x > @record_dims.x + @record_dims.width
      sprite.x -= @record_dims.width
      sprite.y += @block

    @record_sprites.push(sprite)

    if @record_sprites.length == height * width
      for old_sprite in @record_sprites[0...width]
        old_sprite.animations = [
          duration: 125
          lerp: [ {name: 'scale', v0: 1, v1: 0},
                  {name: 'y', v1: @record_dims.y-@block} ]
          remove_on_finish: true
        ]
      for old_sprite,i in @record_sprites[width..]
        desty = @record_dims.y+(.5  + i//width)*@block + .5
        if old_sprite == sprite
          # this does a mix of pop in and scroll up
          sprite.animations.push(
            duration: 100
            lerp: [ {name: 'y', v0: sprite.y, v1: (desty-sprite.y)*(100/125)+sprite.y},
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
          old_sprite.animations.push(
            duration: 125
            lerp: [ {name: 'y', v1: desty} ]
          )
      @record_sprites = @record_sprites[width..]
    else
      sprite.animations = @animatePopIn(1, {x:sprite.x, y:sprite.y})


    @advanceNextRecordSprite(1)
    @sprites.push(sprite)


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
      when 'star'
        @ctx.arc(0,0,radius*.8,0,Math.PI)
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
   
    if fill
      @ctx.fill()
    @ctx.stroke()
    return

  renderCommand: (command, size) ->
    switch (command)
      when 'up'
        @renderArrow(UP.theta, size)
      when 'down'
        @renderArrow(DOWN.theta, size)
      when 'left'
        @renderArrow(LEFT.theta, size)
      when 'right'
        @renderArrow(RIGHT.theta, size)
    return

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
