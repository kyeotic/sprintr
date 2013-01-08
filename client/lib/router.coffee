
window.app = window.app || {}


class Router
    constructor: ->
        @location = window.location.hash.replace('#', '')
    set: (path) ->
        window.location.hash = @location = path.replace('#', '')    
    hashChange: =>
        @set(window.location.hash)
        @onNavigate()
    onNavigate: ->
        console.log "No navigate hanlder set, path is: #{@location}"
        
window.app.router = new Router()

window.onhashchange = window.app.router.hashChange
    