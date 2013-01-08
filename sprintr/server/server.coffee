
#publish all sprints for now
Meteor.publish "sprints", ->
    return Parties.find()