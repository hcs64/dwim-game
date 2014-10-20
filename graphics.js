// Generated by CoffeeScript 1.7.1
(function() {
  var DwimGraphics,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  DwimGraphics = (function() {
    function DwimGraphics(parent_div, game_state) {
      this.parent_div = parent_div;
      this.game_state = game_state;
      this.renderModeSprite = __bind(this.renderModeSprite, this);
      this.renderBot = __bind(this.renderBot, this);
      this.block = 32;
      this.mode_dims = {
        x: 10,
        y: 10,
        width: this.block * 3,
        height: this.block * 11
      };
      this.mode_appearance = [
        {
          x: 0,
          y: 0,
          shape: 'circle'
        }, {
          x: this.block * 2,
          y: 0,
          shape: 'diamond'
        }, {
          x: 0,
          y: this.block * 6,
          shape: 'clover'
        }, {
          x: this.block * 2,
          y: this.block * 6,
          shape: 'pinch'
        }
      ];
      this.board_dims = {
        x: this.mode_dims.x + this.mode_dims.width + this.block,
        y: 10 + this.block / 2,
        width: this.block * 10,
        height: this.block * 10
      };
      this.clues_dims = {
        x: 10,
        y: this.mode_dims.y + this.mode_dims.height,
        width: this.block * 14,
        height: this.block * 6,
        Wi: 14,
        Hi: 6
      };
      this.message_pos = {
        x: this.board_dims.x + this.board_dims.width / 2,
        y: this.board_dims.y + this.board_dims.height / 2
      };
      this.program_fill_style = '#404040';
      this.program_stroke_style = '#000000';
      this.grid_stroke_style = '#404040';
      this.fail_fill_style = '#c00000';
      this.win_fill_style = '#00c000';
      this.message_bg_fill_style = '#000000';
      this.computeOutlines();
      this.computeProgramLabels();
      this.sprites = [];
      this.anim_complete_callbacks = [];
      this.clues = [];
      this.cnv = document.createElement('canvas');
      this.cnv.width = this.board_dims.x + this.board_dims.width + this.block;
      this.cnv.height = this.clues_dims.y + this.clues_dims.height + this.block;
      this.parent_div.appendChild(this.cnv);
      this.ctx = this.cnv.getContext('2d');
    }

    DwimGraphics.prototype.instruction_names = {
      s: 'square',
      c: 'star',
      d: 'diamond',
      h: 'hex'
    };

    DwimGraphics.prototype.instruction_colors = {
      r: '#c00000',
      g: '#00c000',
      b: '#0000c0',
      p: '#c000c0'
    };

    DwimGraphics.prototype.label_letters = ['a', 'b', 'c', 'd', 'e', 'f'];

    DwimGraphics.prototype.computeOutlines = function() {
      var is_in, was_in, x, y, _i, _j, _k, _ref, _ref1, _ref2, _results;
      this.outline_links = [];
      for (x = _i = 0, _ref = this.game_state.Wi; 0 <= _ref ? _i <= _ref : _i >= _ref; x = 0 <= _ref ? ++_i : --_i) {
        was_in = true;
        for (y = _j = 0, _ref1 = this.game_state.Hi; 0 <= _ref1 ? _j <= _ref1 : _j >= _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
          is_in = this.game_state.level[x][y].type === 'obstacle';
          if (was_in && !is_in) {
            this.outline_links.push({
              x0: x * this.block,
              y0: y * this.block - 1,
              x1: (x + 1) * this.block - 1,
              y1: y * this.block - 1
            });
          }
          if (!was_in && is_in) {
            this.outline_links.push({
              x0: x * this.block,
              y0: y * this.block,
              x1: (x + 1) * this.block - 1,
              y1: y * this.block
            });
          }
          was_in = is_in;
        }
      }
      _results = [];
      for (y = _k = 0, _ref2 = this.game_state.Hi; 0 <= _ref2 ? _k <= _ref2 : _k >= _ref2; y = 0 <= _ref2 ? ++_k : --_k) {
        was_in = true;
        _results.push((function() {
          var _l, _ref3, _results1;
          _results1 = [];
          for (x = _l = 0, _ref3 = this.game_state.Wi; 0 <= _ref3 ? _l <= _ref3 : _l >= _ref3; x = 0 <= _ref3 ? ++_l : --_l) {
            is_in = this.game_state.level[x][y].type === 'obstacle';
            if (was_in && !is_in) {
              this.outline_links.push({
                x0: x * this.block - 1,
                y0: y * this.block,
                x1: x * this.block - 1,
                y1: (y + 1) * this.block - 1
              });
            }
            if (!was_in && is_in) {
              this.outline_links.push({
                x0: x * this.block,
                y0: y * this.block,
                x1: x * this.block,
                y1: (y + 1) * this.block - 1
              });
            }
            _results1.push(was_in = is_in);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    DwimGraphics.prototype.computeProgramLabels = function() {
      var assigned, b, x, y, _i, _ref, _results;
      assigned = {};
      this.program_labels = [];
      _results = [];
      for (y = _i = 0, _ref = this.game_state.Hi; 0 <= _ref ? _i < _ref : _i > _ref; y = 0 <= _ref ? ++_i : --_i) {
        _results.push((function() {
          var _j, _ref1, _results1;
          _results1 = [];
          for (x = _j = 0, _ref1 = this.game_state.Wi; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; x = 0 <= _ref1 ? ++_j : --_j) {
            b = this.game_state.level[x][y];
            if (b.type === 'program' && !assigned[b.id]) {
              this.program_labels[b.id] = {
                x: x * this.block,
                y: y * this.block,
                id: b.id,
                letter: this.label_letters[b.id]
              };
              _results1.push(assigned[b.id] = true);
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    DwimGraphics.prototype.render = function(t) {
      var fcn;
      this.renderBG();
      this.animateSprites(t);
      this.renderSprites();
      this.renderFG();
      if (!this.isAnimating()) {
        if (this.anim_complete_callbacks.length > 0) {
          fcn = this.anim_complete_callbacks.shift();
          return fcn();
        }
      }
    };

    DwimGraphics.prototype.renderBG = function() {
      this.ctx.save();
      this.ctx.fillStyle = 'black';
      this.ctx.fillRect(0, 0, this.cnv.width, this.cnv.height);
      this.renderGrid();
      this.renderLabels();
      return this.ctx.restore();
    };

    DwimGraphics.prototype.animateSprites = function(absolute_t) {
      var anim, do_next, property, remove, sprite, t, to_keep, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2, _ref3;
      to_keep = [];
      _ref = this.sprites;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sprite = _ref[_i];
        do_next = true;
        remove = false;
        while (do_next && sprite.animations.length > 0) {
          do_next = false;
          anim = sprite.animations[0];
          if (anim.set != null) {
            _ref1 = anim.set;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              property = _ref1[_j];
              sprite[property.name] = property.v;
            }
          }
          if (anim.start_t == null) {
            anim.start_t = absolute_t;
            if (sprite.leftover_t != null) {
              anim.start_t -= sprite.leftover_t;
            }
            sprite.leftover_t = 0;
          }
          t = (absolute_t - anim.start_t) / anim.duration;
          if (t >= 1) {
            sprite.leftover_t = absolute_t - (anim.start_t + anim.duration);
            sprite.animations.shift();
            if (anim.remove_on_finish) {
              remove = true;
            } else {
              do_next = true;
            }
            if (anim.lerp != null) {
              _ref2 = anim.lerp;
              for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                property = _ref2[_k];
                sprite[property.name] = property.v1;
              }
            }
          } else {
            if (anim.lerp != null) {
              _ref3 = anim.lerp;
              for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
                property = _ref3[_l];
                if (property.v0 == null) {
                  property.v0 = sprite[property.name];
                }
                sprite[property.name] = (property.v1 - property.v0) * t + property.v0;
              }
            }
          }
        }
        sprite.leftover_t = 0;
        if (!remove) {
          to_keep.push(sprite);
        }
      }
      return this.sprites = to_keep;
    };

    DwimGraphics.prototype.isAnimating = function() {
      var sprite, _i, _len, _ref;
      _ref = this.sprites;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sprite = _ref[_i];
        if ((sprite.animations != null) && sprite.animations.length > 0) {
          return true;
        }
      }
      return false;
    };

    DwimGraphics.prototype.renderSprites = function() {
      var idx, sprite, _i, _ref;
      for (idx = _i = _ref = this.sprites.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; idx = _ref <= 0 ? ++_i : --_i) {
        sprite = this.sprites[idx];
        this.ctx.save();
        this.ctx.translate(sprite.x, sprite.y);
        sprite.render(sprite);
        this.ctx.restore();
      }
    };

    DwimGraphics.prototype.renderFG = function() {
      this.ctx.save();
      this.renderWalls();
      this.renderClues();
      if (this.game_state.halted) {
        if (this.game_state.won) {
          this.renderMessage(this.win_fill_style, 'Click to continue');
        } else {
          this.renderMessage(this.fail_fill_style, 'Click to retry');
        }
      } else {

      }
      return this.ctx.restore();
    };

    DwimGraphics.prototype.renderWalls = function() {
      var x0, x1, y0, y1, _i, _len, _ref, _ref1;
      this.ctx.save();
      this.ctx.translate(this.board_dims.x, this.board_dims.y);
      this.ctx.lineWidth = 2;
      this.ctx.lineCap = 'round';
      this.ctx.strokeStyle = 'white';
      this.ctx.beginPath();
      _ref = this.outline_links;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref1 = _ref[_i], x0 = _ref1.x0, y0 = _ref1.y0, x1 = _ref1.x1, y1 = _ref1.y1;
        this.ctx.moveTo(x0, y0);
        this.ctx.lineTo(x1, y1);
      }
      this.ctx.stroke();
      return this.ctx.restore();
    };

    DwimGraphics.prototype.renderGrid = function() {
      var x, y, _i, _j, _k, _l, _m, _n, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
      this.ctx.save();
      this.ctx.translate(this.board_dims.x, this.board_dims.y);
      this.ctx.strokeStyle = this.grid_stroke_style;
      this.ctx.lineWidth = 1;
      for (x = _i = 0, _ref = this.game_state.Wi; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        for (y = _j = 0, _ref1 = this.game_state.Hi; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
          switch (this.game_state.level[x][y].type) {
            case 'empty':
              this.ctx.strokeRect(x * this.block - .5, y * this.block - .5, this.block, this.block);
          }
        }
      }
      this.ctx.strokeStyle = this.program_stroke_style;
      this.ctx.fillStyle = this.program_fill_style;
      for (x = _k = 0, _ref2 = this.game_state.Wi; 0 <= _ref2 ? _k < _ref2 : _k > _ref2; x = 0 <= _ref2 ? ++_k : --_k) {
        for (y = _l = 0, _ref3 = this.game_state.Hi; 0 <= _ref3 ? _l < _ref3 : _l > _ref3; y = 0 <= _ref3 ? ++_l : --_l) {
          switch (this.game_state.level[x][y].type) {
            case 'program':
              this.ctx.fillRect(x * this.block - .5, y * this.block - .5, this.block, this.block);
              this.ctx.strokeRect(x * this.block - .5, y * this.block - .5, this.block, this.block);
          }
        }
      }
      this.ctx.strokeStyle = 'white';
      this.ctx.lineWidth = 1.5;
      for (x = _m = 0, _ref4 = this.game_state.Wi; 0 <= _ref4 ? _m < _ref4 : _m > _ref4; x = 0 <= _ref4 ? ++_m : --_m) {
        for (y = _n = 0, _ref5 = this.game_state.Hi; 0 <= _ref5 ? _n < _ref5 : _n > _ref5; y = 0 <= _ref5 ? ++_n : --_n) {
          switch (this.game_state.level[x][y].type) {
            case 'exit':
              this.ctx.save();
              this.ctx.translate((x + .5) * this.block - .5, (y + .5) * this.block - .5);
              this.renderShape('star5', this.block * .375);
              this.ctx.restore();
          }
        }
      }
      return this.ctx.restore();
    };

    DwimGraphics.prototype.renderBot = function(sprite) {
      var stretch;
      stretch = 2 * (1 - Math.abs(sprite.t - .5));
      switch (sprite.dir.name) {
        case 'up':
        case 'down':
          this.ctx.scale(1 / stretch, stretch);
          break;
        default:
          this.ctx.scale(stretch, 1 / stretch);
      }
      return this.renderBotMode(this.game_state.current_mode.idx, sprite.scale * this.block);
    };

    DwimGraphics.prototype.makeBotSprite = function() {
      var bot, gfx, _ref;
      gfx = this;
      bot = {
        computePos: (function(_this) {
          return function() {
            return {
              x: (_this.game_state.bot.x + .5) * _this.block + _this.board_dims.x - .5,
              y: (_this.game_state.bot.y + .5) * _this.block + _this.board_dims.y - .5
            };
          };
        })(this),
        render: this.renderBot,
        animations: [],
        t: 0,
        scale: 1,
        leftover_t: 0,
        dir: {
          name: 'down'
        },
        animateMove: function(old_pos, dir) {
          var new_pos;
          new_pos = this.computePos();
          return this.animations.push({
            duration: 150,
            lerp: [
              {
                name: 't',
                v0: 0,
                v1: 1
              }, {
                name: 'x',
                v0: old_pos.x,
                v1: new_pos.x
              }, {
                name: 'y',
                v0: old_pos.y,
                v1: new_pos.y
              }
            ],
            set: [
              {
                name: 'dir',
                v: dir
              }
            ]
          });
        },
        animateBump: function(old_pos, dir) {
          var howfar, new_pos;
          howfar = .15 * gfx.block;
          new_pos = {
            x: old_pos.x + dir.dx * howfar,
            y: old_pos.y + dir.dy * howfar
          };
          this.animations.push({
            duration: 15,
            lerp: [
              {
                name: 't',
                v0: 0,
                v1: .1
              }, {
                name: 'x',
                v0: old_pos.x,
                v1: new_pos.x
              }, {
                name: 'y',
                v0: old_pos.y,
                v1: new_pos.y
              }
            ],
            set: [
              {
                name: 'dir',
                v: dir
              }
            ]
          });
          this.animations.push({
            duration: 50,
            lerp: [
              {
                name: 't',
                v0: .1,
                v1: 0
              }
            ]
          });
          this.animations.push({
            duration: 50,
            lerp: [
              {
                name: 't',
                v0: 0,
                v1: .1
              }, {
                name: 'x',
                v0: new_pos.x,
                v1: (new_pos.x + old_pos.x) / 2
              }, {
                name: 'y',
                v0: new_pos.y,
                v1: (new_pos.y + old_pos.y) / 2
              }
            ]
          });
          return this.animations.push({
            duration: 50,
            lerp: [
              {
                name: 't',
                v0: .1,
                v1: 0
              }, {
                name: 'x',
                v0: (new_pos.x + old_pos.x) / 2,
                v1: old_pos.x
              }, {
                name: 'y',
                v0: (new_pos.y + old_pos.y) / 2,
                v1: old_pos.y
              }
            ]
          });
        }
      };
      _ref = bot.computePos(), bot.x = _ref.x, bot.y = _ref.y;
      return bot;
    };

    DwimGraphics.prototype.makeModeSprites = function() {
      var i, mode, mode_sprites, sprite, _i, _len, _ref;
      mode_sprites = [];
      _ref = this.game_state.modes;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        mode = _ref[i];
        sprite = {
          x: this.mode_dims.x + .5 + this.mode_appearance[i].x,
          y: this.mode_dims.y + .5 + this.mode_appearance[i].y,
          mode: mode,
          render: this.renderModeSprite,
          scale: 1,
          animations: []
        };
        mode_sprites.push(sprite);
      }
      return mode_sprites;
    };

    DwimGraphics.prototype.renderModeSprite = function(sprite) {
      var current_symbol, ics, idx, len, mode, ocs, sym, temp_sym, _i, _len, _ref;
      mode = sprite.mode;
      ocs = this.block;
      ics = this.block * .875;
      temp_sym = mode.symbols;
      current_symbol = null;
      this.ctx.strokeStyle = 'white';
      if (mode === this.game_state.current_mode) {
        this.ctx.save();
        this.ctx.lineWidth = 2.5 * sprite.scale;
        this.ctx.strokeRect(-this.block * .25, -this.block * .25, this.block * 1.75, this.block * 5.5);
        this.ctx.restore();
        if (this.game_state.current_program.length > 0) {
          current_symbol = this.game_state.current_program[0];
          if (!(_ref = this.game_state.current_program[0], __indexOf.call(mode.symbols, _ref) >= 0)) {
            temp_sym = mode.symbols.concat([current_symbol]);
          }
        }
      }
      len = temp_sym.length;
      this.renderNumber(mode.idx + 1);
      this.ctx.save();
      this.ctx.translate(this.block + .5, this.block * .25 + .5);
      this.renderBotMode(mode.idx, this.block * sprite.scale);
      this.ctx.restore();
      this.ctx.translate(this.block * .125, this.block);
      this.ctx.save();
      this.ctx.translate(ocs / 2, ocs / 2);
      for (_i = 0, _len = temp_sym.length; _i < _len; _i++) {
        sym = temp_sym[_i];
        this.ctx.fillStyle = this.instruction_colors[sym];
        this.ctx.fillRect(-ocs / 2 - .5, -ocs / 2 - .5, ocs, ocs);
        this.ctx.strokeRect(-ocs / 2, -ocs / 2, ocs, ocs);
        if (sym in mode.lookup) {
          this.renderCommand(mode.lookup[sym], ocs);
        } else {
          this.renderShape('question', ocs / 2);
        }
        this.ctx.translate(0, ocs);
      }
      this.ctx.restore();
      if (current_symbol != null) {
        idx = temp_sym.indexOf(current_symbol);
        this.ctx.save();
        this.ctx.strokeStyle = 'yellow';
        this.ctx.lineWidth = 4;
        this.ctx.strokeRect(-.5, -.5 + idx * ocs, ocs, ocs);
        return this.ctx.restore();
      }
    };

    DwimGraphics.prototype.animatePopIn = function(anims, low_scale, scale, pos) {
      var pop_0, pop_1;
      pop_0 = {
        duration: 100,
        lerp: [
          {
            name: 'scale',
            v0: low_scale,
            v1: scale * 1.25
          }
        ]
      };
      if (pos != null) {
        pop_0.set = [
          {
            name: 'x',
            v: pos.x
          }, {
            name: 'y',
            v: pos.y
          }
        ];
      }
      pop_1 = {
        duration: 25,
        lerp: [
          {
            name: 'scale',
            v0: scale * 1.25,
            v1: scale
          }
        ]
      };
      anims.push(pop_0);
      return anims.push(pop_1);
    };

    DwimGraphics.prototype.renderBotMode = function(mode, radius) {
      var mode_appearance;
      if (radius === 0) {
        return;
      }
      mode_appearance = this.mode_appearance[mode];
      this.ctx.strokeStyle = 'white';
      this.ctx.fillStyle = 'black';
      this.ctx.lineWidth = 1.5;
      return this.renderShape(mode_appearance.shape, radius * .4, true);
    };

    DwimGraphics.prototype.renderLabels = function() {
      var label, _i, _len, _ref, _results;
      this.ctx.save();
      this.ctx.translate(this.board_dims.x + .5 + this.block / 16, this.board_dims.y + .5 + this.block / 16);
      this.ctx.strokeStyle = 'white';
      this.ctx.lineWidth = 1;
      _ref = this.program_labels;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        label = _ref[_i];
        this.ctx.save();
        this.ctx.translate(label.x, label.y);
        this.renderLetter(label.letter);
        _results.push(this.ctx.restore());
      }
      return _results;
    };

    DwimGraphics.prototype.renderClues = function() {
      var action, bs, command, highlight, idx, label, mode, phl, pid, program, was_unknown, xi, yi, _i, _j, _len, _ref, _ref1;
      this.ctx.save();
      this.ctx.translate(this.clues_dims.x + this.block * .5, this.clues_dims.y + this.block * .5);
      bs = this.block * .875;
      xi = 0;
      yi = 0;
      _ref = this.program_labels;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        label = _ref[_i];
        program = this.game_state.programs[label.id];
        if (xi + program.code.length + 2 >= this.clues_dims.Wi) {
          this.ctx.translate(-xi * this.block, this.block * 1.5);
          xi = 0;
          yi += 1.5;
        }
        this.ctx.strokeStyle = 'white';
        this.ctx.save();
        this.ctx.translate(.5, .5 + this.block * .125);
        this.renderLetter(label.letter, this.block * .75);
        this.ctx.restore();
        this.ctx.translate(this.block, 0);
        xi += 1;
        pid = this.game_state.current_program_id;
        phl = this.game_state.current_program_history.length;
        if (pid !== label.id || phl === 0) {
          mode = this.game_state.current_mode;
        } else {
          mode = this.game_state.current_program_history[phl - 1].mode;
        }
        highlight = -1;
        for (idx = _j = 0, _ref1 = program.code.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; idx = 0 <= _ref1 ? ++_j : --_j) {
          command = program.code.charAt(idx);
          this.ctx.fillStyle = this.instruction_colors[command];
          this.ctx.fillRect(0, 0, bs, bs);
          was_unknown = mode === 'unknown';
          if (!was_unknown) {
            action = mode.lookup[command];
            this.ctx.translate(bs / 2 + .5, bs / 2 + .5);
            if (action != null) {
              if (pid !== label.id) {
                this.renderCommand(mode.lookup[command], this.block);
              }
              if (action.type === 'mode') {
                mode = this.game_state.modes[action.idx];
              }
            } else {
              if (pid !== label.id) {
                this.renderShape('question', this.block / 2);
              }
              mode = 'unknown';
            }
            this.ctx.translate(-bs / 2 - .5, -bs / 2 - .5);
          }
          if (pid === label.id && (idx === phl - 1 || (!was_unknown && mode === 'unknown' && idx === phl))) {
            highlight = xi;
          }
          this.ctx.translate(this.block, 0);
          xi += 1;
        }
        if (highlight !== -1) {
          this.ctx.save();
          this.ctx.translate(-(xi - highlight) * this.block, 0);
          this.ctx.strokeStyle = 'yellow';
          this.ctx.lineWidth = 4;
          this.ctx.strokeRect(0, 0, bs, bs);
          this.ctx.restore();
        }
        this.ctx.translate(this.block, 0);
        xi += 1;
      }
      return this.ctx.restore();
    };

    DwimGraphics.prototype.renderMessage = function(fill_style, message) {
      var width;
      this.ctx.save();
      this.ctx.font = 'bold 16px monospace';
      this.ctx.textAlign = 'center';
      this.ctx.textBaseline = 'middle';
      this.ctx.fillStyle = this.message_bg_fill_style;
      width = this.ctx.measureText(message).width;
      this.ctx.fillRect(this.message_pos.x - width / 2 - 16, this.message_pos.y - 16, width + 32, 32);
      this.ctx.fillStyle = fill_style;
      this.ctx.fillText(message, this.message_pos.x, this.message_pos.y);
      return this.ctx.restore();
    };

    DwimGraphics.prototype.onAnimComplete = function(fcn) {
      return this.anim_complete_callbacks.push(fcn);
    };

    DwimGraphics.prototype.renderArrow = function(dir, size) {
      var ahs, as;
      as = size * .75;
      ahs = size * .2;
      this.ctx.rotate(-dir);
      this.ctx.beginPath();
      this.ctx.moveTo(-as / 2, 0);
      this.ctx.lineTo(as / 2, 0);
      this.ctx.lineTo(as / 2 - ahs, ahs);
      this.ctx.moveTo(as / 2, 0);
      this.ctx.lineTo(as / 2 - ahs, -ahs);
      this.ctx.stroke();
      this.ctx.rotate(dir);
    };

    DwimGraphics.prototype.renderShape = function(shape, radius, fill) {
      var cb, i, ics, inner, ox, oy, r, r2, sides, _i;
      if (fill == null) {
        fill = false;
      }
      this.ctx.beginPath();
      switch (shape) {
        case 'circle':
          this.ctx.arc(0, 0, radius * .8, 0, Math.PI * 2);
          break;
        case 'star8':
        case 'star5':
          sides = shape === 'star8' ? 8 : 5;
          inner = radius * .5;
          this.ctx.moveTo(0, -radius);
          this.ctx.save();
          for (i = _i = 0; 0 <= sides ? _i < sides : _i > sides; i = 0 <= sides ? ++_i : --_i) {
            this.ctx.rotate(Math.PI / sides);
            this.ctx.lineTo(0, -inner);
            this.ctx.rotate(Math.PI / sides);
            this.ctx.lineTo(0, -radius);
          }
          this.ctx.restore();
          break;
        case 'square':
          r = radius * .75;
          this.ctx.moveTo(-r, -r);
          this.ctx.lineTo(-r, +r);
          this.ctx.lineTo(+r, +r);
          this.ctx.lineTo(+r, -r);
          this.ctx.closePath();
          break;
        case 'diamond':
          r = radius * Math.SQRT1_2 * 1.125;
          this.ctx.moveTo(-r, 0);
          this.ctx.lineTo(0, +r);
          this.ctx.lineTo(+r, 0);
          this.ctx.lineTo(0, -r);
          this.ctx.closePath();
          break;
        case 'hex':
          r = radius * .8;
          r2 = r / 2;
          this.ctx.moveTo(-r, 0);
          this.ctx.lineTo(-r2, -r);
          this.ctx.lineTo(+r2, -r);
          this.ctx.lineTo(+r, 0);
          this.ctx.lineTo(+r2, +r);
          this.ctx.lineTo(-r2, +r);
          this.ctx.closePath();
          break;
        case 'question':
          r = radius * .75;
          this.ctx.moveTo(-r * .75, -.5 * r);
          this.ctx.lineTo(-r * .75, -r);
          this.ctx.lineTo(+r * .75, -r);
          this.ctx.lineTo(+r * .75, 0);
          this.ctx.lineTo(0, 0);
          this.ctx.lineTo(0, .625 * r);
          this.ctx.moveTo(0, .75 * r);
          this.ctx.lineTo(0, r);
          break;
        case 'octagon':
          ics = radius * 1.75;
          cb = radius * .5;
          ox = -ics / 2;
          oy = -ics / 2;
          this.ctx.translate(ox, oy);
          this.ctx.beginPath();
          this.ctx.moveTo(0, cb);
          this.ctx.lineTo(cb, 0);
          this.ctx.lineTo(ics - cb, 0);
          this.ctx.lineTo(ics, cb);
          this.ctx.lineTo(ics, ics - cb);
          this.ctx.lineTo(ics - cb, ics);
          this.ctx.lineTo(cb, ics);
          this.ctx.lineTo(0, ics - cb);
          this.ctx.closePath();
          break;
        case 'clover':
          r = radius * .75;
          r2 = r / 2;
          this.ctx.moveTo(0, -r2);
          this.ctx.arc(r2, -r2, r2, Math.PI, -1.5 * Math.PI);
          this.ctx.arc(r2, r2, r2, -.5 * Math.PI, Math.PI);
          this.ctx.arc(-r2, r2, r2, 0, -.5 * Math.PI);
          this.ctx.arc(-r2, -r2, r2, -1.5 * Math.PI, 0);
          break;
        case 'pinch':
          r = radius * .75;
          this.ctx.moveTo(-r, -r);
          this.ctx.quadraticCurveTo(0, 0, r, -r);
          this.ctx.quadraticCurveTo(0, 0, r, r);
          this.ctx.quadraticCurveTo(0, 0, -r, r);
          this.ctx.quadraticCurveTo(0, 0, -r, -r);
      }
      if (fill) {
        this.ctx.fill();
      }
      this.ctx.stroke();
    };

    DwimGraphics.prototype.renderCommand = function(command, size) {
      this.ctx.save();
      switch (command.type) {
        case 'move':
          this.renderArrow(command.dir.theta, size);
          break;
        case 'mode':
          this.renderBotMode(command.idx, size);
      }
      return this.ctx.restore();
    };

    DwimGraphics.prototype.digit_graphics = [[[[0, 0], [4, 0], [4, 4], [0, 4], [0, 0]]], [[[2, 0], [2, 4]]], [[[0, 0], [4, 0], [4, 2], [0, 2], [0, 4], [4, 4]]], [[[0, 0], [4, 0], [4, 4], [0, 4]], [[0, 2], [4, 2]]], [[[0, 0], [0, 2], [4, 2]], [[4, 0], [4, 4]]], [[[4, 0], [0, 0], [0, 2], [4, 2], [4, 4], [0, 4]]], [[[4, 0], [0, 0], [0, 4], [4, 4], [4, 2], [0, 2]]], [[[0, 0], [4, 0], [4, 4]]], [[[0, 0], [0, 4], [4, 4], [4, 0], [0, 0]], [[0, 2], [4, 2]]], [[[0, 4], [4, 4], [4, 0], [0, 0], [0, 2], [4, 2]]]];

    DwimGraphics.prototype.renderNumber = function(n, scale) {
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
      this.ctx.save();
      for (i = _i = _ref = s.length - 1; _i >= 0; i = _i += -1) {
        this.ctx.beginPath();
        _ref1 = this.digit_graphics[s[i]];
        for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
          line = _ref1[_j];
          this.ctx.moveTo(line[0][0] * scale, line[0][1] * scale);
          _ref2 = line.slice(1);
          for (_k = 0, _len1 = _ref2.length; _k < _len1; _k++) {
            point = _ref2[_k];
            this.ctx.lineTo(point[0] * scale, point[1] * scale);
          }
        }
        this.ctx.stroke();
        this.ctx.translate(5 * scale, 0);
      }
      return this.ctx.restore();
    };

    DwimGraphics.prototype.letterGraphics = {
      a: [[[0, 1], [1.5, 1], [1.5, 3], [0, 3], [0, 2], [1.5, 2]]],
      b: [[[0, 0], [0, 3], [1.5, 3], [1.5, 1.5], [0, 1.5]]],
      c: [[[1.5, 1], [0, 1], [0, 3], [1.5, 3]]],
      d: [[[2, 0], [2, 3], [.5, 3], [.5, 1.5], [2, 1.5]]],
      e: [[[0, 2], [1.5, 2], [1.5, 1], [0, 1], [0, 3], [1.5, 3]]],
      f: [[[.5, 1.5], [1.5, 1.5]], [[2, 0], [1, 0], [1, 3]]]
    };

    DwimGraphics.prototype.renderLetter = function(l, scale) {
      var g, line, point, _i, _j, _len, _len1, _ref;
      if (scale == null) {
        scale = this.block / 2;
      }
      g = this.letterGraphics[l];
      if (g == null) {
        return;
      }
      this.ctx.beginPath();
      for (_i = 0, _len = g.length; _i < _len; _i++) {
        line = g[_i];
        this.ctx.moveTo(line[0][0] / 4 * scale, line[0][1] / 4 * scale);
        _ref = line.slice(1);
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          point = _ref[_j];
          this.ctx.lineTo(point[0] / 4 * scale, point[1] / 4 * scale);
        }
      }
      return this.ctx.stroke();
    };

    return DwimGraphics;

  })();

  window.DwimGraphics = DwimGraphics;

}).call(this);

//# sourceMappingURL=graphics.map
