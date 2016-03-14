// Generated by CoffeeScript 1.8.0
(function() {
  var nextUnusedLetter,
    __hasProp = {}.hasOwnProperty;

  nextUnusedLetter = function(object) {
    var candidate, index, letters, suffix;
    letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    index = 0;
    suffix = 0;
    candidate = function() {
      return "" + letters[index] + (suffix > 0 ? suffix : '');
    };
    while (candidate() in object) {
      index++;
      if (index === letters.length) {
        index = 0;
        suffix++;
      }
    }
    return candidate();
  };

  APISandbox.addClass('handful', 'A handful of dice', function(x) {
    return true;
  });

  APISandbox.addConstructor('Take a new handful of dice', function(count, environment) {
    var key;
    key = nextUnusedLetter(environment);
    environment[key] = count;
    return "Let " + key + " represent a handful of " + count + " six-sided dice.";
  }, {
    name: 'how many dice in the handful',
    description: 'an integer number of dice, from 1 to 20',
    type: 'integer',
    min: 1,
    max: 20,
    defaultValue: '3'
  });

  APISandbox.addMethod('handful', 'show a picture of it', function(name, environment) {
    var c, count, die, dots, i, interp, r, result, s, size, svg, x, y, _i, _ref, _ref1;
    result = document.createElement('div');
    result.innerHTML = "<p>Your " + environment[name] + " dice might look like this, if you arranged them neatly.</p>";
    count = environment[name];
    size = 70;
    svg = new Snap(size * count, size);
    r = 0.5 * size;
    _ref = [0.7071 * r, 0.5 * r], c = _ref[0], s = _ref[1];
    interp = function(a, b, t) {
      return (1 - t) * a + t * b;
    };
    dots = function(x1, y1, x2, y2, n) {
      var j, t, _i, _results;
      _results = [];
      for (j = _i = 1; 1 <= n ? _i <= n : _i >= n; j = 1 <= n ? ++_i : --_i) {
        t = j / (n + 1);
        _results.push(svg.circle(interp(x1, x2, t), interp(y1, y2, t), 2).attr({
          stroke: 'none',
          fill: 'black'
        }));
      }
      return _results;
    };
    for (i = _i = 0; 0 <= count ? _i < count : _i > count; i = 0 <= count ? ++_i : --_i) {
      _ref1 = [size * i + size / 2, size / 2], x = _ref1[0], y = _ref1[1];
      die = svg.polyline(x, y, x - c, y - s, x, y - r, x + c, y - s, x + c, y + s, x, y + r, x - c, y + s, x - c, y - s, x, y, x + c, y - s, x, y, x, y + r);
      die.attr({
        stroke: 'black',
        fill: 'none'
      });
      dots(x, y, x + c, y + s, 1);
      dots(x - c, y - s, x, y + r, 2);
      dots(x - c, y - s, x + c, y - s, 3);
    }
    svg.insertAfter(result.childNodes[0]);
    return result;
  });

  APISandbox.addMethod('handful', 'roll the dice', function(name, numRolls, environment) {
    var barHeight, barWidth, count, div, height, i, mar, max, maxCount, min, numDice, r, result, roll, rollOne, svg, textHeight, x, _i, _j, _len, _ref, _ref1, _ref2, _ref3;
    rollOne = function() {
      return 1 + Math.floor(Math.random() * 6);
    };
    numDice = environment[name];
    roll = function() {
      var i, result, _i;
      result = 0;
      for (i = _i = 1; 1 <= numDice ? _i <= numDice : _i >= numDice; i = 1 <= numDice ? ++_i : --_i) {
        result += rollOne();
      }
      return result;
    };
    result = {};
    _ref = (function() {
      var _j, _results;
      _results = [];
      for (i = _j = 1; 1 <= numRolls ? _j <= numRolls : _j >= numRolls; i = 1 <= numRolls ? ++_j : --_j) {
        _results.push(roll());
      }
      return _results;
    })();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      r = _ref[_i];
      result[r] = ((_ref1 = result[r]) != null ? _ref1 : 0) + 1;
    }
    min = numDice;
    max = numDice * 6;
    maxCount = 0;
    for (r in result) {
      if (!__hasProp.call(result, r)) continue;
      count = result[r];
      maxCount = Math.max(maxCount, count);
    }
    barWidth = 30;
    height = 100;
    textHeight = 30;
    mar = 2;
    svg = new Snap(barWidth * (max - min + 1), height + textHeight * 2);
    for (i = _j = min; min <= max ? _j <= max : _j >= max; i = min <= max ? ++_j : --_j) {
      barHeight = height * ((_ref2 = result[i]) != null ? _ref2 : 0) / maxCount + 1;
      x = barWidth * (i - min);
      svg.rect(x + mar, textHeight + height - barHeight, barWidth - 2 * mar, barHeight).attr({
        fill: '#aaf',
        stroke: '#00a'
      });
      svg.text(x + 3 * mar, textHeight + height - barHeight - 3, (_ref3 = result[i]) != null ? _ref3 : '0');
      svg.text(x + 3 * mar, height + textHeight * 2, i);
    }
    div = document.createElement('div');
    div.innerHTML = "<p>Here is a histogram showing the results of all " + numRolls + " rolls of the " + numDice + " dice in handful " + name + ".  Each roll was treated as the sum of the " + numDice + " numbers rolled.</p>";
    svg.insertAfter(div.childNodes[0]);
    return div;
  }, {
    name: 'how many times to roll the dice',
    description: 'an integer number of rolls, from 1 to 1000',
    type: 'integer',
    min: 1,
    max: 1000,
    defaultValue: 100
  });

  APISandbox.setup(document.getElementById('main-div'));

  ($('#title-div')).append(APISandbox.permalinkElement());

  ($('#title-div')).append(' &mdash; ');

  ($('#title-div')).append(APISandbox.clearElement());

}).call(this);

//# sourceMappingURL=demo2-solo.js.map
