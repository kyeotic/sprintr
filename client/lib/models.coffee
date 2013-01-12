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
    constructor: (repository) ->
        @sprint = {}
        @id = 0
        
        @_repository = repository
        #generally this method should only be called by the autosubscribe
        update = ->
            @sprint = repository.findOne Session.get("sprintId")
            @id = @sprint?._id
        Meteor.autosubscribe update
        @subscribe = update #so templates can get a subscribable call
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
        story.tasks?.forEach (i) ->
            type = if i.isTestTask then 'TT' else 'TA'
            result += "\t#{i.points} - #{type} - #{i.name}\n"
        return result
    summary: (sprint = {}) ->
        if !@sprint? or !@sprint.workStories?
            return
        
        result = ""
        @sprint.workStories.forEach (i) =>
            result += "#{@storySummary(i)}\n"
        result += "\nTotal Points: #{@points()}"
        result += "\nCommitted Points: #{@committedPoints()}"
        result += "\nStretch Points: #{@stretchPoints()}"
        return result
        
    
    #Update the sprint collection
    update: (action, value) ->
        mod = {}
        mod[action] = value
        @_repository.update(@id, mod)
        return
    
    ###
    #WorkStory Methods
    ###
    getStory: (id) -> @sprint.workStories.find (i) -> i.id == id
    getStoryIndex: (id) -> @sprint.workStories.findIndex (i) -> i.id == id
    
    updateStory: (id, property, value, action = "$set") ->
        story = @getStory(id)
        storyIndex = @sprint.workStories.indexOf(story)
        
        if action == "$set"
            story[property] = value
        else if action == "$push"
            story[property].push(value)
            
        update = {}
        update["workStories.#{storyIndex}.#{property}"] = value
        @update(action, update)
    removeStory: (id) ->
        story = @getStory(id)
        @_repository.update(@id, { $pull: { workStories: story } })
    moveStory: (id, direction) ->
        story = @getStory(id)
        dir = if direction == "up" then "moveUp" else "moveDown"
        result =@sprint.workStories[dir](story)
        if result
            @update("$set", {workStories: @sprint.workStories})
        return result
    
    ###
    #Task Methods
    ###
    
    updateTask: (taskId, story, property, value) -> #No kids, only action is set
        taskIndex = story.tasks.findIndex (i) -> i.id == taskId
        @updateStory(story.id, "tasks.#{taskIndex}.#{property}", value)
    removeTask: (taskId, storyId) ->
        storyIndex = @getStoryIndex(storyId)
        task = @sprint.workStories[storyIndex].tasks.find (i) -> i.id == taskId
        update = {}
        update["workStories.#{storyIndex}.tasks"] = task
        #console.log update
        @_repository.update(@id, { $pull: update })        
    moveTask: (taskId, storyId, direction) ->
        story = @getStory(storyId)
        task = story.tasks.find (i) -> i.id == taskId
        dir = if direction == "up" then "moveUp" else "moveDown"
        result = story.tasks[dir](task)
        if result
            @updateStory(story.id, "tasks", story.tasks)
        return result
    
    



lib = window.app.lib || {}

lib.Task = Task
lib.WorkStory = WorkStory
lib.Sprint = Sprint
lib.SprintModel = SprintModel