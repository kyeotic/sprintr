
Router = window.app.router
Lib = window.app.lib
SelectedSprint = {}

#select the first sprint, or make a new one if none exist
selectSprintDefault = ->      
    sprint = Sprints.findOne({}, {sort: {timestamp: -1}})
    if sprint
        Router.set(sprint._id)
    else
        Template.sprintList.newSprint()

Meteor.subscribe "sprints", ->
    Router.onNavigate = ->
        
        Session.set("sprintId", @location)  # Set the session for tracking      
        sprint = Sprints.findOne(Session.get("sprintId"))
        
        if !sprint #We can't find the sprint based on the URL, select default
            console.log @location
            selectSprintDefault()
            return
            
        SelectedSprint = new Lib.Sprint sprint #load sprint into model
        #console.log SelectedSprint
        Meteor.flush()
    
    
    if Router.location != "" #if a location exists, go to it
        Router.onNavigate()
    else
        selectSprintDefault()

Meteor.startup ->
    #startup stuff