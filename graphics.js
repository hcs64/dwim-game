// Generated by CoffeeScript 1.7.1
(function() {
  var att_lined_style, bot_points, bot_size, bot_style, cell_size, clear_style, command_scrim_points, command_size, digit_graphics, exit_text_style, filled_style, g, hr3, inner_command_size, lined_style, obstacle_cell_style, pixlined_style, program_cell_style, renderNumber, rr3, setStyle, thick_lined_style;

  g = {};

  g.cell_size = cell_size = 32;

  clear_style = {
    fill: 'black'
  };

  lined_style = {
    stroke: 'white',
    width: 1.5,
    fill: 'black'
  };

  att_lined_style = {
    stroke: 'yellow',
    width: 1.5,
    fill: 'black'
  };

  thick_lined_style = {
    stroke: 'white',
    width: 2.5,
    fill: 'black'
  };

  pixlined_style = {
    stroke: 'white',
    width: 1,
    fill: 'black'
  };

  filled_style = {
    fill: 'white'
  };

  exit_text_style = {
    font: '12px monospace',
    fill: 'white',
    align: 'center',
    baseline: 'middle'
  };

  obstacle_cell_style = {
    fill: 'white'
  };

  program_cell_style = {
    fill: 'blue'
  };

  g.thick_lined_style = thick_lined_style;

  g.lined_style = lined_style;

  g.att_lined_style = att_lined_style;

  bot_style = lined_style;

  g.setStyle = setStyle = function(ctx, s) {
    if (s.fill) {
      ctx.fillStyle = s.fill;
    }
    if (s.stroke) {
      ctx.strokeStyle = s.stroke;
    }
    if (s.width) {
      ctx.lineWidth = s.width;
    }
    if (s.font) {
      ctx.font = s.font;
    }
    if (s.align) {
      ctx.textAlign = s.align;
    }
    if (s.baseline) {
      return ctx.textBaseline = s.baseline;
    }
  };

  g.clear = function(ctx, width, height) {
    ctx.save();
    setStyle(ctx, clear_style);
    ctx.fillRect(0, 0, width, height);
    return ctx.restore();
  };

  g.border = function(ctx, width, height) {
    ctx.save();
    setStyle(ctx, lined_style);
    ctx.strokeRect(0, 0, width, height);
    return ctx.restore();
  };

  hr3 = Math.sqrt(3) / 2;

  rr3 = 1 / Math.sqrt(3);

  g.bot_size = bot_size = cell_size * .75;

  bot_points = [
    {
      x: bot_size * rr3,
      y: 0
    }, {
      x: -bot_size * (hr3 - rr3),
      y: -bot_size / 2
    }, {
      x: -bot_size * (hr3 - rr3),
      y: bot_size / 2
    }
  ];

  g.renderBot = function(ctx) {
    var bp;
    bp = bot_points;
    ctx.save();
    ctx.translate((this.showxi + .5) * cell_size, (this.showyi + .5) * cell_size);
    ctx.rotate(-this.showdir);
    ctx.beginPath();
    ctx.moveTo(bp[0].x, bp[0].y);
    ctx.lineTo(bp[1].x, bp[1].y);
    ctx.lineTo(bp[2].x, bp[2].y);
    ctx.closePath();
    setStyle(ctx, bot_style);
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(bot_points[0].x, bot_points[0].y, bot_size / 4, (1 - 1 / 5) * Math.PI, (1 + 1 / 5) * Math.PI);
    ctx.stroke();
    ctx.restore();
  };

  g.renderMine = function(ctx) {
    setStyle(ctx, pixlined_style);
    ctx.beginPath();
    ctx.moveTo(-cell_size * .35, -cell_size * .35);
    ctx.lineTo(cell_size * .35, cell_size * .35);
    ctx.moveTo(cell_size * .35, -cell_size * .35);
    ctx.lineTo(-cell_size * .35, cell_size * .35);
    ctx.moveTo(0, -cell_size * .4);
    ctx.lineTo(0, cell_size * .4);
    ctx.moveTo(cell_size * .4, 0);
    ctx.lineTo(-cell_size * .4, 0);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(0, 0, cell_size * .3, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
  };

  g.renderArrow = function(ctx, dir, size) {
    var ahs, as;
    as = size * .75;
    ahs = size * .2;
    ctx.rotate(-dir);
    ctx.beginPath();
    ctx.moveTo(-as / 2, 0);
    ctx.lineTo(as / 2, 0);
    ctx.lineTo(as / 2 - ahs, ahs);
    ctx.moveTo(as / 2, 0);
    ctx.lineTo(as / 2 - ahs, -ahs);
    ctx.stroke();
    ctx.rotate(dir);
  };

  g.renderShape = function(ctx, shape, radius) {
    var r, r2;
    ctx.beginPath();
    switch (shape) {
      case 'circle':
        ctx.arc(0, 0, radius * .8, 0, Math.PI * 2);
        break;
      case 'square':
        r = radius * .75;
        ctx.moveTo(-r, -r);
        ctx.lineTo(-r, +r);
        ctx.lineTo(+r, +r);
        ctx.lineTo(+r, -r);
        ctx.closePath();
        break;
      case 'diamond':
        r = radius * Math.SQRT1_2 * 1.125;
        ctx.moveTo(-r, 0);
        ctx.lineTo(0, +r);
        ctx.lineTo(+r, 0);
        ctx.lineTo(0, -r);
        ctx.closePath();
        break;
      case 'hex':
        r = radius * .8;
        r2 = r / 2;
        ctx.moveTo(-r, 0);
        ctx.lineTo(-r2, -r);
        ctx.lineTo(+r2, -r);
        ctx.lineTo(+r, 0);
        ctx.lineTo(+r2, +r);
        ctx.lineTo(-r2, +r);
        ctx.closePath();
        break;
      case 'question':
        r = radius * .75;
        ctx.moveTo(-r * .75, -.5 * r);
        ctx.lineTo(-r * .75, -r);
        ctx.lineTo(+r * .75, -r);
        ctx.lineTo(+r * .75, 0);
        ctx.lineTo(0, 0);
        ctx.lineTo(0, .625 * r);
        ctx.moveTo(0, .75 * r);
        ctx.lineTo(0, r);
    }
    ctx.stroke();
  };

  g.command_size = command_size = 32;

  g.inner_command_size = inner_command_size = 29;

  g.outer_command_size = 38;

  command_scrim_points = (function() {
    var ics;
    ics = inner_command_size;
    return [
      {
        x: -ics / 2,
        y: -ics / 2
      }, {
        x: -ics / 2,
        y: +ics / 2
      }, {
        x: +ics / 2,
        y: +ics / 2
      }, {
        x: +ics / 2,
        y: -ics / 2
      }
    ];
  })();

  g.renderCommandScrim = function(ctx, current) {
    var cs, ics, pt, _i, _len;
    if (current == null) {
      current = false;
    }
    cs = command_size;
    ics = inner_command_size;
    ctx.save();
    setStyle(ctx, lined_style);
    ctx.strokeRect(-ics / 2, -ics / 2, ics, ics);
    if (current) {
      setStyle(ctx, filled_style);
      for (_i = 0, _len = command_scrim_points.length; _i < _len; _i++) {
        pt = command_scrim_points[_i];
        ctx.fillRect(pt.x - ics * .1, pt.y - ics * .1, ics * .2, ics * .2);
      }
    }
    ctx.restore();
  };

  g.renderProgramCell = function(ctx, x, y) {
    var cs;
    cs = command_size;
    ctx.save();
    setStyle(ctx, program_cell_style);
    ctx.fillRect(x * cs, y * cs, cs, cs);
    return ctx.restore();
  };

  g.renderObstacleCell = function(ctx, x, y) {
    var cs;
    cs = command_size;
    ctx.save();
    setStyle(ctx, obstacle_cell_style);
    ctx.fillRect(x * cs, y * cs, cs, cs);
    return ctx.restore();
  };

  g.renderExitCell = function(ctx, x, y) {
    var cs;
    cs = command_size;
    setStyle(ctx, exit_text_style);
    ctx.fillText("exit", (x + .5) * cs, (y + .5) * cs);
    setStyle(ctx, lined_style);
    return ctx.strokeRect(x * cs, y * cs, cs, cs);
  };

  digit_graphics = [[[[0, 0], [4, 0], [4, 4], [0, 4], [0, 0]]], [[[2, 0], [2, 4]]], [[[0, 0], [4, 0], [4, 2], [0, 2], [0, 4], [4, 4]]], [[[0, 0], [4, 0], [4, 4], [0, 4]], [[0, 2], [4, 2]]], [[[0, 0], [0, 2], [4, 2]], [[4, 0], [4, 4]]], [[[4, 0], [0, 0], [0, 2], [4, 2], [4, 4], [0, 4]]], [[[4, 0], [0, 0], [0, 4], [4, 4], [4, 2], [0, 2]]], [[[0, 0], [4, 0], [4, 4]]], [[[0, 0], [0, 4], [4, 4], [4, 0], [0, 0]], [[0, 2], [4, 2]]], [[[0, 4], [4, 4], [4, 0], [0, 0], [0, 2], [4, 2]]]];

  g.renderNumber = renderNumber = function(ctx, n, scale) {
    var i, line, point, s, _i, _j, _k, _len, _len1, _ref, _ref1, _ref2;
    if (scale == null) {
      scale = 4;
    }
    s = [];
    if (n < 0 || n !== Math.floor(n)) {
      console.log("tried to render " + number + ", only nonnegative integers supported");
    }
    if (n === 0) {
      s = [0];
    }
    while (n > 0) {
      s[s.length] = n % 10;
      n = Math.floor(n / 10);
    }
    ctx.save();
    for (i = _i = _ref = s.length - 1; _i >= 0; i = _i += -1) {
      ctx.beginPath();
      _ref1 = digit_graphics[s[i]];
      for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
        line = _ref1[_j];
        ctx.moveTo(line[0][0] * scale, line[0][1] * scale);
        _ref2 = line.slice(1);
        for (_k = 0, _len1 = _ref2.length; _k < _len1; _k++) {
          point = _ref2[_k];
          ctx.lineTo(point[0] * scale, point[1] * scale);
        }
      }
      ctx.stroke();
      ctx.translate(5 * scale, 0);
    }
    return ctx.restore();
  };

  window.dwim_graphics = g;

}).call(this);

//# sourceMappingURL=graphics.map
