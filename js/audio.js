// Generated by CoffeeScript 1.4.0
/*
Space Alert Web
Copyright (c) 2013 Jason Siefken <siefkenj @ gmail.com> - Licensed GPLv3
*/

/*
# Audio classes.  There is currently one sound font
# hard coded to read reasourses frome res/*.mp3 directory.
*/

var AudioClip, AudioElmSoundFont, Scheduler, SpaceAlertSoundFont, URL,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

URL = window.URL || window.webkitURL;

/*
# performs actions at the times specified by eventList.
# eventList = {timeInSeconds: {...}}
*/


Scheduler = (function() {

  function Scheduler(args) {
    var t;
    if (args == null) {
      args = {};
    }
    this.timeout = __bind(this.timeout, this);

    this.updateCurrentTime500 = __bind(this.updateCurrentTime500, this);

    this.eventList = args.eventList, this.speed = args.speed, this.soundFont = args.soundFont, this.logger = args.logger;
    this.speed = this.speed || 1;
    this.timeouts = [];
    this.currentTime = 0;
    this.events = (function() {
      var _results;
      _results = [];
      for (t in this.eventList) {
        _results.push((+t) * 1000);
      }
      return _results;
    }).call(this);
    console.log(this.eventList, 'eventing', this.events);
    this.timer = null;
    this.status = "paused";
  }

  Scheduler.prototype.play = function() {
    var createEventCallback, t, _i, _len, _ref,
      _this = this;
    this.status = "playing";
    createEventCallback = function(time) {
      return (function() {
        return _this.timeout(time);
      });
    };
    this.timer = window.setInterval(this.updateCurrentTime500, 500);
    _ref = this.events;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      t = _ref[_i];
      if (t >= this.currentTime) {
        this.timeouts.push(window.setTimeout(createEventCallback(t), (t - this.currentTime) / this.speed));
      }
    }
  };

  Scheduler.prototype.pause = function() {
    var id, _i, _len, _ref;
    this.status = "paused";
    window.clearInterval(this.timer);
    _ref = this.timeouts;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      id = _ref[_i];
      window.clearTimeout(id);
    }
    this.timeouts = [];
  };

  Scheduler.prototype.updateCurrentTime500 = function() {
    return this.currentTime += 500 * this.speed;
  };

  Scheduler.prototype.timeout = function(time) {
    var audioClip, event;
    time = time / 1000;
    event = this.eventList[time];
    if (this.soundFont != null) {
      audioClip = this.soundFont.getClip(event);
      audioClip.play();
    }
    if (this.logger) {
      this.logger.log(event);
    }
    return console.log('timeout', time, event);
  };

  return Scheduler;

})();

/*
# Abstract class for an AudioClip.  The space alert
# scheduler expects subclasses of AudioClip
*/


AudioClip = (function() {

  function AudioClip() {}

  AudioClip.prototype.duration = 0;

  AudioClip.prototype.currentTime = 0;

  AudioClip.prototype.play = function() {
    throw new Error("Play method not implemented in " + this);
  };

  AudioClip.prototype.pause = function() {
    throw new Error("Pause method not implemented in " + this);
  };

  return AudioClip;

})();

/*
# Abstract class for a sound font.  getClip should accept
# a space alert command and return an AudioClip corresponding to that
# command.
*/


SpaceAlertSoundFont = (function() {

  function SpaceAlertSoundFont() {}

  SpaceAlertSoundFont.prototype.getClip = function() {
    throw new Error("getClip method not implemented in " + this);
  };

  return SpaceAlertSoundFont;

})();

/*
# a SpaceAlertSoundFont that uses <audio> elements.
*/


