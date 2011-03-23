(function() {
  var Graft, R;
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  if (typeof Backbone != "undefined" && Backbone !== null) {
    return false;
  }
  Graft = Backbone.Graft = {};
  R = Graft.Reference = {};
  R.Model = Backbone.Model;
  R.Collection = Backbone.Collection;
  Graft.Joined = R.Model.extend({
    join: false,
    initialize: function(startModel, options) {
      var as, data, _ref;
      if ((startModel != null) && !startModel instanceof R.Model) {
        return false;
      }
      if (!options || !(options.as != null)) {
        return false;
      }
      as = options.as;
      (_ref = this.join) != null ? _ref : this.join = options.join;
      data = {};
      data[as] = startModel.toJSON();
      return this.set(data);
    },
    get: function(attrName) {
      var attr, attrs, result, _i, _len;
      attrs = attrName.split('.');
      result = R.Model.prototype.get.call(this, attrs.shift());
      for (_i = 0, _len = attrs.length; _i < _len; _i++) {
        attr = attrs[_i];
        result = result[attr];
      }
      return result;
    },
    mergeIn: function(joinModel, name) {
      if (joinModel instanceof Graft.Joined) {
        return _.each(joinModel, __bind(function(member) {
          var _ref;
          if (_ref = !member, __indexOf.call(this.toJSON(), _ref) >= 0) {
            throw "Can't join.";
            return false;
          }
        }, this));
      }
    }
  });
  Graft.Collection = R.Collection.extend({
    _findByAttribute: function(attr, value) {
      var ret;
      ret = this.select(function(member) {
        return member.get(attr) === value;
      });
      return ret;
    },
    filterByAttribute: function(attr, value) {
      var element, ret, _i, _len, _ref;
      ret = new Graft.Collection;
      _ref = this._findByAttribute(attr, value);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        element = _ref[_i];
        ret.add(element.toJSON());
      }
      return ret;
    },
    join: function() {
      var aliases, as, joinOrders, joined, order, _fn, _i, _len;
      as = arguments[0], joinOrders = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      aliases = _.pluck(joinOrders, 'as').push(as);
      if (!_.unique(aliases).length === aliases.length) {
        throw "All aliases in the join must be unique.";
        return false;
      }
      joined = new Graft.Collection;
      this.each(function(member) {
        return joined.add(new Graft.Joined(member, {
          as: as,
          join: true
        }));
      });
      _fn = __bind(function(order) {
        var name, _joined_, _ref;
        if (!(order.linkCollection != null) || !order.linkCollection instanceof Graft.Collection) {
          return false;
        }
        if (!(order.fromKey != null) || !(order.linkKey != null) || !(order.as != null)) {
          return false;
        }
        _joined_ = new Graft.Collection;
        name = (_ref = order.fromName) != null ? _ref : as;
        joined.each(function(member) {
          var match, matches, memberItems, _i, _len, _results;
          matches = order.linkCollection._findByAttribute(order.linkKey, member.get(name + '.' + order.fromKey));
          memberItems = member.toJSON();
          _results = [];
          for (_i = 0, _len = matches.length; _i < _len; _i++) {
            match = matches[_i];
            _results.push((function(match) {
              var joinData, joinMember;
              joinMember = new Graft.Joined;
              joinData = memberItems;
              joinData[order.as] = match.toJSON();
              joinMember.set(joinData);
              return _joined_.add(joinMember);
            })(match));
          }
          return _results;
        });
        return joined = _joined_;
      }, this);
      for (_i = 0, _len = joinOrders.length; _i < _len; _i++) {
        order = joinOrders[_i];
        _fn(order);
      }
      return joined;
    }
  });
  Graft.Overrun = function() {
    Backbone.Model = Graft.Joined;
    return Backbone.Collection = Graft.Collection;
  };
}).call(this);
