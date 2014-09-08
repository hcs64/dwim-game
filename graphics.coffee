# mostly from obot right now

g = {}

g.cell_size = cell_size = 32

clear_style = fill: 'black'
lined_style = stroke: 'white', width: 1.5, fill: 'black'
pixlined_style = stroke: 'white', width: 1, fill: 'black'
filled_style = fill: 'white'

g.lined_style  = lined_style
bot_style = lined_style

light_link_style = stroke: 'white', width: .5
node_text_style = fill: 'white', font: '16px monospace'
node_text_error_style = fill: 'red', font: '16px monospace'
node_text_spacing = 18
menu_text_style = fill: 'white', font: '16px sans'
menu_text_invert_style = fill: 'black', font: '16px sans'
menu_text_spacing = 18

g.setStyle = setStyle = (ctx, s) ->
  ctx.fillStyle   = s.fill   if s.fill
  ctx.strokeStyle = s.stroke if s.stroke
  ctx.lineWidth   = s.width  if s.width
  ctx.font        = s.font   if s.font

g.clear = (ctx, width, height) ->
  ctx.save()
  setStyle(ctx, clear_style)
  ctx.fillRect(0,0,width,height)
  ctx.restore()

g.border = (ctx, width, height) ->
  ctx.save()
  setStyle(ctx, lined_style)
  ctx.strokeRect(0,0,width,height)
  ctx.restore()

# bot graphics
hr3 = Math.sqrt(3)/2
rr3 = 1/Math.sqrt(3)
g.bot_size = bot_size = cell_size*.75
bot_points = [
  (x: bot_size * rr3, y: 0),
  (x: -bot_size * (hr3-rr3), y: -bot_size/2),
  (x: -bot_size * (hr3-rr3), y: bot_size/2)
]

g.renderBot = (ctx) ->
  bp = bot_points
  ctx.save()
  ctx.translate((@showxi + .5) * cell_size, (@showyi + .5) * cell_size)
  ctx.rotate(-@showdir)

  ctx.beginPath()
  ctx.moveTo(bp[0].x, bp[0].y)
  ctx.lineTo(bp[1].x, bp[1].y)
  ctx.lineTo(bp[2].x, bp[2].y)
  ctx.closePath()

  setStyle(ctx, bot_style)

  ctx.fill()
  ctx.stroke()

  # "eye"
  ctx.beginPath()
  ctx.arc(bot_points[0].x, bot_points[0].y, bot_size/4,
    (1-1/5)*Math.PI, (1+1/5)*Math.PI)
  ctx.stroke()

  ctx.restore()

  return

# obstacle graphics
g.renderMine = (ctx) ->
    setStyle(ctx, pixlined_style)

    ctx.beginPath()
    ctx.moveTo(-cell_size*.35,-cell_size*.35)
    ctx.lineTo(cell_size*.35,cell_size*.35)
    ctx.moveTo(cell_size*.35,-cell_size*.35)
    ctx.lineTo(-cell_size*.35,cell_size*.35)

    ctx.moveTo(0,-cell_size*.4)
    ctx.lineTo(0,cell_size*.4)
    ctx.moveTo(cell_size*.4,0)
    ctx.lineTo(-cell_size*.4,0)
    ctx.stroke()

    ctx.beginPath()
    ctx.arc(0,0, cell_size*.3, 0, Math.PI*2)
    ctx.fill()
    ctx.stroke()

    return
 
g.renderArrow  = (ctx, dir, size) ->
  as = size*.75  # arrow size
  ahs = size*.2 # arrowhead size

  ctx.rotate(-dir)

  ctx.beginPath()
  ctx.moveTo(-as/2, 0)
  ctx.lineTo(as/2, 0)
  ctx.lineTo(as/2-ahs,ahs)
  ctx.moveTo(as/2,0)
  ctx.lineTo(as/2-ahs,-ahs)
  ctx.stroke()

  ctx.rotate(dir)

  return

g.renderShape = (ctx, shape, radius) ->
  ctx.beginPath()
  switch shape
    when 'circle'
      ctx.arc(0,0,radius*.8,0,Math.PI*2)
    when 'square'
      r = radius*.75
      ctx.moveTo(-r,-r)
      ctx.lineTo(-r,+r)
      ctx.lineTo(+r,+r)
      ctx.lineTo(+r,-r)
      ctx.closePath()
    when 'diamond'
      r = radius*Math.SQRT1_2*1.125
      ctx.moveTo(-r,0)
      ctx.lineTo(0,+r)
      ctx.lineTo(+r,0)
      ctx.lineTo(0,-r)
      ctx.closePath()
    when 'hex'
      r = radius * .8
      r2 = r/2
      ctx.moveTo(-r,0)
      ctx.lineTo(-r2,-r)
      ctx.lineTo(+r2,-r)
      ctx.lineTo(+r,0)
      ctx.lineTo(+r2,+r)
      ctx.lineTo(-r2,+r)
      ctx.closePath()

  ctx.stroke()
  return

# command graphics
g.command_size = command_size = 32
g.inner_command_size = inner_command_size = 29
g.outer_command_size = 38
command_scrim_points = do ->
  ics = inner_command_size
  [
    (x: -ics/2, y: -ics/2),
    (x: -ics/2, y: +ics/2),
    (x: +ics/2, y: +ics/2),
    (x: +ics/2, y: -ics/2)
  ]

g.renderCommandScrim = (ctx, current = false) ->
  cs = command_size
  ics = inner_command_size

  ctx.save()
  
  setStyle(ctx, lined_style)

  ctx.strokeRect( -ics/2, -ics/2, ics, ics )

  if current
    setStyle(ctx, filled_style)
    for pt in command_scrim_points
      ctx.fillRect(pt.x-ics*.1, pt.y-ics*.1, ics*.2, ics*.2)
 
  ctx.restore()

  return

# control panel button graphics
controls_start = (x: 10, y: 10)
control_size = 66
inner_control_size = 60
control_bevel = 6
renderControlPanel = (ctx) ->
  ctx.translate(controls_start.x, controls_start.y)

  for b, i in @buttons
    ctx.save()
    
    ctx.lineWidth = 1.5
    if i != @selected_button
      ctx.strokeStyle = 'white'
      ctx.fillStyle = 'black'
    else
      ctx.strokeStyle = 'black'
      ctx.fillStyle = 'white'

    renderButtonScrim(ctx)

    ctx.translate(inner_control_size/2,inner_control_size/2)
    b.render(ctx)
    ctx.restore()
    ctx.translate(0,control_size)

  return

window.dwim_graphics = g
