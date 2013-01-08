
Router = {}

Meteor.subscribe "sprints"

Meteor.startup ->
    Meteor.autorun ->
        Router = window.app.router
        Router.onNavigate = ->
            console.log "Meteor Router set, path is: #{@location}"
        if Router.location != ""
            Router.onNavigate()
        Router.set "test"

Template.sprintList.items = ->
    return [
        { name: "Sprint 1" }
        { name: "Sprint 2" }
    ]
Template.sprintList.isActive = ->
    return this.name == "Sprint 2"