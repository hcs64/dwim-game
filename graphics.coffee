# mostly from obot right now

g = {}

g.cell_size = cell_size = 32

g.clear = (ctx, width, height) ->
  ctx.fillStyle = 'black'
  ctx.fillRect(0,0,width,height)

g.border = (ctx, width, height) ->
  ctx.save()
  ctx.strokeStyle = 'white'
  ctx.lineWidth = 1.5
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

g.renderBot = (ctx, dying = 0) ->
  bp = bot_points
  ctx.save()
  ctx.translate((@showxi + .5) * cell_size, (@showyi + .5) * cell_size)
  ctx.rotate(-@showdir)

  ctx.beginPath()
  ctx.moveTo(bp[0].x, bp[0].y)
  ctx.lineTo(bp[1].x, bp[1].y)
  ctx.lineTo(bp[2].x, bp[2].y)
  ctx.closePath()

  ctx.lineWidth = 1.5
  ctx.fillStyle = 'black'

  intensity = Math.floor((1-dying)*(1-dying)*255)
  if dying == 0
    ctx.strokeStyle = 'white'
  else
    ctx.strokeStyle = "rgb(#{intensity},#{intensity},#{intensity})"

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
    ctx.fillStyle = 'black'
    ctx.strokeStyle = 'white'
    ctx.lineWidth = 1

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

  return

# command graphics
command_size = 32
inner_command_size = 29
command_scrim_points = do ->
  ics = inner_command_size
  [
    (x: -ics/2, y: -ics/2),
    (x: -ics/2, y: +ics/2),
    (x: +ics/2, y: +ics/2),
    (x: +ics/2, y: -ics/2)
  ]

g.renderCommand = (ctx, what, where, current, rev = false) ->
  cs = command_size
  ics = inner_command_size

  ctx.save()
  
  ctx.lineWidth = 1.5
  ctx.strokeStyle = 'white'

  ctx.translate(where.x+.5*cs, where.y+.5*cs)

  ctx.strokeRect( -ics/2, -ics/2, ics, ics )

  if current
    ctx.fillStyle = 'white'
    for pt in command_scrim_points
      ctx.fillRect(pt.x-ics*.1, pt.y-ics*.1, ics*.2, ics*.2)
 
  what.render(ctx, rev)
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
