###
Space Alert Web
Copyright (c) 2013 Jason Siefken <siefkenj @ gmail.com> - Licensed GPLv3
###



init = ->
    
    logger = new MissionLog(document.querySelector('#log'))
    window.soundFont = new SpaceAlert.Audio.AudioElmSoundFont()
    window.eventList = SpaceAlert.CommandSequence.makeCommandSequence(SpaceAlert.CommandSequence.NEW_FRONTIER_MISSION_1)
    window.sched = new SpaceAlert.Scheduler({eventList, soundFont, logger, speed: 1})
    console.log sched
    window.sched = sched

    hasFinishedDownloading = false
    finishedDownloadingCallback = null
    soundFont.downloadClips ->
        hasFinishedDownloading = true
        finishedDownloadingCallback?()
    
    document.querySelector('#play-button').onclick = ->
        if hasFinishedDownloading
            sched.play()
        else
            finishedDownloadingCallback = ->
                sched.play()
    document.querySelector('#pause-button').onclick = ->
        sched.pause()

    document.querySelector('#showclips-button').onclick = ->
        for _,clip of soundFont.clips when clip
            clip.controls = true
            clip.setAttribute('style','')
            document.body.appendChild clip


window.addEventListener('load', init, false)


# initialize with a ul element, then call .log to
# put well formatted log entries in.  Only threats,
# incoming data, and data transfers are shown
class MissionLog
    formatTime = (secs) ->
        min = Math.floor(secs/60)
        secs = secs % 60
        return "#{min}:#{("00" + secs).slice(-2)}"
    
    constructor: (@elm) ->
        ''
    log: (cmd) ->
        switch cmd.type
            when 'Threat'
                text = ""
                if cmd.serous
                    text += "Serious "
                switch cmd.zone
                    when 'Internal'
                        text += "<span class='internal'>Internal Threat</span> "
                    when 'White'
                        text += "Threat <span class='white'>Zone White</span> "
                    when 'Blue'
                        text += "Threat <span class='blue'>Zone Blue</span> "
                    when 'Red'
                        text += "Threat <span class='red'>Zone Red</span> "
                text += "(<span class='time'>Time #{cmd.round}</span>)"

                @elm.innerHTML += """<li><span class="timestamp">#{formatTime(cmd.time)}</span><span class="description threat">#{text}</span></li>"""
            when 'Incoming Data'
                text = "Incoming Data"
                @elm.innerHTML += """<li><span class="timestamp">#{formatTime(cmd.time)}</span><span class="description incoming-data">#{text}</span></li>"""
            when 'Data Transfer'
                text = "Data Transfer"
                @elm.innerHTML += """<li><span class="timestamp">#{formatTime(cmd.time)}</span><span class="description data-transfer">#{text}</span></li>"""
