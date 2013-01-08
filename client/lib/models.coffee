class Task
    constructor: (data) ->
        @points = 0
        @text = ""
        @isTestTask = false
        
class WorkStory
    constructor: (data = {}) ->
        @points = 0
        @isCommitted = true
        @text = ""
        @tasks = [new Task()]
    summary: ->
        label = if @isCommitted then "C" else "S"
        result = "#{@points}(#{label}) - #{@text}\n"
        @tasks.forEach (i) ->
            type = if i.isTestTask then 'TT' else 'TA'
            result += "\t#{i.points} - #{type} - #{i.text}\n"
        return result
        
class Sprint
    constructor: (data = {}) ->
        console.log data
        @name = data.name || "New Sprint"
        @timestamp = data.timestamp || new Date()
        workStories = []
        
        if (data.workStories?.length)
            data.workStories.forEach (i) ->
                workStories.push new WorkStory(i)
        else
            workStories.push new WorkStory()
        @workStories = workStories
    points: ->
        total = 0
        @workStories.forEach (i) -> total += parseInt i.points
        return total
    committedPoints: ->
        total = 0
        @workStories.forEach (i) -> 
            if i.isCommitted 
                total += parseInt i.points
        return total
    stretchPoints: ->
        Points: ->
        total = 0
        @workStories.forEach (i) -> 
            if !i.isCommitted 
                total += parseInt i.points
        return total
    summary: ->
        result = ""
        @workStories.forEach (i) ->
            result += "#{i.summary()}\n"
            result += "\nTotal Points: #{@points()}"
            result += "\nCommitted Points: #{@committedPoints()}"
            result += "\nStretch Points: #{@stretchPoints()}"
        return result
        
lib = window.app.lib || {}

lib.Task = Task
lib.WorkStory = WorkStory
lib.Sprint = Sprint