// requestAnimationFrame polyfill by Erik Möller. fixes from Paul Irish and Tino Zijdel
 
// http://paulirish.com/2011/requestanimationframe-for-smart-animating/
// http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
 
// MIT license
 
(function() {
    var lastTime = 0;
    var vendors = ['ms', 'moz', 'webkit', 'o'];
    for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
        window.requestAnimationFrame = window[vendors[x]+'RequestAnimationFrame'];
        window.cancelAnimationFrame = window[vendors[x]+'CancelAnimationFrame']
                                   || window[vendors[x]+'CancelRequestAnimationFrame'];
    }
    if (!window.requestAnimationFrame)
        window.requestAnimationFrame = function(callback, element) {
            var currTime = new Date().getTime();
            var timeToCall = Math.max(0, 16 - (currTime - lastTime));
            var id = window.setTimeout(function() { callback(currTime + timeToCall); },
                timeToCall);
            lastTime = currTime + timeToCall;
            return id;
        };
     if (!window.cancelAnimationFrame)
         window.cancelAnimationFrame = function(id) {
             clearTimeout(id);
         };
}());

// on the recommendation of HTML5: Up and Running

function getCursorPosition(el, ev) {
    var x, y;
    if (ev.pageX != undefined && ev.pageY != undefined) {
        x = ev.pageX;
        y = ev.pageY;
    } else {
        x = ev.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        y = ev.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }

    x -= el.offsetLeft;
    y -= el.offsetTop;

    return {x: x, y: y};
}

//

var registerKeyFunction;
var translateCharCode;

registerKeyFunction = function (fn) {
  document.addEventListener('keypress', function (e) {
    var cc;

    if (e.ctrlKey || e.altKey || e.metaKey) {
      // keyboard shortcut of some kind
      return true
    } else {
      cc = translateCharCode(e);
      if (cc.length > 0) {
        fn(cc)
      }
      e.preventDefault()
    }
  });

  //if (backspace_ret) {
  {
    document.addEventListener('keydown', function (e) {
      if (e.keyCode === 13) {
        fn("<return>");
      } else if (e.keyCode === 8) {
        fn("<backspace>");
      } else if (e.keyCode === 38) {
        fn("<up>");
      } else if (e.keyCode === 40) {
        fn("<down>");
      } else if (e.keyCode === 37) {
        fn("<left>");
      } else if (e.keyCode === 39) {
        fn("<right>");
      } else {
        return
      }
      e.preventDefault();
    });
  }
};


(function(){
    var t = function (e) {
        var k = e.charCode;
        var ks = String.fromCharCode(k);
        
        if ((k >= t.aCode && k <= t.zCode) ||
            (k >= t.ACode && k <= t.ZCode) ||
            (k >= t._0Code && k <= t._9Code)) {
            
            return ks;
        }
        
        if (t.etcCodes.indexOf(ks) !== -1) {
            return ks;
        }
        
        return '';
    };

    t.aCode = 'a'.charCodeAt(0);
    t.zCode = 'z'.charCodeAt(0);
    t.ACode = 'A'.charCodeAt(0);
    t.ZCode = 'Z'.charCodeAt(0);
    t._0Code = '0'.charCodeAt(0);
    t._9Code = '9'.charCodeAt(0);
    t.etcCodes = ',:=';

    translateCharCode = t;

})();

