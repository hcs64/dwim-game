class DwimGraphics
  constructor: (@parent_div, @game_state) ->
    # constants of layout
    @block = 32

    @board_dims = {x: 70, y: 168, width: @block*10, height: @block*10}
    @program_dims = {x: 20, y: 32}
    @mapping_dims = {x: 90, y: 10}
    @proglist_dims = {}

    @program_fill_style = '#0000c0'
    @grid_stroke_style = '#404040'

    @computeOutlines()

    @sprites = []

    # construct the canvas
    @cnv = document.createElement('canvas')
    @cnv.width = @board_dims.x + @board_dims.width + @block
    @cnv.height = @board_dims.y + @board_dims.height + @block
    @parent_div.appendChild(@cnv)
    @ctx = @cnv.getContext('2d')

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

    # grid
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

    @ctx.restore()

  animateSprites: (absolute_t) ->
    for sprite in @sprites
      do_next = true
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
          do_next = true

          if anim.lerp?
            for property in anim.lerp
              sprite[property.name] = property.v1
        else
          if anim.lerp?
            for property in anim.lerp
              sprite[property.name] =
                (property.v1 - property.v0) * t + property.v0

      sprite.leftover_t = 0

  isAnimating: () ->
    for sprite in @sprites
      if sprite.animations? and sprite.animations.length > 0
        return true
    return false
 
  renderSprites: ->
    for sprite in @sprites
      @ctx.save()
      @ctx.translate(sprite.x, sprite.y)
      sprite.render(@ctx)
      @ctx.restore()

    return

  renderFG: ->
    @ctx.save()

    # outlines
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

    @ctx.restore()

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


window.DwimGraphics = DwimGraphics
