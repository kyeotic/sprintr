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
            setTimeout(clear, 3000)
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

Template.workstory.events Lib.okCancelEvents ".story-name", {
    ok: (value) ->
        SprintModel.updateStory(this.id, "name", value, "$set")
}

Template.workstory.events Lib.okCancelEvents ".story-points", {
    ok: (value) ->
        SprintModel.updateStory(this.id, "points", value, "$set")
}

Template.workstory.events {
    "click .add-task": (evt) ->
        SprintModel.updateStory(this.id, "tasks", new Lib.Task(), "$push")
    "click .story-commit": (evt) ->
        SprintModel.updateStory(this.id, "isCommitted", !this.isCommitted, "$set")
    "click .story-moveup": (evt) ->
        SprintModel.moveStory(this.id, "up")
    "click .story-movedown": (evt) ->
        SprintModel.moveStory(this.id, "down")
    "click .story-collapse": (evt, template) ->                
        body = template.find(".story-body")
        button = template.find(".story-collapse i")
        toggleStoryCollapse(this.id, button, body)
        return
}

iconExpand = "icon-chevron-down"
iconCollapse = "icon-chevron-right"

toggleStoryCollapse = (id, icon, body) ->
    collapser = "story#{id}-isCollapsed"
    unless Session.get(collapser)? #init the collapse as false
        Session.set(collapser, false)  
    Session.set(collapser, !Session.get(collapser))
    
    $(body).slideToggle()
    if Session.get(collapser)
        icon.classList.add iconCollapse
        icon.classList.remove iconExpand
    else
        icon.classList.remove iconCollapse
        icon.classList.add iconExpand

Template.workstory.isCollapsed = ->
    return Session.get("story#{this.id}-isCollapsed") || false

Template.workstory.events {
    "click .remove-story": (evt) ->
        SprintModel.removeStory(this.id)
}

###
Task
###

Template.task.events Lib.okCancelEvents ".task-name", {
    ok: (value, event, template) ->
        SprintModel.updateTask(this.id, template.data, "name", value)
}

Template.task.events Lib.okCancelEvents ".task-points", {
    ok: (value, event, template) ->
        SprintModel.updateTask(this.id, template.data, "points", value)
}

Template.task.events {
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
                SprintModel.moveTask(taskId, storyId, direction)
                setY = e.pageY
            return
        
        $(window).mousemove(taskMove)
        
        $(window).one "mouseup", ->
            $(window).unbind("mousemove", taskMove)        
}


