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

#store story id and task id when moving tasks in it
movingStory = "movingStory"
Session.set(movingStory, null)
movingTask = "movingTask"
Session.set(movingTask, null) 

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
        SprintModel.addStory()
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
SideBar
###

Template.sprintSideBar.committedPoints = -> 
   if !SprintModel.subscribe
        return
    SprintModel.subscribe() #to set subcription for initial display
    return SprintModel.committedPoints()
Template.sprintSideBar.stretchPoints = -> 
    if !SprintModel.subscribe
        return
    SprintModel.subscribe() #to set subcription for initial display
    return SprintModel.stretchPoints()
Template.sprintSideBar.totalPoints = -> 
    if !SprintModel.subscribe
        return
    SprintModel.subscribe() #to set subcription for initial display
    return SprintModel.points()
Template.sprintSideBar.events {
    "click #collapseAllStoriesButton": ->
        setAllStoriesCollapse(true)
    "click #expandAllStoriesButton": ->
        setAllStoriesCollapse(false)
}

###
WorkStory
###
Template.workstories.isCollapsed = ->
    return Session.get("story#{this.id}-isCollapsed") || false
Template.workstories.deleteStoryClass = ->
    return if Session.get("story#{this.id}-deleteconfirm") then "btn-danger" else "btn-inverse"    

Template.workstories.events Lib.okCancelEvents ".story-name", {
    ok: (value) ->
        console.log value
        console.log this
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
        SprintModel.addTask(this.id)
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
            SprintModel.removeStory(this.id)
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
        Session.set(movingStory, storyId)
        storyMove = (e) ->
            if Math.abs(e.pageY - setY) >= setH #(setH * 1.5) #Get halfway past
                direction = if e.pageY < setY then "up" else "down"
                if SprintModel.moveStory(storyId, direction)
                    setY = e.pageY
            return        
        $(window).mousemove(storyMove)        
        $(window).one "mouseup", ->
            Session.set(movingStory, null)
            $(window).unbind("mousemove", storyMove)
        return
    "keydown .story": (e, template) ->
        storyHotkeys(e, this.id, template)
        return
}

Template.workstories.storyDrag = ->
    movingStoryId = Session.get(movingStory)
    if !movingStoryId?
        return ""
    return if movingStoryId == this.id then "dragging" else "dragging-other"
    
selectLastTask = (storyId) ->
    story = SprintModel.getStory(storyId)
    taskId = story.tasks.last().id
    Meteor.flush()
    Lib.activateInput $(".tasks > ##{taskId} > input[name=\"name\"]")
selectStory = (storyId) ->
    Lib.activateInput $(".stories > ##{storyId} > [name=\"name\"]")
selectPreviousWorkStory = (storyId) ->
    storyIndex = SprintModel.getStoryIndex(storyId)
    if storyIndex <= 0 #can't move to previous if first
        return
    selectStory(SprintModel.sprint.workStories[storyIndex - 1].id)
selectNextWorkStory = (storyId) ->
    storyIndex = SprintModel.getStoryIndex(storyId)
    if storyIndex >= SprintModel.sprint.workStories.length - 1 #can't select next if last
        return
    selectStory(SprintModel.sprint.workStories[storyIndex + 1].id)
getStoryNode = (id) ->
    storyIndex = SprintModel.getStoryIndex(id)
    return $(".story##{id}:nth-child(#{storyIndex + 1})") #stupid 0-1 index disagreement
getStoryCollapseString = (id) -> return "story#{id}-isCollapsed"

toggleStoryCollapse = (id) ->
    setStoryCollapse(id, !Session.get(getStoryCollapseString(id)))
    return
setStoryCollapse = (id, hide) ->
    console.log getStoryNode(id)
    body = getStoryNode(id).find(".story-body")
    console.log body
    body[if hide then "slideUp" else "slideDown"] 400, ->
        Session.set(getStoryCollapseString(id), hide)
    return    
setAllStoriesCollapse = (hide) ->
    selectorMod = if hide then ":not(collapsed)" else ".collapsed"
    animation = if hide then "slideUp" else "slideDown"
    $(".story-body#{selectorMod}")[animation] 400, ->
        for story in SprintModel.sprint.workStories
            do (story) ->
                Session.set(getStoryCollapseString(story.id), hide)
    return
    

storyHotkeys = (e, storyId, template) ->
    if e.ctrlKey
        switch e.keyCode
            when 89 #y = new task
                SprintModel.addTask(storyId)
                selectLastTask(storyId)
            when 85 #u - select last task
                selectLastTask(storyId)
            when 219,38 #[ and up - previous story
                selectPreviousWorkStory(storyId)
            when 221,40 #] and down - next story
                selectNextWorkStory(storyId)
            when 77 #m - minimiza, maximize
                toggleStoryCollapse(storyId)
            else
                return
    else
        return
    e.preventDefault()
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
        Session.set(movingTask, {storyId: storyId, taskId: taskId})
        taskMove = (e) ->
            if Math.abs(e.pageY - setY) >= setH #(setH * 1.5) #Get halfway past
                direction = if e.pageY < setY then "up" else "down"
                if SprintModel.moveTask(taskId, storyId, direction)
                    setY = e.pageY
            return        
        $(window).mousemove(taskMove)        
        $(window).one "mouseup", ->
            Session.set(movingTask, null)
            $(window).unbind("mousemove", taskMove)
}

Template.tasks.taskDrag = (storyId) ->
    moving = Session.get(movingTask)
    if moving == null || moving.storyId != storyId
        return ""
    return if moving.taskId == this.id then "dragging" else "dragging-other"
    
###
#Hotkeys
###

###
    r = 82
    t = 87
    y = 89
    s = 83
    d = 68
    [ = 219
    ] = 221
    left = 37
    up = 38
    right = 39
    down= 40
    n = 78
###
hotkeys = (e) ->    
        
    if e.ctrlKey
        switch e.keyCode
            when 68 #s - new story
                SprintModel.addStory()
                Meteor.flush()
                selectStory(SprintModel.sprint.workStories.last().id)
            when 188 #comma - collapse all
                setAllStoriesCollapse(true)
            when 190 #. - expand all
                setAllStoriesCollapse(false)
            else
               return
    else
        return
    #console.log e
    e.preventDefault()
    return

#window.testEvent = hotkeys
window.document.addEventListener('keydown', hotkeys, false);
