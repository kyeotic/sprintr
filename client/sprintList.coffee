Router = window.app.router
Lib = window.app.lib

#
#Sprint List
#

Template.sprintList.items = ->
    return Sprints.find({}, {sort: {timestamp: -1}})
    
Template.sprintList.isActive = ->
    return this._id == Session.get("sprintId")

Template.sprintList.newSprint = ->
    newId = Sprints.insert new Lib.Sprint()
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