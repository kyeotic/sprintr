
Router = window.app.router
Lib = window.app.lib

Meteor.subscribe "sprints", ->
    count = Sprints.find().count()
    console.log "sprint count it #{count}"
    if (!Session.get("sprintId"))
        
        sprint = Sprints.findOne({}, {sort: {name: 1}})
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
    return Sprints.find({}, {sort: {name: 1}})
    
Template.sprintList.isActive = ->
    return this._id == Session.get("sprintId")

Template.sprintList.newSprint = ->
    newId = Sprints.insert({name: "New Sprint"})
    Router.set(newId)


#
#Sprint
#

Template.sprint.events Lib.okCancelEvents "#sprint-name",
    {
        ok: (text) -> Sprints.update(this._id, {$set: {name: value}})
    }


Meteor.startup ->
    Meteor.autorun ->
        Router.onNavigate = ->
            Session.set("sprintId", @location)
            console.log "Meteor Router set, path is: #{@location}"
        if Router.location != ""
            Router.onNavigate()