###
Space Alert Web
Copyright (c) 2013 Jason Siefken <siefkenj @ gmail.com> - Licensed GPLv3
###

###
# Audio classes.  There is currently one sound font
# hard coded to read reasourses frome res/*.mp3 directory.
###

URL = window.URL || window.webkitURL

###
# performs actions at the times specified by eventList.
# eventList = {timeInSeconds: {...}}
###
class Scheduler
    constructor: (args={}) ->
        {@eventList, @speed, @soundFont, @logger} = args
        @speed = @speed || 1

        @timeouts = []
        @currentTime = 0    #time in ms
        @events = ((+t)*1000 for t of @eventList)
        console.log @eventList, 'eventing', @events
        @timer = null
        @status = "paused"

    play: ->
        @status = "playing"
        createEventCallback = (time) =>
            return (=> @timeout(time))
        @timer = window.setInterval(@updateCurrentTime500, 500)
        for t in @events when t >= @currentTime
            @timeouts.push window.setTimeout(createEventCallback(t), (t - @currentTime)/@speed)
        return

    pause: ->
        @status = "paused"
        window.clearInterval(@timer)
        for id in @timeouts
            window.clearTimeout(id)
        @timeouts = []
        return

    updateCurrentTime500: =>
        @currentTime += 500 * @speed

    timeout: (time) =>
        # time is reported in ms, but events are always indexed by seconds
        time = time / 1000
        event = @eventList[time]
        if @soundFont?
            audioClip = @soundFont.getClip(event)
            audioClip.play()
        if @logger
            @logger.log(event)
        console.log('timeout', time, event)

###
# Abstract class for an AudioClip.  The space alert
# scheduler expects subclasses of AudioClip
###
class AudioClip
    duration: 0
    currentTime: 0
    play: -> throw new Error("Play method not implemented in #{@}")
    pause: -> throw new Error("Pause method not implemented in #{@}")

###
# Abstract class for a sound font.  getClip should accept
# a space alert command and return an AudioClip corresponding to that
# command.
###
class SpaceAlertSoundFont
    getClip: -> throw new Error("getClip method not implemented in #{@}")


