
#publish all sprints for now
Meteor.publish "sprints", ->
    return Sprints.find()