AudioElmSoundFont = (function(_super) {
  var AudioLoop, AudioSequence;

  __extends(AudioElmSoundFont, _super);

  /*
      # Some subclasses of AudioClip particular to the <audio> element
  */


  /*
      # Creates an AudioClip that loops for the specified duration
  */


  AudioLoop = (function(_super1) {

    __extends(AudioLoop, _super1);

    function AudioLoop(elm, duration) {
      this.elm = elm;
      this.duration = duration != null ? duration : Infinity;
      this.pause = __bind(this.pause, this);

      this._play = __bind(this._play, this);

      this.play = __bind(this.play, this);

      this.timeout = null;
      this.currentTime = 0;
      this.numLoops = -1;
    }

    AudioLoop.prototype.play = function() {
      this._play();
      return window.setTimeout(this.pause, Math.floor(this.duration * 1000) - this.currentTime);
    };

    AudioLoop.prototype._play = function() {
      var delay;
      this.numLoops += 1;
      this.currentTime = Math.floor(1000 * this.numLoops * this.elm.duration);
      this.elm.play();
      delay = Math.floor(1000 * (this.elm.duration - this.elm.currentTime));
      window.clearTimeout(this.timeout);
      return this.timeout = window.setTimeout(this._play, delay);
    };

    AudioLoop.prototype.pause = function() {
      window.clearTimeout(this.timeout);
      this.elm.pause();
      return this.currentTime = Math.floor(1000 * (this.numLoops * this.elm.duration + this.elm.currentTime));
    };

    return AudioLoop;

  })(AudioClip);

  /*
      # Creates an audio clip that plays each audio object 
      # in @seq one after another
  */


  AudioSequence = (function(_super1) {
    var sum;

    __extends(AudioSequence, _super1);

    sum = function(array) {
      var i, ret, _i, _len;
      ret = 0;
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        i = array[_i];
        ret += i;
      }
      return i;
    };

    function AudioSequence(clips) {
      var a, i, t, _i, _len, _ref;
      this.clips = clips;
      this.updateCurrentTime500 = __bind(this.updateCurrentTime500, this);

      this.currentTime = 0;
      this.currentlyPlaying = 0;
      this.durations = (function() {
        var _i, _len, _ref, _results;
        _ref = this.clips;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          a = _ref[_i];
          _results.push(Math.floor(a.duration * 1000));
        }
        return _results;
      }).call(this);
      this.startTimes = [0];
      _ref = this.durations;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        t = _ref[i];
        if (i < this.durations.length - 1) {
          this.startTimes[i + 1] = this.startTimes[i] + t;
        }
      }
      this.duration = sum(this.durations);
      this.timeouts = [];
      this.status = "paused";
    }

    AudioSequence.prototype.play = function() {
      var createCallback, delay, i, startTime, _i, _len, _ref,
        _this = this;
      this.status = "playing";
      this.timer = window.setInterval(this.updateCurrentTime500, 500);
      createCallback = function(clip) {
        return function() {
          _this.currentlyPlaying = clip;
          _this.clips[clip].play();
          return _this.currentTime = _this.startTimes[_this.currentlyPlaying];
        };
      };
      _ref = this.startTimes;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        startTime = _ref[i];
        if (!(startTime > this.currentTime)) {
          continue;
        }
        delay = startTime - this.currentTime;
        this.timeouts.push(window.setTimeout(createCallback(i), delay));
      }
      if (this.currentTime - this.startTimes[this.currentlyPlaying] < this.durations[this.currentlyPlaying]) {
        return this.clips[this.currentlyPlaying].play();
      }
    };

    AudioSequence.prototype.pause = function() {
      var clip, timeout, _i, _j, _len, _len1, _ref, _ref1;
      this.status = "paused";
      window.clearInterval(this.timer);
      _ref = this.timeouts;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        timeout = _ref[_i];
        window.clearTimeout(timeout);
      }
      _ref1 = this.clips;
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        clip = _ref1[_j];
        clip.pause();
      }
      return this.currentTime = this.startTimes[this.currentlyPlaying] + Math.floor(1000 * this.clips[this.currentlyPlaying].currentTime);
    };

    AudioSequence.prototype.updateCurrentTime500 = function() {
      return this.currentTime += 500;
    };

    return AudioSequence;

  })(AudioClip);

  AudioElmSoundFont.prototype.CLIP_FILENAMES = ["alert", "begin_first_phase", "communications_down", "communications_restored", "data_transfer", "first_phase_ends_in_1_minute", "first_phase_ends_in_20_seconds", "first_phase_ends", "incoming_data", "internal_threat", "operation_ends_in_1_minute", "operation_ends_in_20_seconds", "operation_ends", "pink_noise", "red_alert_0", "red_alert_1", "red_alert_2", "red_alert_3", "repeat", "second_phase_begins", "second_phase_ends_in_1_minute", "second_phase_ends_in_20_seconds", "second_phase_ends", "serious_internal_threat", "serious_threat", "third_phase_begins", "threat", "time_t_plus_1", "time_t_plus_2", "time_t_plus_3", "time_t_plus_4", "time_t_plus_5", "time_t_plus_6", "time_t_plus_7", "time_t_plus_8", "unconfirmed_report", "zone_blue", "zone_red", "zone_white"];

  AudioElmSoundFont.prototype.CLIP_DIR_PREFIX = "res/";

  AudioElmSoundFont.prototype.CLIP_DIR_SUFFIX = ".mp3";

  function AudioElmSoundFont() {
    this.clips = {};
  }

  AudioElmSoundFont.prototype.downloadClips = function(callback) {
    var i, request, url, urls, _i, _len,
      _this = this;
    urls = this.CLIP_FILENAMES.map(function(x) {
      return _this.CLIP_DIR_PREFIX + x + _this.CLIP_DIR_SUFFIX;
    });
    this._unloadedClips = urls.length;
    for (i = _i = 0, _len = urls.length; _i < _len; i = ++_i) {
      url = urls[i];
      request = new XMLHttpRequest();
      request.open('GET', url, true);
      request.responseType = 'blob';
      request.fileID = this.CLIP_FILENAMES[i];
      request.onload = function(event) {
        var audioElm, blob;
        console.log(event, event.currentTarget.response);
        blob = event.currentTarget.response;
        audioElm = new Audio;
        audioElm.src = URL.createObjectURL(blob);
        _this.clips[event.currentTarget.fileID] = audioElm;
        _this._unloadedClips -= 1;
        if (_this._unloadedClips === 0) {
          return typeof callback === "function" ? callback() : void 0;
        }
      };
      request.send();
    }
  };

  AudioElmSoundFont.prototype.getClip = function(cmd) {
    var clipList;
    switch (cmd.type) {
      case 'Incoming Data':
        return this.clips['incoming_data'];
      case 'Data Transfer':
        return this.clips['data_transfer'];
      case 'Phase End':
        switch (cmd.phase) {
          case 1:
            return new AudioSequence([this.clips['first_phase_ends'], this.clips['second_phase_begins']]);
          case 2:
            return new AudioSequence([this.clips['second_phase_ends'], this.clips['third_phase_begins']]);
          case 3:
            return this.clips['operation_ends'];
        }
        break;
      case 'Phase Ending':
        switch (cmd.phase) {
          case 1:
            if (cmd.delay === '20 Seconds') {
              return this.clips['first_phase_ends_in_20_seconds'];
            } else {
              return this.clips['first_phase_ends_in_1_minute'];
            }
            break;
          case 2:
            if (cmd.delay === '20 Seconds') {
              return this.clips['second_phase_ends_in_20_seconds'];
            } else {
              return this.clips['second_phase_ends_in_1_minute'];
            }
            break;
          case 3:
            if (cmd.delay === '20 Seconds') {
              return this.clips['operation_ends_in_20_seconds'];
            } else {
              return this.clips['operation_ends_in_1_minute'];
            }
        }
        break;
      case 'Threat':
        clipList = [this.clips['alert']];
        if (cmd.unconfirmed) {
          clipList.push(this.clips['unconfirmed_report']);
        }
        clipList.push(this.clips["time_t_plus_" + cmd.round]);
        if (cmd.zone === 'Internal') {
          if (cmd.serous) {
            clipList.push(this.clips['serious_internal_threat']);
          } else {
            clipList.push(this.clips['internal_threat']);
          }
        } else {
          if (cmd.serous) {
            clipList.push(this.clips['serious_threat']);
          } else {
            clipList.push(this.clips['threat']);
          }
          switch (cmd.zone) {
            case 'Red':
              clipList.push(this.clips['zone_red']);
              break;
            case 'White':
              clipList.push(this.clips['zone_white']);
              break;
            case 'Blue':
              clipList.push(this.clips['zone_blue']);
          }
        }
        clipList = clipList.concat([this.clips['repeat']].concat(clipList.slice(1)));
        console.log(clipList, 'cliplist');
        return new AudioSequence(clipList);
      case 'Comm Down':
        clipList = [this.clips['communications_down'], new AudioLoop(this.clips['white_noise'], cmd.duration), this.clips['communications_restored']];
        return new AudioSequence(clipList);
    }
    throw new Error("Unrecognized command in getClip");
  };

  return AudioElmSoundFont;

}).call(this, SpaceAlertSoundFont);

window.SpaceAlert = window.SpaceAlert || {};

window.SpaceAlert.Audio = {
  SpaceAlertSoundFont: SpaceAlertSoundFont,
  AudioElmSoundFont: AudioElmSoundFont,
  AudioClip: AudioClip
};

window.SpaceAlert.Scheduler = Scheduler;