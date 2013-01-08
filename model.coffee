#Sprints


###
Each sprint is a document
sprints contain work stories
work stories contain tasks    

###

Sprints = new Meteor.Collection("sprints")

#clients can do any actions on sprints
Sprints.allow {
    insert: (sprint) -> true
    update: (id, sprint) -> true
    remove: (id, sprint) -> true
}