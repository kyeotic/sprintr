random = Meteor.random

class Task
    constructor: () ->
        @id = random()
        @points = 0
        @name = ""
        @isTestTask = false

class WorkStory
    constructor: (data = {}) ->
        @id = data.id || random()
        @points = data.points|| 0
        @isCommitted = data.isCommitted || true
        @name = data.name || ""

        @tasks = [new Task()]

class Sprint
    constructor: () ->
        @name = "New Sprint"
        @timestamp = new Date()
        @workStories = [new WorkStory()]

class SprintModel
    constructor: ->
        @sprint = {} #for tracking the sprint through callers
    points: ->
        total = 0
        @sprint.workStories?.forEach (i) -> total += parseInt i.points
        return total
    committedPoints: ->
        total = 0
        @sprint.workStories?.forEach (i) ->
            if i.isCommitted
                total += parseInt i.points
        return total
    stretchPoints: ->
        total = 0
        @sprint.workStories?.forEach (i) ->
            if !i.isCommitted
                total += parseInt i.points
        return total
    storySummary: (story) ->
        label = if story.isCommitted then "C" else "S"
        result = "#{story.points}(#{label}) - #{story.name}\n"
        story.tasks.forEach (i) ->
            type = if i.isTestTask then 'TT' else 'TA'
            result += "\t#{i.points} - #{type} - #{i.name}\n"
        return result
    summary: (sprint = {}) ->
        @sprint = sprint
        result = ""
        @sprint.workStories?.forEach (i) =>
            result += "#{@storySummary(i)}\n"
        result += "\nTotal Points: #{@points()}"
        result += "\nCommitted Points: #{@committedPoints()}"
        result += "\nStretch Points: #{@stretchPoints()}"
        return result

lib = window.app.lib || {}

lib.Task = Task
lib.WorkStory = WorkStory
lib.Sprint = Sprint
lib.SprintModel = new SprintModel()