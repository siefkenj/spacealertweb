###
Space Alert Web
Copyright (c) 2013 Jason Siefken <siefkenj @ gmail.com> - Licensed GPLv3
###


SpaceAlertCommandSequence =
    NEW_FRONTIER_MISSION_1: ["010AL2STW", "045UR3TR", "130AL3SIT", "155DT", "220ID", "250CS10", "320AL4TB", "355ID", "405DT", "450PE1", "520CS20", "555AL6TB", "615ID", "625DT", "645UR7TW", "715AL8STR", "735CS15", "820DT", "900PE2", "915CS20", "950DT", "1030DT", "1230PE3"]
    NEW_FRONTIER_MISSION_2: ["010AL1TR", "100AL2IT", "135ID", "200DT", "230AL3TW", "330DT", "355AL4TR", "450PE1", "500AL5TW", "520CS20", "545DT", "605UR7STR", "640AL7IT", "705ID", "725AL8STB", "810DT", "900PE2", "910CS10", "955DT", "1035CS30", "1210DT", "1300PE3"]
    NEW_FRONTIER_MISSION_3: ["015AL2STW", "100AL2IT", "130ID", "155AL3TB", "230CS10", "305AL4IT", "400DT", "450PE1", "500AL5TR", "520UR6STW", "600CS20", "630AL7STB", "655DT", "715ID", "730AL8STR", "810DT", "900PE2", "915CS20", "1000DT", "1100CS10", "1330PE3"]
    NEW_FRONTIER_MISSION_4: ["015AL1TR", "040ID", "105AL2STB", "200UR3TW", "235DT", "300CS10", "325DT", "355AL4SIT", "450PE1", "505AL5TB", "530DT", "545AL6STR", "610ID", "625CS15", "650AL7IT", "720AL7TW", "745DT", "805UR8TB", "855CS15", "940PE2", "1005CS30", "1050DT", "1235DT", "1330PE3"]
    NEW_FRONTIER_MISSION_5: ["015AL2IT", "040AL2STR", "105ID", "130CS20", "215DT", "235AL3STW", "325DT", "400AL4TR", "455PE1", "505UR5SIT", "535ID", "600AL6STB", "635DT", "650DT", "710CS10", "730AL7IT", "825AL8TW", "920PE2", "930DT", "1030CS25", "1100DT", "1205CS15", "1300PE3"]
    NEW_FRONTIER_MISSION_6: ["010UR1TR", "040AL2IT", "130AL3STW", "155ID", "210ID", "230AL4TB", "300DT", "325AL4IT", "345CS5", "420DT", "510PE1", "525AL5TR", "550AL6STW", "620DT", "650AL7TB", "710UR7IT", "745CS15", "815AL8TR", "840DT", "905CS10", "1000PE2", "1010CS10", "1030CS10", "1050CS20", "1140DT", "1220DT", "1400PE3"]
    
    ###
    # makeCommandSequence returns an object whose keys are seconds
    # and whose values are the space alert commands to be issued at that time.
    # list can be a list of commands in object format or flash-based string format
    ###
    makeCommandSequence: (list) ->
        ret = {}
        for cmd in list
            cmd = SpaceAlertCommandSequence.parse(cmd)
            ret[cmd.time] = cmd
        return ret
    ###
    # Returns an object representing the command cmd.
    # parse will turn string commands used by the flash-based
    # track generator into javascript objects.
    ###
    parse: (cmd) ->
        if cmd.type?
            return cmd

        ret = {}
        [_,time,rest] = cmd.match(/^(\d+)(.*)/) || []
        [_,min,sec] = time.match(/(\d+)(\d\d)$/) || []
        time = 60 * (+min) + (+sec)
        ret['time'] = +time
        
        if rest is 'ID'
            ret['type'] = "Incoming Data"
            return ret
        if rest is 'DT'
            ret['type'] = "Data Transfer"
            return ret
        if rest.slice(0,2) is 'PE'
            ret['type'] = "Phase End"
            ret['phase'] = +rest.slice(2)
            return ret
        if rest.slice(0,2) is 'CS'
            ret['type'] = "Comm Down"
            ret['duration'] = +rest.slice(2)
            return ret

        # if we've made it this far, we are either an unconfirmed report
        # or a threat report
        ret['type'] = "Threat"
        if rest.slice(0,2) is 'UR'
            ret['unconfirmed'] = true
            rest = rest.slice(2)
        if rest.slice(0,2) is 'AL'
            rest = rest.slice(2)

        [_,round,rest] = rest.match(/^(\d+)(.*)/) || []
        ret['round'] = +round

        if rest.charAt(0) is 'S'
            ret['serous'] = true
            rest = rest.slice(1)

        switch rest
            when 'TR'
                ret['zone'] = 'Red'
            when 'TW'
                ret['zone'] = 'White'
            when 'TB'
                ret['zone'] = 'Blue'
            when 'IT'
                ret['zone'] = 'Internal'

        return ret

window.SpaceAlert = window.SpaceAlert || {}
window.SpaceAlert.CommandSequence = SpaceAlertCommandSequence
