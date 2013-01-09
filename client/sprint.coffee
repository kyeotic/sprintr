Router = window.app.router
Lib = window.app.lib
SelectedSprint = {}

Meteor.subscribe "sprints", ->
    if (!Session.get("sprintId"))        
        sprint = Sprints.findOne({}, {sort: {timestamp: -1}})
        if sprint
            Router.set(sprint._id)
        else
            Template.sprintList.newSprint()

Meteor.startup ->
    Meteor.autorun ->
        Router.onNavigate = ->
            Session.set("sprintId", @location)
            SelectedSprint = new Lib.Sprint Sprints.findOne(Session.get("sprintId"))
            #console.log SelectedSprint
            Meteor.flush()
        if Router.location != ""
            Router.onNavigate()

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
            sprint = Sprints.findOne({}, {sort: {name: 1}})
            if sprint
                Router.set(sprint._id)
            else
                Template.sprintList.newSprint()
        else
            Session.set("deleteConfirm", true)
            clear = -> Session.set("deleteConfirm", false)
            setTimeout(clear, 3000)
    "click .add-story": (evt) ->
        console.log "New Story"
        workStory =  new Lib.WorkStory()
        Sprints.update(this._id, { $push: { workStories: workStory } })
        console.log this
    "click .add-task": (evt) ->
        console.log this
    "click .sprint-name": (evt, tmpl) ->
        Session.set('editingSprintName', true)
        Meteor.flush() # force DOM redraw, so we can focus the edit field
        Lib.activateInput(tmpl.find("#sprint-name"))
        return    
}

Template.sprint.editingName = ->
    return Session.equals('editingSprintName', true)

Template.sprint.summary = ->
    if !SelectedSprint?.summary
        return
    #console.log SelectedSprint.summary()
    return SelectedSprint.summary()

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
            console.log "workstory update"
            storyIndex = SelectedSprint.workStories.indexOf(this)
            console.log storyIndex
            #Sprints.update(SelectedSprint._id, {$set: {name: value}})
    }
    