###
# a SpaceAlertSoundFont that uses <audio> elements.
###
class AudioElmSoundFont extends SpaceAlertSoundFont
    ###
    # Some subclasses of AudioClip particular to the <audio> element
    ###
    
    ###
    # Creates an AudioClip that loops for the specified duration
    ###
    class AudioLoop extends AudioClip
        constructor: (@elm, @duration=Infinity) ->
            @timeout = null
            @currentTime = 0
            @numLoops = -1
        play: =>
            @_play()
            window.setTimeout(@pause, Math.floor(@duration*1000) - @currentTime)
        _play: =>
            @numLoops += 1
            @currentTime = Math.floor(1000 * @numLoops * @elm.duration)

            @elm.play()
            
            delay = Math.floor(1000*(@elm.duration - @elm.currentTime))
            # just in case, clear any old timeouts before we make new ones
            window.clearTimeout(@timeout)
            @timeout = window.setTimeout(@_play, delay)
        pause: =>
            window.clearTimeout(@timeout)
            @elm.pause()
            @currentTime = Math.floor(1000 * (@numLoops * @elm.duration + @elm.currentTime))
    ###
    # Creates an audio clip that plays each audio object 
    # in @seq one after another
    ####
    class AudioSequence extends AudioClip
        sum = (array) ->
            ret = 0
            for i in array
                ret += i
            return i
        
        constructor: (@clips) ->
            @currentTime = 0
            @currentlyPlaying = 0
            @durations = (Math.floor(a.duration*1000) for a in @clips)
            @startTimes = [0]
            for t,i in @durations when i < @durations.length - 1 #don't create that one excess entry in @startTimes
                @startTimes[i+1] = @startTimes[i] + t
            @duration = sum(@durations)
            @timeouts = []
            @status = "paused"
        play: ->
            @status = "playing"
            @timer = window.setInterval(@updateCurrentTime500, 500)
            
            createCallback = (clip) =>
                return =>
                    @currentlyPlaying = clip
                    @clips[clip].play()
                    @currentTime = @startTimes[@currentlyPlaying]

            # create the callbacks for all future events
            for startTime,i in @startTimes when startTime > @currentTime
                delay = startTime - @currentTime
                @timeouts.push window.setTimeout(createCallback(i), delay)
            # start the event we're possibly in the middle of
            if @currentTime - @startTimes[@currentlyPlaying] < @durations[@currentlyPlaying]
                @clips[@currentlyPlaying].play()
        pause: ->
            @status = "paused"
            window.clearInterval(@timer)
            for timeout in @timeouts
                window.clearTimeout(timeout)
            for clip in @clips
                clip.pause()
            @currentTime = @startTimes[@currentlyPlaying] + Math.floor(1000*@clips[@currentlyPlaying].currentTime)
        updateCurrentTime500: =>
            @currentTime += 500
    
    #
    # Main methods of AudioElmSoundFont
    #
    CLIP_FILENAMES: ["alert", "begin_first_phase", "communications_down", "communications_restored", "data_transfer", "first_phase_ends_in_1_minute", "first_phase_ends_in_20_seconds", "first_phase_ends", "incoming_data", "internal_threat", "operation_ends_in_1_minute", "operation_ends_in_20_seconds", "operation_ends", "pink_noise", "red_alert_0", "red_alert_1", "red_alert_2", "red_alert_3", "repeat", "second_phase_begins", "second_phase_ends_in_1_minute", "second_phase_ends_in_20_seconds", "second_phase_ends", "serious_internal_threat", "serious_threat", "third_phase_begins", "threat", "time_t_plus_1", "time_t_plus_2", "time_t_plus_3", "time_t_plus_4", "time_t_plus_5", "time_t_plus_6", "time_t_plus_7", "time_t_plus_8", "unconfirmed_report", "zone_blue", "zone_red", "zone_white"]
    CLIP_DIR_PREFIX: "res/"
    CLIP_DIR_SUFFIX: ".mp3"

    constructor: ->
        @clips = {}
        # populate the clips list
        #for elm in document.querySelectorAll('audio')
        #    @clips[elm.id] = elm
    # fetches all clips via XMLHTTPRequest
    # and calls callback when done
    downloadClips: (callback) ->
        urls = @CLIP_FILENAMES.map((x) => @CLIP_DIR_PREFIX + x + @CLIP_DIR_SUFFIX)
        @_unloadedClips = urls.length

        for url,i in urls
            request = new XMLHttpRequest()
            request.open('GET', url, true)
            #request.responseType = 'arraybuffer'
            request.responseType = 'blob'
            request.fileID = @CLIP_FILENAMES[i]     # keep around this id for later

            request.onload = (event) =>
                #blob = new Blob([event.currentTarget.response], {type: "audio/mp3"})
                console.log event, event.currentTarget.response
                blob = event.currentTarget.response

                audioElm = new Audio
                audioElm.src = URL.createObjectURL(blob)
                
                @clips[event.currentTarget.fileID] = audioElm
                # if the clips have already been loaded into the webpage, uncomment this
                #@clips[event.currentTarget.fileID] = document.querySelector("##{event.currentTarget.fileID}")
                @_unloadedClips -= 1
                if @_unloadedClips is 0
                    callback?()

            request.send()
        return


    getClip: (cmd) ->
        switch cmd.type
            when 'Incoming Data'
                return @clips['incoming_data']
            when 'Data Transfer'
                return @clips['data_transfer']
            when 'Phase End'
                switch cmd.phase
                    when 1
                        return new AudioSequence([@clips['first_phase_ends'], @clips['second_phase_begins']])
                    when 2
                        return new AudioSequence([@clips['second_phase_ends'], @clips['third_phase_begins']])
                    when 3
                        return @clips['operation_ends']
            when 'Phase Ending'
                switch cmd.phase
                    when 1
                        if cmd.delay is '20 Seconds'
                            return @clips['first_phase_ends_in_20_seconds']
                        else
                            return @clips['first_phase_ends_in_1_minute']
                    when 2
                        if cmd.delay is '20 Seconds'
                            return @clips['second_phase_ends_in_20_seconds']
                        else
                            return @clips['second_phase_ends_in_1_minute']
                    when 3
                        if cmd.delay is '20 Seconds'
                            return @clips['operation_ends_in_20_seconds']
                        else
                            return @clips['operation_ends_in_1_minute']
            when 'Threat'
                clipList = [@clips['alert']]
                if cmd.unconfirmed
                    clipList.push @clips['unconfirmed_report']

                clipList.push @clips["time_t_plus_#{cmd.round}"]

                if cmd.zone is 'Internal'
                    if cmd.serous
                        clipList.push @clips['serious_internal_threat']
                    else
                        clipList.push @clips['internal_threat']
                else
                    if cmd.serous
                        clipList.push @clips['serious_threat']
                    else
                        clipList.push @clips['threat']
                    switch cmd.zone
                        when 'Red'
                            clipList.push @clips['zone_red']
                        when 'White'
                            clipList.push @clips['zone_white']
                        when 'Blue'
                            clipList.push @clips['zone_blue']
                # once we have our commands, we repeat them once more without the alert
                clipList = clipList.concat([@clips['repeat']].concat(clipList.slice(1)))
                console.log clipList, 'cliplist'
                return new AudioSequence(clipList)
            when 'Comm Down'
                clipList = [@clips['communications_down'], new AudioLoop(@clips['white_noise'], cmd.duration), @clips['communications_restored']]
                return new AudioSequence(clipList)
        throw new Error("Unrecognized command in getClip")

window.SpaceAlert = window.SpaceAlert || {}
window.SpaceAlert.Audio = {SpaceAlertSoundFont, AudioElmSoundFont, AudioClip}
window.SpaceAlert.Scheduler = Scheduler
