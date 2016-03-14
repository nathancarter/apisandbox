// Generated by CoffeeScript 1.8.0
(function() {
  var Command, History, State,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty;

  window.APISandbox = {};

  APISandbox.Command = Command = Command = (function() {
    function Command() {
      var method, objectName, parameters;
      objectName = arguments[0], method = arguments[1], parameters = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      this.objectName = objectName;
      this.method = method;
      this.parameters = parameters;
      this.methodName = __bind(this.methodName, this);
      this.constructorName = __bind(this.constructorName, this);
      this.apply = __bind(this.apply, this);
    }

    Command.prototype.apply = function(state) {
      var div, element, parameter, parameters, result;
      result = state.copy();
      result.command = this;
      if (result.environment === null) {
        result.environment = state.environment;
        state.environment = null;
      }
      parameters = (function() {
        var _i, _len, _ref, _results;
        _ref = this.parameters;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          parameter = _ref[_i];
          if ('name' in parameter) {
            _results.push(state.environment[parameter.name]);
          } else {
            _results.push(parameter.value);
          }
        }
        return _results;
      }).call(this);
      parameters.push(result.environment);
      if (this.objectName != null) {
        parameters.unshift(this.objectName);
      }
      element = this.objectName && !(this.objectName in state.environment) ? "This command was formerly run on " + this.objectName + ", which no longer exists due to changes made up above." : this.method.apply(null, parameters);
      if (!(element instanceof window.Node)) {
        div = APISandbox.div.ownerDocument.createElement('div');
        div.innerHTML = "" + element;
        element = div;
      }
      div = APISandbox.div.ownerDocument.createElement('div');
      div.setAttribute('class', 'command-result');
      div.appendChild(element);
      result.element = div;
      return result;
    };

    Command.prototype.constructorName = function() {
      var data, phrase, _ref, _ref1;
      _ref1 = (_ref = APISandbox.data.constructors) != null ? _ref : {};
      for (phrase in _ref1) {
        if (!__hasProp.call(_ref1, phrase)) continue;
        data = _ref1[phrase];
        if (data.call === this.method) {
          return phrase;
        }
      }
      return null;
    };

    Command.prototype.methodName = function() {
      var bigdata, className, data, phrase, _ref, _ref1;
      _ref1 = (_ref = APISandbox.data.members) != null ? _ref : {};
      for (className in _ref1) {
        if (!__hasProp.call(_ref1, className)) continue;
        bigdata = _ref1[className];
        for (phrase in bigdata) {
          if (!__hasProp.call(bigdata, phrase)) continue;
          data = bigdata[phrase];
          if (data.call === this.method) {
            return {
              className: className,
              phrase: phrase
            };
          }
        }
      }
      return null;
    };

    return Command;

  })();

  APISandbox.State = State = State = (function() {
    function State(command) {
      this.command = command != null ? command : null;
      this.copy = __bind(this.copy, this);
      this.computeObjectsInClass = __bind(this.computeObjectsInClass, this);
      this.environment = {};
      this.element = null;
      this.objectsInClass = null;
    }

    State.prototype.computeObjectsInClass = function() {
      var cname, info, object, oname, _ref, _results;
      if (this.environment === null) {
        return this.objectsInClass = null;
      }
      if (this.objectsInClass !== null) {
        return;
      }
      this.objectsInClass = {};
      _ref = this.environment;
      _results = [];
      for (oname in _ref) {
        if (!__hasProp.call(_ref, oname)) continue;
        object = _ref[oname];
        _results.push((function() {
          var _base, _ref1, _ref2, _ref3, _results1;
          _ref3 = (_ref1 = (_ref2 = APISandbox.data) != null ? _ref2.classes : void 0) != null ? _ref1 : {};
          _results1 = [];
          for (cname in _ref3) {
            if (!__hasProp.call(_ref3, cname)) continue;
            info = _ref3[cname];
            if (info.isAnInstance(object)) {
              ((_base = this.objectsInClass)[cname] != null ? _base[cname] : _base[cname] = []).push(oname);
              break;
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    State.prototype.copy = function() {
      var e, key, result, value, _ref, _ref1;
      result = new State();
      _ref = this.environment;
      for (key in _ref) {
        if (!__hasProp.call(_ref, key)) continue;
        value = _ref[key];
        try {
          result.environment[key] = (_ref1 = value != null ? typeof value.copy === "function" ? value.copy() : void 0 : void 0) != null ? _ref1 : JSON.parse(JSON.stringify(value));
        } catch (_error) {
          e = _error;
          result.environment = null;
          break;
        }
      }
      return result;
    };

    return State;

  })();

  APISandbox.History = History = History = (function() {
    function History() {
      this.deserialize = __bind(this.deserialize, this);
      this.serialize = __bind(this.serialize, this);
      this.duplicateAction = __bind(this.duplicateAction, this);
      this.deleteAction = __bind(this.deleteAction, this);
      this.changeAction = __bind(this.changeAction, this);
      this.rewriteHistory = __bind(this.rewriteHistory, this);
      this.appendAction = __bind(this.appendAction, this);
      this.states = [APISandbox.initialState()];
    }

    History.prototype.appendAction = function(action) {
      return this.states.push(action.apply(this.states[this.states.length - 1]));
    };

    History.prototype.rewriteHistory = function(i, f) {
      var action, j, last, state, toRewrite, _i, _j, _len, _ref, _results;
      if (i <= 0) {
        return;
      }
      toRewrite = (function() {
        var _i, _len, _ref, _results;
        _ref = this.states.splice(i);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          state = _ref[_i];
          _results.push(state.command);
        }
        return _results;
      }).call(this);
      if (this.states[i - 1].environment === null) {
        this.states[0] = APISandbox.initialState();
        for (j = _i = 1; 1 <= i ? _i < i : _i > i; j = 1 <= i ? ++_i : --_i) {
          this.states[j] = this.states[j].command.apply(this.states[j - 1]);
        }
      }
      last = this.states[i - 1];
      _ref = f(toRewrite);
      _results = [];
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        action = _ref[_j];
        _results.push(this.states.push(last = action.apply(last)));
      }
      return _results;
    };

    History.prototype.changeAction = function(i, action) {
      return this.rewriteHistory(i, function(olds) {
        return [action].concat(__slice.call(olds.slice(1)));
      });
    };

    History.prototype.deleteAction = function(i) {
      return this.rewriteHistory(i, function(olds) {
        return olds.slice(1);
      });
    };

    History.prototype.duplicateAction = function(i) {
      return this.rewriteHistory(i, function(olds) {
        return [olds[0]].concat(__slice.call(olds));
      });
    };

    History.prototype.serialize = function() {
      var array, mn, state;
      array = (function() {
        var _i, _len, _ref, _results;
        _ref = this.states.slice(1);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          state = _ref[_i];
          if (state.command.objectName != null) {
            mn = state.command.methodName();
            _results.push(["m " + state.command.objectName, mn.className, mn.phrase].concat(__slice.call(state.command.parameters)));
          } else {
            _results.push(["c " + (state.command.constructorName())].concat(__slice.call(state.command.parameters)));
          }
        }
        return _results;
      }).call(this);
      return JSON.stringify(array);
    };

    History.prototype.deserialize = function(encoded) {
      var className, command, constructorName, encodedState, methodPhrase, objectName, parameters, _i, _len, _ref, _results;
      this.states = [APISandbox.initialState()];
      _ref = JSON.parse(encoded);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        encodedState = _ref[_i];
        command = encodedState[0].slice(0, 2) === 'm ' ? (objectName = encodedState[0].slice(2), className = encodedState[1], methodPhrase = encodedState[2], parameters = encodedState.slice(3), (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(Command, [objectName, APISandbox.data.members[className][methodPhrase].call].concat(__slice.call(parameters)), function(){})) : (constructorName = encodedState[0].slice(2), parameters = encodedState.slice(1), (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(Command, [null, APISandbox.data.constructors[constructorName].call].concat(__slice.call(parameters)), function(){}));
        _results.push(this.appendAction(command));
      }
      return _results;
    };

    return History;

  })();

  APISandbox.setup = function(div, initialHTML) {
    var init;
    this.div = div;
    if (initialHTML == null) {
      initialHTML = '';
    }
    if (this.data == null) {
      this.data = {};
    }
    init = (this.history = new History()).states[0];
    init.DOM = this.div.ownerDocument.createElement('div');
    init.DOM.innerHTML = initialHTML;
    while (this.div.hasChildNodes()) {
      this.div.removeChild(this.div.lastChild);
    }
    this.div.appendChild(init.DOM);
    this.div.appendChild(this.createCommandUI(1));
    return this.handlePermalink();
  };

  APISandbox.addClass = function(name, desc, chi) {
    var _base;
    return ((_base = (this.data != null ? this.data : this.data = {})).classes != null ? _base.classes : _base.classes = {})[name] = {
      description: desc,
      isAnInstance: chi
    };
  };

  APISandbox.addConstructor = function() {
    var func, parameters, phrase, _base;
    phrase = arguments[0], func = arguments[1], parameters = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
    return ((_base = (this.data != null ? this.data : this.data = {})).constructors != null ? _base.constructors : _base.constructors = {})[phrase] = {
      call: func,
      parameters: parameters
    };
  };

  APISandbox.addMethod = function() {
    var className, func, parameters, phrase, _base, _base1;
    className = arguments[0], phrase = arguments[1], func = arguments[2], parameters = 4 <= arguments.length ? __slice.call(arguments, 3) : [];
    if ((_base = (this.data != null ? this.data : this.data = {})).members == null) {
      _base.members = {};
    }
    return ((_base1 = this.data.members)[className] != null ? _base1[className] : _base1[className] = {})[phrase] = {
      call: func,
      parameters: parameters
    };
  };

  APISandbox.addGlobal = function(name, description, object) {
    var _base;
    return ((_base = (this.data != null ? this.data : this.data = {})).globals != null ? _base.globals : _base.globals = {})[name] = {
      description: description,
      value: object
    };
  };

  APISandbox.initialState = function() {
    var key, result, value, _ref, _ref1, _ref2;
    result = new State();
    _ref2 = (_ref = (_ref1 = this.data) != null ? _ref1.globals : void 0) != null ? _ref : {};
    for (key in _ref2) {
      if (!__hasProp.call(_ref2, key)) continue;
      value = _ref2[key];
      result.environment[key] = value.value;
    }
    return result;
  };

  APISandbox.permalink = function() {
    var currentURL;
    currentURL = window.location.href.split('?')[0];
    return "" + currentURL + "?" + (encodeURIComponent(this.history.serialize()));
  };

  APISandbox.inputWidget = function(index, paramIndex, type) {
    var c, choices, className, cname, func, id, idexpr, input, notify, oldValidator, onames, onoff, phrase, re, result, right, state, typeName, validate, validator;
    typeName = type.type;
    id = "input-" + index + "-" + paramIndex;
    idexpr = "id='" + id + "'";
    if (typeName.slice(0, 7) === 'object:') {
      className = typeName.slice(7);
      typeName = 'object';
    } else {
      className = null;
    }
    right = (function() {
      var _ref, _ref1, _ref2;
      switch (typeName) {
        case 'integer':
        case 'float':
        case 'string':
        case 'short string':
          return "<input type='text' " + idexpr + " width=40 class='form-control' value='" + ((_ref = type.defaultValue) != null ? _ref : '') + "'/>";
        case 'boolean':
          onoff = type.defaultValue ? 'selected' : '';
          return "<input type='checkbox' " + idexpr + " " + onoff + " class='form-control'/>";
        case 'choice':
        case 'object':
          if (typeName === 'choice') {
            choices = type.values;
          } else {
            state = (_ref1 = this.history.states[index - 1]) != null ? _ref1.objectsInClass : void 0;
            choices = [];
            _ref2 = state != null ? state : {};
            for (cname in _ref2) {
              if (!__hasProp.call(_ref2, cname)) continue;
              onames = _ref2[cname];
              if ((className == null) || className === cname) {
                choices = choices.concat(onames);
              }
            }
          }
          choices = (function() {
            var _i, _len, _results;
            _results = [];
            for (_i = 0, _len = choices.length; _i < _len; _i++) {
              c = choices[_i];
              _results.push("<option value='" + c + "'>" + c + "</option>");
            }
            return _results;
          })();
          return ("<select " + idexpr + " class='form-control'>" + (choices.join('')) + " </select>").replace("value='" + type.defaultValue + "'", "value='" + type.defaultValue + "' selected");
        case 'JSON':
        case 'long string':
          return "<textarea rows=6 cols=40 class='form-control' " + idexpr + ">" + type.defaultValue + "</textarea>";
      }
    }).call(this);
    result = this.div.ownerDocument.createElement('tr');
    result.innerHTML = "<td align='right' width='35%'><label >" + type.name + "</label></td><td width='65%'>" + right + " &nbsp; <span id='" + id + "-notifications'></span></td>";
    validator = type.validator;
    if (typeName === 'integer' || typeName === 'float') {
      oldValidator = validator;
      if (typeName === 'integer') {
        re = /^[+-]?[0-9]+$/;
        func = parseInt;
        phrase = 'an integer';
      } else {
        re = /^[+-]?[0-9]*\.?[0-9]+|[+-]?[0-9]+\.[0-9]*$/;
        func = parseFloat;
        phrase = 'a float';
      }
      validator = function(input) {
        var value;
        if (!re.test(input)) {
          return {
            valid: false,
            message: "This is not " + phrase + "."
          };
        } else {
          value = func(input);
          if ((type.min != null) && type.min > value) {
            return {
              valid: false,
              message: "The minimum is " + type.min + "."
            };
          } else if ((type.max != null) && type.max < value) {
            return {
              valid: false,
              message: "The maximum is " + type.max + "."
            };
          } else {
            return typeof oldValidator === "function" ? oldValidator(value) : void 0;
          }
        }
      };
    }
    input = $("#" + id, result);
    notify = $("#" + id + "-notifications", result);
    validate = (function(_this) {
      return function() {
        var validation, _ref, _ref1, _ref2;
        validation = typeof validator === "function" ? validator(($(input)).val()) : void 0;
        if ((validation != null ? validation.valid : void 0) === false) {
          notify.get(0).innerHTML = "<font color=red>" + ((_ref = validation != null ? validation.message : void 0) != null ? _ref : '') + "</font>";
          return input.get(0).setAttribute('data-invalid', (_ref1 = validation != null ? validation.message : void 0) != null ? _ref1 : '--');
        } else {
          notify.get(0).innerHTML = (_ref2 = validation != null ? validation.message : void 0) != null ? _ref2 : '';
          return input.get(0).removeAttribute('data-invalid');
        }
      };
    })(this);
    input.change(validate);
    input.keyup(validate);
    setTimeout(validate, 0);
    input.addClass('command-ui-input');
    if (type.defaultValue != null) {
      input.val(type.defaultValue);
    }
    return result;
  };

  APISandbox.readDataFrom = function(widget) {
    return ($(widget)).val();
  };

  APISandbox.writeDataTo = function(widget, value) {
    return ($(widget)).val(value);
  };

  APISandbox.readAll = function(index) {
    var i, message, next, result;
    result = [];
    i = 0;
    while ((next = $("#input-" + index + "-" + i)).length > 0) {
      if (message = next.get(0).getAttribute('data-invalid')) {
        throw message;
      }
      result.push(next.val());
      i++;
    }
    return result;
  };

  APISandbox.writeAll = function(index) {
    var i, value, widget, _i, _len, _ref, _ref1, _ref2, _results;
    _ref = this.history.states[index].command.parameters;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      value = _ref[i];
      widget = $("#input-" + index + "-" + i);
      widget.val((_ref1 = (_ref2 = value.name) != null ? _ref2 : value.value) != null ? _ref1 : value);
      _results.push(widget.change());
    }
    return _results;
  };

  APISandbox.restoreSelects = function(index) {
    var choices, command, methName, methods, option, _i, _len, _ref;
    command = this.history.states[index].command;
    if (index < this.history.states.length) {
      ($("#delete-command-" + index)).show();
      ($("#duplicate-command-" + index)).show();
    } else {
      ($("#delete-command-" + index)).hide();
      ($("#duplicate-command-" + index)).hide();
    }
    choices = $("#ctor-select-" + index);
    methods = $("#method-select-" + index);
    if (command.objectName != null) {
      _ref = choices.get(0).childNodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        option = _ref[_i];
        if (option.getAttribute('data-object-name') === command.objectName) {
          choices.val(option.getAttribute('value'));
          choices.change();
          break;
        }
      }
      methods.show();
      if ((methName = command.methodName()) != null) {
        methods.val(methName.phrase);
        methods.change();
        return;
      }
    }
    choices.val(command.constructorName());
    choices.change();
    return methods.hide();
  };

  APISandbox.tableForFunction = function(index, className, funcName) {
    var data, i, parameter, result, table, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4;
    data = className ? (_ref = this.data.members) != null ? (_ref1 = _ref[className]) != null ? _ref1[funcName] : void 0 : void 0 : (_ref2 = this.data.constructors) != null ? _ref2[funcName] : void 0;
    result = this.div.ownerDocument.createElement('div');
    table = this.div.ownerDocument.createElement('table');
    table.style.borderSpacing = '10px';
    table.style.borderCollapse = 'separate';
    table.setAttribute('width', '100%');
    result.appendChild(table);
    _ref4 = (_ref3 = data != null ? data.parameters : void 0) != null ? _ref3 : {};
    for (i = _i = 0, _len = _ref4.length; _i < _len; i = ++_i) {
      parameter = _ref4[i];
      table.appendChild(this.inputWidget(index, i, parameter));
    }
    return result;
  };

  APISandbox.createCommandUI = function(index) {
    var cname, data, deleteX, duplicate, fillMethods, float, hideApply, hideCancel, hideMethods, methods, object, objects, option, phrase, result, row, select, showApply, showCancel, showMethods, table, updateParameterTable, updateViewAfter, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4;
    if ((_ref = this.history.states[index - 1]) != null) {
      if (typeof _ref.computeObjectsInClass === "function") {
        _ref.computeObjectsInClass();
      }
    }
    result = this.div.ownerDocument.createElement('div');
    result.setAttribute('class', 'command-ui');
    result.setAttribute('id', "command-ui-" + index);
    result.innerHTML = "<select id='ctor-select-" + index + "' class='form-control' style='width: 80%;'></select>";
    select = $("#ctor-select-" + index, result);
    _ref3 = (_ref1 = (_ref2 = this.history.states[index - 1]) != null ? _ref2.objectsInClass : void 0) != null ? _ref1 : {};
    for (cname in _ref3) {
      objects = _ref3[cname];
      for (_i = 0, _len = objects.length; _i < _len; _i++) {
        object = objects[_i];
        option = this.div.ownerDocument.createElement('option');
        option.setAttribute('value', cname);
        option.setAttribute('data-object-name', object);
        option.innerHTML = "With the " + cname + " " + object + ",";
        result.childNodes[0].appendChild(option);
      }
    }
    _ref4 = this.data.constructors;
    for (phrase in _ref4) {
      data = _ref4[phrase];
      option = this.div.ownerDocument.createElement('option');
      option.setAttribute('value', option.innerHTML = phrase);
      result.childNodes[0].appendChild(option);
    }
    if (select.get(0).childNodes.length === 0) {
      return result;
    }
    methods = this.div.ownerDocument.createElement('select');
    methods.setAttribute('id', "method-select-" + index);
    methods.setAttribute('class', 'form-control');
    methods.style.width = '80%';
    select.after(methods);
    hideMethods = function() {
      return ($(methods)).hide();
    };
    showMethods = function() {
      return ($(methods)).show();
    };
    hideMethods();
    fillMethods = (function(_this) {
      return function(className) {
        var _ref5, _ref6, _ref7;
        while (methods.childNodes.length > 0) {
          methods.removeChild(methods.childNodes[0]);
        }
        _ref7 = (_ref5 = ((_ref6 = _this.data.members) != null ? _ref6 : {})[className]) != null ? _ref5 : {};
        for (phrase in _ref7) {
          data = _ref7[phrase];
          option = _this.div.ownerDocument.createElement('option');
          option.setAttribute('value', option.innerHTML = phrase);
          methods.appendChild(option);
          if (methods.childNodes.length === 1) {
            ($(methods)).val(phrase);
          }
        }
        if (methods.childNodes.length === 0) {
          option = _this.div.ownerDocument.createElement('option');
          option.setAttribute('value', '');
          option.innerHTML = 'there is nothing you can do';
          methods.appendChild(option);
          return ($(methods)).val('');
        }
      };
    })(this);
    table = this.div.ownerDocument.createElement('div');
    table.setAttribute('id', "parameters-for-" + index);
    result.appendChild(table);
    result.appendChild(row = this.div.ownerDocument.createElement('div'));
    row.innerHTML = "<input type='button' value='Apply' class='btn btn-default btn-primary' id='apply-button-" + index + "'/> <input type='button' value='Cancel' class='btn btn-default btn-warning' id='cancel-button-" + index + "'/>";
    row.style.textAlign = 'right';
    showApply = function() {
      return ($("#apply-button-" + index, result)).show();
    };
    hideApply = function() {
      return ($("#apply-button-" + index, result)).hide();
    };
    showCancel = function() {
      return ($("#cancel-button-" + index, result)).show();
    };
    hideCancel = function() {
      return ($("#cancel-button-" + index, result)).hide();
    };
    hideCancel();
    updateParameterTable = (function(_this) {
      return function(newTable) {
        ($(table)).replaceWith(newTable);
        newTable.setAttribute('id', "parameters-for-" + index);
        table = newTable;
        ($('.command-ui-input', result)).change(function() {
          var _ref5;
          showApply();
          if (((_ref5 = _this.history.states[index]) != null ? _ref5.command : void 0) != null) {
            return showCancel();
          }
        });
        return ($('.command-ui-input', result)).keyup(function() {
          var _ref5;
          showApply();
          if (((_ref5 = _this.history.states[index]) != null ? _ref5.command : void 0) != null) {
            return showCancel();
          }
        });
      };
    })(this);
    ($(methods)).change((function(_this) {
      return function() {
        var method, _ref5;
        method = ($(methods)).val();
        updateParameterTable(_this.tableForFunction(index, select.val(), method));
        if (method !== '') {
          showApply();
          if (((_ref5 = _this.history.states[index]) != null ? _ref5.command : void 0) != null) {
            return showCancel();
          }
        } else {
          hideApply();
          return hideCancel();
        }
      };
    })(this));
    select.change((function(_this) {
      return function() {
        var choice, _ref5, _ref6;
        choice = select.val();
        if (((_ref5 = _this.data.constructors) != null ? _ref5[choice] : void 0) != null) {
          hideMethods();
          updateParameterTable(_this.tableForFunction(index, null, choice));
          showApply();
          if (((_ref6 = _this.history.states[index]) != null ? _ref6.command : void 0) != null) {
            return showCancel();
          }
        } else {
          fillMethods(choice);
          showMethods();
          return ($(methods)).change();
        }
      };
    })(this));
    select.change();
    updateViewAfter = (function(_this) {
      return function(deleteThis) {
        var i, n, start, _j, _k, _ref5, _results;
        if (deleteThis == null) {
          deleteThis = false;
        }
        while (result.nextSibling != null) {
          result.parentNode.removeChild(result.nextSibling);
        }
        if (deleteThis) {
          result.parentNode.removeChild(result);
        }
        n = _this.history.states.length;
        start = deleteThis ? index - 1 : index;
        for (i = _j = start; start <= n ? _j < n : _j > n; i = start <= n ? ++_j : --_j) {
          if (i > 0) {
            _this.div.appendChild(_this.history.states[i].element);
          }
          _this.div.appendChild(_this.createCommandUI(i + 1));
          if (i + 1 < n) {
            _this.writeAll(i + 1);
            _this.restoreSelects(i + 1);
          }
        }
        _results = [];
        for (i = _k = _ref5 = start + 1; _ref5 <= n ? _k < n : _k > n; i = _ref5 <= n ? ++_k : --_k) {
          ($("#apply-button-" + i, _this.div)).hide();
          _results.push(($("#cancel-button-" + i, _this.div)).hide());
        }
        return _results;
      };
    })(this);
    float = this.div.ownerDocument.createElement('div');
    float.style.float = 'right';
    float.innerHTML = "<button type='button' id='delete-command-" + index + "' class='btn btn-danger btn-sm'><span class='glyphicon glyphicon-remove'></span></button><button type='button' id='duplicate-command-" + index + "' class='btn btn-default btn-sm'><span class='glyphicon glyphicon-plus'></span></button>";
    result.insertBefore(float, result.childNodes[0]);
    deleteX = float.childNodes[0];
    ($(deleteX)).click((function(_this) {
      return function() {
        _this.history.deleteAction(index);
        updateViewAfter(true);
        return _this.updatePermalinkElement();
      };
    })(this));
    ($(deleteX)).hide();
    duplicate = float.childNodes[1];
    ($(duplicate)).click((function(_this) {
      return function() {
        _this.history.duplicateAction(index);
        updateViewAfter();
        return _this.updatePermalinkElement();
      };
    })(this));
    ($(duplicate)).hide();
    ($("#apply-button-" + index, result)).click((function(_this) {
      return function() {
        var choice, className, command, e, encodedParameters, funcData, i, objectName, paramData, parameters;
        choice = select.val();
        className = objectName = null;
        if (!(funcData = _this.data.constructors[choice])) {
          objectName = select.find(':selected').get(0).getAttribute('data-object-name');
          funcData = _this.data.members[choice][($(methods)).val()];
        }
        try {
          parameters = _this.readAll(index);
        } catch (_error) {
          e = _error;
          return alert("Fix the errors, starting with:\n\n" + e);
        }
        encodedParameters = (function() {
          var _j, _len1, _ref5, _results;
          _ref5 = funcData.parameters;
          _results = [];
          for (i = _j = 0, _len1 = _ref5.length; _j < _len1; i = ++_j) {
            paramData = _ref5[i];
            if (paramData.type === 'object') {
              _results.push({
                name: parameters[i]
              });
            } else {
              _results.push({
                value: parameters[i]
              });
            }
          }
          return _results;
        })();
        command = (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return Object(result) === result ? result : child;
        })(_this.Command, [objectName, funcData.call].concat(__slice.call(encodedParameters)), function(){});
        if (index === _this.history.states.length) {
          _this.history.appendAction(command);
        } else {
          _this.history.changeAction(index, command);
        }
        hideApply();
        hideCancel();
        updateViewAfter();
        _this.updatePermalinkElement();
        ($(deleteX)).show();
        return ($(duplicate)).show();
      };
    })(this));
    ($("#cancel-button-" + index, result)).click((function(_this) {
      return function() {
        _this.writeAll(index);
        _this.restoreSelects(index);
        hideApply();
        return hideCancel();
      };
    })(this));
    return result;
  };

  APISandbox.handlePermalink = function() {
    var e, index, queryString, state, _i, _len, _ref;
    queryString = window.location.href.split('?')[1];
    if (queryString === '' || queryString === null) {
      return;
    }
    queryString = decodeURIComponent(queryString);
    if (queryString === '' || queryString === null) {
      return;
    }
    try {
      JSON.parse(queryString);
    } catch (_error) {
      e = _error;
      return;
    }
    this.history.deserialize(queryString);
    _ref = this.history.states;
    for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
      state = _ref[index];
      if (index > 0) {
        this.div.appendChild(state.element);
        this.div.appendChild(this.createCommandUI(index + 1));
      }
      if (index < this.history.states.length - 1) {
        this.writeAll(index + 1);
        this.restoreSelects(index + 1);
      }
      ($("#apply-button-" + index, this.div)).hide();
      ($("#cancel-button-" + index, this.div)).hide();
    }
    return this.updatePermalinkElement();
  };

  APISandbox.permalinkElement = function() {
    var result;
    if (this._permalinkElement == null) {
      result = this.div.ownerDocument.createElement('a');
      result.setAttribute('href', '');
      result.innerHTML = 'Permalink';
      ($(result)).click((function(_this) {
        return function() {
          return window.location.href = _this.permalink();
        };
      })(this));
      this._permalinkElement = result;
    }
    return this._permalinkElement;
  };

  APISandbox.updatePermalinkElement = function() {
    return this.permalinkElement().setAttribute('href', APISandbox.permalink());
  };

  APISandbox.clearElement = function() {
    var result;
    result = this.div.ownerDocument.createElement('a');
    result.setAttribute('href', window.location.href.split('?')[0]);
    result.innerHTML = 'Clear';
    return result;
  };

}).call(this);

//# sourceMappingURL=app.js.map
