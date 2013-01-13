Router = window.app.router
Lib = window.app.lib
SprintModel = window.app.SprintModel || {}

###
Sprint
###

#Id of the currently selected sprint
Session.set("sprintId", null)

#When editing a list name, ID of the list
Session.set('editingSprintName', false)


#used for forcing confirm on delete
Session.set("deleteConfirm", false)

Template.sprint.deleteButtonLabel = ->
    return if Session.get("deleteConfirm") then "Actually Delete" else "Delete Sprint"

Template.sprint.sprint = ->
    return Sprints.findOne(Session.get("sprintId")) #need to find a way around this

Template.sprint.events Lib.okCancelEvents "#sprint-name", {
        ok: (value) ->
            Sprints.update(this._id, {$set: {name: value}})
            Session.set('editingSprintName', false)
        cancel: () ->
            Session.set('editingSprintName', false)
    }

Template.sprint.events {
    "click #sprint-remove": (evt) ->
        if Session.get("deleteConfirm")
            Sprints.remove(this._id)
            Session.set("deleteConfirm", false)
            sprint = Sprints.findOne({}, {sort: {timestamp: -1}})
            if sprint
                Router.set(sprint._id)
            else
                Template.sprintList.newSprint()
        else
            Session.set("deleteConfirm", true)
            clear = -> Session.set("deleteConfirm", false)
            setTimeout(clear, 2000)
    "click .add-story": (evt) ->
        workStory =  new Lib.WorkStory()
        Sprints.update(this._id, { $push: { workStories: workStory } })
    "click .sprint-name": (evt, tmpl) ->
        Session.set('editingSprintName', true)
        Meteor.flush() # force DOM redraw, so we can focus the edit field
        Lib.activateInput(tmpl.find("#sprint-name"))
        return
}

Template.sprint.editingName = ->
    return Session.equals('editingSprintName', true)

Template.sprint.summary = ->
    if !SprintModel.subscribe
        return
    SprintModel.subscribe() #to set subcription for initial display
    return SprintModel.summary()

Template.sprint.workStories = ->
    #We can arrive before the context is set
    if !this.workStories
        return
    return this.workStories

Template.sprint.tasks = ->
    if !this.tasks
        return
    return this.tasks


###
WorkStory
###
Template.workstories.isCollapsed = ->
    return Session.get("story#{this.id}-isCollapsed") || false
Template.workstories.deleteLabel = ->
    return if Session.get("story#{this.id}-deleteconfirm") then "Actually Remove" else "Remove WorkStory"

Template.workstories.events Lib.okCancelEvents ".story-name", {
    ok: (value) ->
        if this.name == value then return
        SprintModel.updateStory(this.id, "name", value, "$set")
}

Template.workstories.events Lib.okCancelEvents ".story-points", {
    ok: (value) ->
        if this.points == value then return
        SprintModel.updateStory(this.id, "points", value, "$set")
}

Template.workstories.events {
    "click .add-task": (evt) ->
        SprintModel.updateStory(this.id, "tasks", new Lib.Task(), "$push")
    "click .story-commit": (evt) ->
        SprintModel.updateStory(this.id, "isCommitted", !this.isCommitted, "$set")
    "click .story-moveup": (evt) ->
        SprintModel.moveStory(this.id, "up")
    "click .story-movedown": (evt) ->
        SprintModel.moveStory(this.id, "down")
    "click .story-collapse": (evt, template) ->
        toggleStoryCollapse(this.id, getStoryNode(this.id, template))
        return
    "click .remove-story": (e, template) ->
        deleter = "story#{this.id}-deleteconfirm"
        if Session.get(deleter)
            Session.set(deleter, false)
            window.test = template
            #SprintModel.removeStory(this.id)
        else
            Session.set(deleter, true)
            clear = -> Session.set(deleter, false)
            setTimeout(clear, 2000)
        return
    "mousedown .story-move": (e, template) ->
        storyId = this.id
        storyNode = getStoryNode(this.id, template)
        setY = event.pageY
        setH = $(storyNode).height()        
        
        storyMove = (e) ->
            if Math.abs(e.pageY - setY) >= setH #(setH * 1.5) #Get halfway past
                direction = if e.pageY < setY then "up" else "down"
                if SprintModel.moveStory(storyId, direction)
                    setY = e.pageY
            return        
        $(window).mousemove(storyMove)        
        $(window).one "mouseup", ->
            $(window).unbind("mousemove", storyMove)
        return
}

getStoryNode = (id, template) ->
    storyIndex = SprintModel.getStoryIndex(id)
    return template.find(".story:nth-child(#{storyIndex + 1})") #stupid 0-1 index disagreement

toggleStoryCollapse = (id, story) ->
    collapser = "story#{id}-isCollapsed"
    body = $(story).find(".story-body")
    if Session.get(collapser)
        #unhide
        body.slideDown 400, ->
            Session.set(collapser, false)
    else
        #hide
        body.slideUp 400, ->
            Session.set(collapser, true)
    return

###
Task
###

Template.tasks.events Lib.okCancelEvents ".task-name", {
    ok: (value, event, template) ->
        if this.name == value then return
        SprintModel.updateTask(this.id, template.data, "name", value)
}

Template.tasks.events Lib.okCancelEvents ".task-points", {
    ok: (value, event, template) ->
        if this.points == value then return
        SprintModel.updateTask(this.id, template.data, "points", value)
}

Template.tasks.events {
    "click .remove-task": (event, template) ->
        SprintModel.removeTask(this.id, template.data.id)
    "click .task-moveup": (event, template) ->
        SprintModel.moveTask(this.id, template.data.id, "up")
    "click .task-movedown": (event, template) ->
        SprintModel.moveTask(this.id, template.data.id, "down")
    "mousedown .task-move": (event, template) ->
        taskId = this.id
        storyId = template.data.id
        setY = event.pageY        
        setH = $(template.firstNode.firstElementChild).height()        
        
        taskMove = (e) ->
            if Math.abs(e.pageY - setY) >= setH #(setH * 1.5) #Get halfway past
                direction = if e.pageY < setY then "up" else "down"
                if SprintModel.moveTask(taskId, storyId, direction)
                    setY = e.pageY
            return        
        $(window).mousemove(taskMove)        
        $(window).one "mouseup", ->
            $(window).unbind("mousemove", taskMove)
}


