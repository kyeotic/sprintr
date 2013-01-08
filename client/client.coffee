
Router = window.app.router
Lib = window.app.lib

Meteor.subscribe "sprints", ->
    if (!Session.get("sprintId"))
        
        sprint = Sprints.findOne({}, {sort: {timestamp: -1}})
        if sprint
            Router.set(sprint._id)
        else
            Template.sprintList.newSprint()

#Id of the currently selected sprint
Session.set("sprintId", null)

#
#Sprint List
#

Template.sprintList.items = ->
    return Sprints.find({}, {sort: {timestamp: -1}})
    
Template.sprintList.isActive = ->
    return this._id == Session.get("sprintId")

Template.sprintList.newSprint = ->
    newId = Sprints.insert({name: "New Sprint", timestamp: new Date()})
    Router.set(newId)
    
Template.sprintList.events {
    "click #new-sprint": (evt) ->
        Template.sprintList.newSprint()
        return
    "click .sprint-select": (evt) ->
        evt.preventDefault()
        Router.set(this._id)
        return
}

#
#Sprint
#

Session.set("deleteConfirm", false)
Template.sprint.deleteButtonLabel = ->
    return if Session.get("deleteConfirm") then "Actually Delete" else "Delete Sprint"

Template.sprint.sprint = ->
    return Sprints.findOne Session.get("sprintId")

Template.sprint.events Lib.okCancelEvents "#sprint-name",
    {
        ok: (value) ->
            Sprints.update(this._id, {$set: {name: value}})
            Meteor.flush()
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
}

Meteor.startup ->
    Meteor.autorun ->
        Router.onNavigate = ->
            Session.set("sprintId", @location)
        if Router.location != ""
            Router.onNavigate()