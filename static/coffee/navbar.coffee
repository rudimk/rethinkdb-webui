
# navigation bar view. Not sure where it should go, putting it here
# because it's global.
class NavBarView extends Backbone.View
    className: 'navbar-view'
    template: Handlebars.compile $('#navbar_view-template').html()
    first_render: true

    initialize: ->
        log_initial '(initializing) NavBarView'
        # rerender when route changes

    init_typeahead: ->
        @.$('input.search-query').typeahead
            source: (typeahead, query) ->
                _machines = _.map machines.models, (machine) ->
                    uuid: machine.get('id')
                    name: machine.get('name') + ' (machine)'
                    type: 'servers'
                _datacenters = _.map datacenters.models, (datacenter) ->
                    uuid: datacenter.get('id')
                    name: datacenter.get('name') + ' (datacenter)'
                    type: 'datacenters'
                _namespaces = _.map namespaces.models, (namespace) ->
                    uuid: namespace.get('id')
                    name: namespace.get('name') + ' (namespace)'
                    type: 'tables'
                _databases = _.map databases.models, (database) ->
                    uuid: database.get('id')
                    name: database.get('name') + ' (database)'
                    type: 'databases'
                return _machines.concat(_datacenters).concat(_namespaces).concat(_databases)
            property: 'name'
            onselect: (obj) ->
                window.app.navigate('#' + obj.type + '/' + obj.uuid , { trigger: true })

    render: (route) =>
        log_render '(rendering) NavBarView'
        @.$el.html @template()
        # set active tab
        if route?
            @.$('ul.nav li').removeClass('active')
            if route is 'route:dashboard'
                $('ul.nav li#nav-dashboard').addClass('active')
            else if route is 'route:index_namespaces'
                $('ul.nav li#nav-namespaces').addClass('active')
            else if route is 'route:index_servers'
                $('ul.nav li#nav-servers').addClass('active')
            else if route is 'route:logs'
                $('ul.nav li#nav-logs').addClass('active')

        if @first_render is true
            # Initialize typeahead
            @init_typeahead()
            @first_render = false

        return @

