Router = window.app.router
Lib = window.app.lib

SelectedSprint = window.app.SelectedSprint ||  ->
    Sprints.findOne Session.get("sprintId")

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
    return Sprints.findOne Session.get("sprintId")

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
        ##SelectedSprint.workStories.push(workStory)
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
    sprint = SelectedSprint()
    if !sprint?.summary
        return
    #console.log SelectedSprint.summary()
    return sprint.summary()

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

updateSprint = (action, value) ->
    mod = {}
    mod[action] = value
    Sprints.update(SelectedSprint()._id, mod)

updateStory = (id, property, value, action = "$set") ->    
    sprint = SelectedSprint()
    story = sprint.workStories.find (i) -> return i.id == id
    storyIndex = sprint.workStories.indexOf(story)
    
    if action == "$set"
        story[property] = value
    else if action == "$push"
        story[property].push(value)
        
    update = {}
    update["workStories.#{storyIndex}.#{property}"] = value
    updateSprint(action, update)

Template.workstory.events Lib.okCancelEvents ".story-name", {
    ok: (value) ->
        updateStory(this.id, "name", value, "$set")
}

Template.workstory.events Lib.okCancelEvents ".story-points", {
    ok: (value) ->
        updateStory(this.id, "points", value, "$set")
}

Template.workstory.events {
    "click .add-task": (evt) ->
        updateStory(this.id, "tasks", new Lib.Task(), "$push")
    "click .story-commit": (evt) ->
        updateStory(this.id, "isCommitted", !this.isCommitted, "$set")
}

Template.workstory.events {
    "click .remove-story": (evt) ->
        storyId = this.id
        ##SelectedSprint.workStories.remove((i) -> i.id == storyId)
        Sprints.update(SelectedSprint()._id, { $pull: { workStories: this } })
}

###
Task
###

updateTask = (taskId, story, property, value) -> #No kids, only action is set
    taskIndex = story.tasks.findIndex (i) -> i.id == taskId
    updateStory(story.id, "tasks.#{taskIndex}.#{property}", value)

Template.task.events Lib.okCancelEvents ".task-name", {
    ok: (value, event, template) ->
        updateTask(this.id, template.data, "name", value)
}

Template.task.events Lib.okCancelEvents ".task-points", {
    ok: (value, event, template) ->
        updateTask(this.id, template.data, "points", value)
}

Template.task.events {
    "click .remove-task": (event, template) ->
        taskId = this.id
        sprint = SelectedSprint()
        storyIndex = sprint.workStories.findIndex (i) -> i.id == template.data.id
        ##SelectedSprint.workStories[storyIndex].tasks.remove((i) -> i.id == taskId)

        update = {}
        update["workStories.#{storyIndex}.tasks"] = this
        #console.log update
        Sprints.update(sprint._id, { $pull: update })
}

