
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