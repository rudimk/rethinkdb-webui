#TODO remove the test functions
generate_id = (n) ->
    chars = '0123456789qwertasdfgzxcvbyuioplkjhnm'
    result = ''
    for i in [0..n]
        num = Math.floor(Math.random()*(chars.length+1))
        result += chars.substring(num, num+1)

    return result


generate_number = (n) ->
    return Math.floor(Math.random()*n)

generate_string = (n) ->
    chars = 'qwertasdfgzxcvbyuioplkjhnm'
    result = ''
    limit = Math.floor(Math.random()*n)+3
    for i in [Math.floor(limit/2)..limit]
        num = Math.floor(Math.random()*(chars.length+1))
        result += chars.substring(num, num+1)

    return result

#TODO Close connection
#TODO destroy views
#TODO maintain data
module 'DataExplorerView', ->
    class @Container extends Backbone.View
        className: 'dataexplorer_container'
        template: Handlebars.compile $('#dataexplorer_view-template').html()
        template_suggestion_name: Handlebars.compile $('#dataexplorer_suggestion_name_li-template').html()

        events:
            ###
            'keyup .input_query': 'handle_keypress'
            'keydown .input_query': 'handle_tab'
            'blur .input_query': 'hide_suggestion'
            'click .input_query': 'make_suggestion' # Click and not focus for webkit browsers
            ###
            'mousedown .suggestion_name_li': 'select_suggestion' # Keep mousedown to compete with blur on .input_query
            'mouseup .suggestion_name_li': 'position_cursor_after_click'
            'mouseover .suggestion_name_li' : 'mouseover_suggestion'
            'mouseout .suggestion_name_li' : 'mouseout_suggestion'
            'click .clear_query': 'clear_query'
            'click .execute_query': 'execute_query'
            'click .namespace_link': 'write_query_namespace'
            'click .old_query': 'write_query_old'
            'click .home_view': 'display_home'
            'click .change_size': 'toggle_size'

        displaying_full_view: false

        map_state:
            '': ''
            'r': 'db'
            'db': 'table'
            'table': 'stream'
            'get': 'view'
            'filter': 'stream'
            'range': 'stream'
            'length': 'value'
            'map': 'array'

        suggestions:
            stream: [
                {
                    suggestion: 'filter'
                    description: ''
                }
                {
                    suggestion: 'length'
                    description: ''
                }
                {
                    suggestion: 'map'
                    description: ''
                }
            ]
            view:[
                {
                    suggestion: 'view'
                    description: 'testing view'
                }
            ]
            db:[
            ]
            table:[
                {
                    suggestion: 'get'
                    description: ''}
                {
                    suggestion: 'insert'
                    description: ''}
            ]
            r:[
                {
                    suggestion: 'add'
                    description: ''
                }
                {
                    suggestion: 'and'
                    description: ''
                }
            ]
            "" :[
                {
                    suggestion: 'r'
                    description : 'The main ReQL namespace'
                }
                {
                    suggestion: 'r('
                    description : 'Variable'
                }

                {
                    suggestion: 'R('
                    description : 'Attribute Selector'
                }
            ]

        # We have to keep track of a lot of things because web-kit browsers handle the events keydown, keyup, blur etc... in a strange way.
        current_suggestions: []
        current_highlighted_suggestion: -1
        current_conpleted_query: ''
        query_first_part: ''
        query_last_part: ''

        write_suggestion: (suggestion_to_write) =>
            @codemirror.setValue @query_first_part + @current_completed_query + suggestion_to_write + @query_last_part

        mouseover_suggestion: (event) =>
            @highlight_suggestion event.target.dataset.id

        mouseout_suggestion: (event) =>
            @hide_suggestion_description()

        highlight_suggestion: (id) =>
            @.$('.suggestion_name_li').removeClass 'suggestion_name_li_hl'
            @.$('.suggestion_name_li').eq(id).addClass 'suggestion_name_li_hl'

            @.$('.suggestion_description').html @current_suggestions[id].description
            @show_suggestion_description()


        position_cursor: (position) =>
            @codemirror.setCursor position

        select_suggestion: (event) =>
            saved_cursor = @codemirror.getCursor()

            suggestion_to_write = @.$(event.target).html()
            @write_suggestion suggestion_to_write

            start_line_index = (@query_first_part + @current_completed_query).lastIndexOf('\n')
            if start_line_index is -1
                start_line_index = 0
            else
                start_line_index += 1

            @codemirror.focus()
            @cursor =
                line: saved_cursor.line
                ch: (@query_first_part + @current_completed_query + suggestion_to_write).length - start_line_index

        position_cursor_after_click: =>
            @position_cursor @cursor


        hide_suggestion: =>
            ###
            if @refocus_position isnt ''
                @position_cursor @refocus_position
                @refocus_position = ''
            ###
            @.$('.suggestion_name_list').css 'display', 'none'
            @hide_suggestion_description()

        hide_suggestion_description: ->
            @.$('.suggestion_description').html ''
            @.$('.suggestion_description').css 'display', 'none'

        show_suggestion: ->
            @.$('.suggestion_name_list').css 'display', 'block'

        show_suggestion_description: ->
            @.$('.suggestion_description').css 'display', 'block'


        expand_textarea: (event) =>
            if @.$('.input_query').length is 1
                @.$('.input_query').height 0
                height = @.$('.input_query').prop('scrollHeight') # We should have -8 but Firefox doesn't add padding in scrollHeight... Maybe we should start adding hacks...
                @.$('.input_query').css 'height', height if @.$('.input_query').height() isnt height

        # Make suggestions when the user is writing
        handle_keypress: (editor, event) =>
            saved_cursor = @codemirror.getCursor()
            if event?.which?
                if event.which is 9 # is tab
                    event.preventDefault()
                    if event.type isnt 'keydown'
                        return true
                    @current_highlighted_suggestion++
                    if @current_highlighted_suggestion >= @current_suggestions.length
                        @current_highlighted_suggestion = 0

                    if @current_suggestions[@current_highlighted_suggestion]?
                        @highlight_suggestion @current_highlighted_suggestion
                        @write_suggestion @current_suggestions[@current_highlighted_suggestion].suggestion
                
                        start_line_index = (@query_first_part + @current_completed_query).lastIndexOf('\n')
                        if start_line_index is -1
                            start_line_index = 0
                        else
                            start_line_index += 1
                        position = (@query_first_part + @current_completed_query + @current_suggestions[@current_highlighted_suggestion].suggestion).length - start_line_index 

                        @position_cursor
                            line: saved_cursor.line
                            ch: position


                    return true
                if event.which is 13 and (event.shiftKey or event.ctrlKey)
                    event.preventDefault()
                    if event.type isnt 'keydown'
                        return true
                    @.$('suggestion_name_list').css 'display', 'none'
                    @execute_query()
                    #@codemirror.blur()
            if event?.type? and event.type isnt 'keyup' # and event.which isnt 37 and event.which isnt 38 and event.which isnt 39 and event.which isnt 40 and event.which isnt 8
                return false

            @current_highlighted_suggestion = -1
            @.$('.suggestion_name_list').html ''

            query_lines = @codemirror.getValue().split '\n'
            # Get query before the cursor
            query_before_cursor = ''
            if @codemirror.getCursor().line > 0
                for i in [0..@codemirror.getCursor().line-1]
                    query_before_cursor += query_lines[i] + '\n'
            query_before_cursor += query_lines[@codemirror.getCursor().line].slice 0, @codemirror.getCursor().ch

            # Get query after the cursor
            query_after_cursor = query_lines[@codemirror.getCursor().line].slice @codemirror.getCursor().ch
            if query_lines.length > @codemirror.getCursor().line+1
                query_after_cursor += '\n'
                for i in [@codemirror.getCursor().line+1..query_lines.length-1]
                    if i isnt query_lines.length-1
                        query_after_cursor += query_lines[i] + '\n'
                    else
                        query_after_cursor += query_lines[i]

            # Check if we are in a string
            if (query_before_cursor.match(/\"/g)||[]).length%2 is 1
                @hide_suggestion()
                return ''
            


            slice_index = @extract_query_first_part query_before_cursor
            #TODO What is slice_index is -1?
            query = query_before_cursor.slice slice_index
            
            @query_first_part = query_before_cursor.slice 0, slice_index
            next_dot_position = query_after_cursor.indexOf('.')
            if next_dot_position is -1
                @query_last_part = ''
            else
                @query_last_part = query_after_cursor.slice next_dot_position
                if query_after_cursor[next_dot_position-1]? and query_after_cursor[next_dot_position-1] is '\n'
                    @query_last_part = '\n' + @query_last_part
            
            last_function = @extract_last_function(query)
            console.log last_function
            if @map_state[last_function]? and @suggestions[@map_state[last_function]]?
                suggestions = []
                for suggestion in @suggestions[@map_state[last_function]]
                    suggestions.push suggestion
                if last_function is 'r'
                    for database in databases.models
                        suggestions.unshift
                            suggestion: 'db(\''+database.get('name')+'\')'
                            description: 'Select database '+database.get('name')
                else if last_function is 'db'
                    for namespace in namespaces.models
                        suggestions.unshift
                            suggestion: 'table(\''+namespace.get('name')+'\')'
                            description: 'Select table '+namespace.get('name')

                if suggestions.length is 0
                    @hide_suggestion
                else
                    @append_suggestion(query, suggestions)

            return false

        extract_current_function: (query) =>
            #TODO Handle string
            start = query.lastIndexOf '.'
            if start is -1
                s = query
            else
                s = query.slice start+1

            end = s.indexOf '('
            if end is -1
                return s
            else
                return s.slice 0, end
 
        extract_last_function: (query) =>
            start = 0
            count_dot = 0
            num_not_open_parenthesis = 0
            for i in [query.length-1..0] by -1
                if query[i] is ')'
                    num_not_open_parenthesis++
                else if query[i] is '('
                    num_not_open_parenthesis--
                else if query[i] is '.' and num_not_open_parenthesis <= 0
                    count_dot++
                    if count_dot is 2
                        start = i+1
                        break
            dot_position = query.indexOf('.', start) 
            dot_position = query.length if dot_position is -1
            parenthesis_position = query.indexOf('(', start) 
            parenthesis_position = query.length if parenthesis_position is -1

            end = Math.min dot_position, parenthesis_position

            return query.slice start, end



        # Return the position of the beggining of the first subquery
        extract_query_first_part: (query) ->
            is_string = false
            count_opening_parenthesis = 0
            for i in [query.length-1..0] by -1
                if query[i] is '"'
                    is_string = !is_string
                else
                    if is_string
                        continue
                    else
                        if query[i] is '('
                            count_opening_parenthesis++
                            if count_opening_parenthesis > 0
                                return i+1
                        else if query[i] is ')'
                            count_opening_parenthesis--
            return 0

        append_suggestion: (query, suggestions) =>
            splitdata = query.split('.')
            @current_completed_query = ''
            if splitdata.length>1
                for i in [0..splitdata.length-2]
                    @current_completed_query += splitdata[i]+'.'
            element_currently_written = splitdata[splitdata.length-1]


            for char in @unsafe_to_safe_regexstr
                element_currently_written = element_currently_written.replace char.pattern, char.replacement

            found_suggestion = false
            pattern = new RegExp('^('+element_currently_written+')', 'i')
            @current_suggestions = []
            for suggestion, i in suggestions
                if pattern.test(suggestion.suggestion)
                    found_suggestion = true
                    @current_suggestions.push suggestion
                    @.$('.suggestion_name_list').append @template_suggestion_name 
                        id: i
                        suggestion: suggestion.suggestion
            if found_suggestion
                @show_suggestion()
            else
                @hide_suggestion()
            return @


        callback_render: (data) =>
            @data_container.render(@query, data)

        execute_query: =>
            window.result = {}

            #@query = @.$('.input_query').val()
            @query = @codemirror.getValue()
            full_query = @query + '.run(this.callback_render)'
            try
                eval(full_query)
            catch err
                @data_container.render_error(err)


            ###
            welcome = q.table('Welcome-rdb')

            for i in [0..20]
                welcome.insert({id: i, num: 20-i}).run()

            welcome.length().run(print)
            welcome.filter({'id': 1}).run(print)
            welcome.filter().run(print)


            query = @.$('.input_query').val() + '.run(call)'
            eval(query)
            @data_container.render(query, result)

            query = @.$('.input_query').val()
            @data_container.add_query(query)
            window.router.sidebar.add_query(query)
            #TODO ajax callsuggestion loading
            if query is '0'
                result = []
            else if query is '1'
                result =  [
                    _id: '97a54c09-112e-4e32-86f8-24522e6e1df4'
                    login: 'michel'
                    first_name: 'Michel'
                    last_name: 'Tu'
                    email: 'michel@rethinkdb.com'
                    messages: 52.54
                    inscription_date: '04/26/1998'
                    citizen_id: null
                    member: true
                    website: "http://www.neumino.com"
                    groups: [
                            id: 'a53e4190-dfcc-4810-aded-a3d4f422e9b9'
                            name: 'front end developers'
                        ,
                            id: 'ebcdb08d-302c-4403-a392-eadad3f5bea5'
                            name: 'rethinkDB'
                    ]
                    skills:
                        development:
                            'javascript': 9
                            'css': 9
                            'c++': 2
                        music:
                            'violin': 0
                            'piano': 1
                            'guitare': 2
                    last_score: [ 54, 43, 11, 95, 78]
                ]
            else
                result = []
                for i in [0..20]
                    element = {}
                    element['_id'] = generate_id(25)
                    element['name'] = generate_string(9)+' '+generate_string(9)
                    element['mail'] = generate_string(8)+'@'+generate_string(6)+'.com'
                    element['age'] = generate_number(100)
                    element['possess_car'] = false
                    element['driver_license'] = null
                    element['last_scores'] = []
                    limit = generate_number(20)
                    for p in [0..limit]
                        element['last_scores'].push generate_number(100)
                    element['phone'] =
                        home: generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)
                        mobile: generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)
                    element['website'] = 'http://www.'+generate_string(12)+'.com'
                    if query is '100'
                        element[generate_string(10)] = generate_string(10)
                    

                    result.push element

                delete result[result.length-1]['phone']['mobile']
                delete result[result.length-1]['website']
            @data_container.render(query, result)
            ###

        clear_query: =>
            #TODO remove when not testing
            welcome = r.db('Welcome-db').table('Welcome-rdb')
            welcome.insert({
                id: generate_id(25)
                name: generate_string(9)+' '+generate_string(9)
                mail: generate_string(8)+'@'+generate_string(6)+'.com'
                age: generate_number(100)
                possess_car: false
                driver_license: null
                phone:
                    home: generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)
                    mobile: generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)+'-'+generate_number(10)+''+generate_number(10)+''+generate_number(10)+''+generate_number(10)
                website: 'http://www.'+generate_string(12)+'.com'
                }).run()

            @.$('.input_query').val ''
            @.$('.input_query').focus()

        # Write a query for the namespace clicked
        write_query_namespace: (event) =>
            event.preventDefault()
            query = 'r.'+event.target.dataset.name+'.find()'
            @.$('.input_query').focus() # Keep this order to have focus at the end of the textarea
            @.$('.input_query').val query

        # Write an old query in the input
        write_query_old: (event) =>
            event.preventDefault()
            @.$('.input_query').focus() # Keep this order to have focus at the end of the textarea
            @.$('.input_query').val event.target.dataset.query

        initialize: =>
            log_initial '(initializing) dataexplorer view:'
            
            host = window.location.hostname
            ###
            port = window.location.port
            if port is ''
                port = 13457
            else
                port = parseInt(port)-1000+13457
            window.conn = new rethinkdb.net.HttpConnection 
                host: host
                port: port
            ###
            window.conn = new rethinkdb.net.HttpConnection 'http://'+host+':'+window.location.port+'/ajax/reql'
            window.r = rethinkdb.query
            window.R = r.R


            #TODO Make this little thing prettier
            @unsafe_to_safe_regexstr = []
            @unsafe_to_safe_regexstr.push # This one has to be firest
                pattern: /\\/g
                replacement: '\\\\'
            @unsafe_to_safe_regexstr.push
                pattern: /\(/g
                replacement: '\\('
            @unsafe_to_safe_regexstr.push
                pattern: /\)/g
                replacement: '\\)'
            @unsafe_to_safe_regexstr.push
                pattern: /\^/g
                replacement: '\\^'
            @unsafe_to_safe_regexstr.push
                pattern: /\$/g
                replacement: '\\$'
            @unsafe_to_safe_regexstr.push
                pattern: /\*/g
                replacement: '\\*'
            @unsafe_to_safe_regexstr.push
                pattern: /\+/g
                replacement: '\\+'
            @unsafe_to_safe_regexstr.push
                pattern: /\?/g
                replacement: '\\?'
            @unsafe_to_safe_regexstr.push
                pattern: /\./g
                replacement: '\\.'
            @unsafe_to_safe_regexstr.push
                pattern: /\|/g
                replacement: '\\|'
            @unsafe_to_safe_regexstr.push
                pattern: /\{/g
                replacement: '\\{'
            @unsafe_to_safe_regexstr.push
                pattern: /\}/g
                replacement: '\\}'
   



            @input_query = new DataExplorerView.InputQuery
            @data_container = new DataExplorerView.DataContainer

            @render()

        render: =>
            @.$el.html @template
            @.$el.append @input_query.render().el
            @.$el.append @data_container.render().el
            return @

        call_codemirror: =>
            @codemirror = CodeMirror.fromTextArea document.getElementById('input_query'),
                mode:
                    name: 'javascript'
                    json: true
                onKeyEvent: @handle_keypress
                onFocus: @handle_keypress
                onBlur: @hide_suggestion
                lineNumbers: true
                lineWrapping: true
                matchBrackets: true

            @codemirror.setSize 700, 100

        # Go home
        display_home: =>
            @.$el.append @data_container.render().el
            return @

        toggle_size: =>
            if @displaying_full_view
                @display_normal()
                @displaying_full_view = false
            else
                @display_full()
                @displaying_full_view = true

        display_normal: =>
            $('.main-container').width '940'
            $('#cluster').width 700
            $('.input_query').width 678
            $('.dataexplorer_container').removeClass 'full_container'
            $('.dataexplorer_container').css 'margin', '0px'
            $('.change_size').val 'Full view'

        display_full: =>
            width = $(window).width() - 220 -40
            $('.main-container').width '100%'
            $('#cluster').width width
            $('.input_query').width width-45
            $('.dataexplorer_container').addClass 'full_container'
            $('.dataexplorer_container').css 'margin', '0px 0px 0px 20px'
            $('.change_size').val 'Smaller view'

        destroy: =>
            @input_query.destroy()
            @data_container.destroy()

    
    class @InputQuery extends Backbone.View
        className: 'query_control'
        template: Handlebars.compile $('#dataexplorer_input_query-template').html()
 
        render: =>
            @.$el.html @template()
            return @

        destroy: ->
            @.$('.input_query').off()


    class @DataContainer extends Backbone.View
        className: 'data_container'
        error_template: Handlebars.compile $('#dataexplorer-error-template').html()

        initialize: ->
            @default_view = new DataExplorerView.DefaultView
            @result_view = new DataExplorerView.ResultView

        add_query: (query) =>
            @default_view.add_query(query)

        render: (query, result) =>
            if query? and result?
                @.$el.html @result_view.render(query, result).el
                @result_view.delegateEvents()
            else
                @.$el.html @default_view.render().el

            return @

        render_error: (err) =>
            @.$el.html @error_template 
                error: err.toString()
            return @

        destroy: =>
            @default_view.destroy()


    class @ResultView extends Backbone.View
        className: 'result_view'
        template: Handlebars.compile $('#dataexplorer_result_container-template').html()
        template_no_result: Handlebars.compile $('#dataexplorer_result_empty-template').html()
        template_json_tree: 
            'container' : Handlebars.compile $('#dataexplorer_result_json_tree_container-template').html()
            'span': Handlebars.compile $('#dataexplorer_result_json_tree_span-template').html()
            'span_with_quotes': Handlebars.compile $('#dataexplorer_result_json_tree_span_with_quotes-template').html()
            'url': Handlebars.compile $('#dataexplorer_result_json_tree_url-template').html()
            'email': Handlebars.compile $('#dataexplorer_result_json_tree_email-template').html()
            'object': Handlebars.compile $('#dataexplorer_result_json_tree_object-template').html()
            'array': Handlebars.compile $('#dataexplorer_result_json_tree_array-template').html()

        template_json_table:
            'container' : Handlebars.compile $('#dataexplorer_result_json_table_container-template').html()
            'tr_attr': Handlebars.compile $('#dataexplorer_result_json_table_tr_attr-template').html()
            'td_attr': Handlebars.compile $('#dataexplorer_result_json_table_td_attr-template').html()
            'tr_value': Handlebars.compile $('#dataexplorer_result_json_table_tr_value-template').html()
            'td_value': Handlebars.compile $('#dataexplorer_result_json_table_td_value-template').html()
            'td_value_content': Handlebars.compile $('#dataexplorer_result_json_table_td_value_content-template').html()
            'data_inline': Handlebars.compile $('#dataexplorer_result_json_table_data_inline-template').html()

        events:
            # Global events
            'click .link_to_raw_view': 'expand_raw_textarea'
            # For Tree view
            'click .jt_arrow': 'toggle_collapse'
            'keypress .jt_editable': 'handle_keypress'
            'blur .jt_editable': 'send_update'
            # For Table view
            'mousedown td': 'handle_mousedown'
            'click .jta_arrow_v': 'expand_tree_in_table'
            'click .jta_arrow_h': 'expand_table_in_table'


        current_result: []

        initialize: =>
            $(document).mousemove @handle_mousemove
            $(document).mouseup @handle_mouseup

        json_to_tree: (result) =>
            return @template_json_tree.container 
                tree: @json_to_node(result)

        #TODO catch RangeError: Maximum call stack size exceeded?
        #TODO check special characters
        #TODO what to do with new line?
        json_to_node: (value) =>
            value_type = typeof value
            
            output = ''
            if value is null
                return @template_json_tree.span
                    classname: 'jt_null'
                    value: 'null'
            else if value.constructor? and value.constructor is Array
                if value.length is 0
                    return '[ ]'
                else
                    sub_values = []
                    for element in value
                        sub_values.push 
                            value: @json_to_node element
                        if typeof element is 'string' and (/^(http|https):\/\/[^\s]+$/i.test(element) or  /^[a-z0-9._-]+@[a-z0-9]+.[a-z0-9._-]{2,4}/i.test(element))
                            sub_values[sub_values.length-1]['no_comma'] = true


                    sub_values[sub_values.length-1]['no_comma'] = true
                    return @template_json_tree.array
                        values: sub_values
            else if value_type is 'object'
                sub_values = []
                for key of value
                    last_key = key
                    sub_values.push
                        key: key
                        value: @json_to_node value[key]
                    #TODO Remove this check by sending whether the comma should be add or not
                    if typeof value[key] is 'string' and (/^(http|https):\/\/[^\s]+$/i.test(value[key]) or  /^[a-z0-9._-]+@[a-z0-9]+.[a-z0-9._-]{2,4}/i.test(value[key]))
                        sub_values[sub_values.length-1]['no_comma'] = true

                if sub_values.length isnt 0
                    sub_values[sub_values.length-1]['no_comma'] = true

                data =
                    no_values: false
                    values: sub_values

                if sub_values.length is 0
                    data.no_value = true

                return @template_json_tree.object data
            else if value_type is 'number'
                return @template_json_tree.span
                    classname: 'jt_num'
                    value: value
            else if value_type is 'string'
                if /^(http|https):\/\/[^\s]+$/i.test(value)
                    return @template_json_tree.url
                        url: value
                else if /^[a-z0-9]+@[a-z0-9]+.[a-z0-9]{2,4}/i.test(value) # We don't handle .museum extension and special characters
                    return @template_json_tree.email
                        email: value

                else
                    return @template_json_tree.span_with_quotes
                        classname: 'jt_string'
                        value: value
            else if value_type is 'boolean'
                return @template_json_tree.span
                    classname: 'jt_bool'
                    value: value
 


        json_to_table: (result) =>
            if not (result.constructor? and result.constructor is Array)
                result = [result]

            map = {}
            for element in result
                if jQuery.isPlainObject(element)
                    for key of element
                        if map[key]?
                            map[key]++
                        else
                            map[key] = 1
                else
                    map['_anonymous object'] = Infinity

            keys_sorted = []
            for key of map
                keys_sorted.push [key, map[key]]

            keys_sorted.sort((a, b) ->
                if a[1] < b[1]
                    return 1
                else if a[1] > b[1]
                    return -1
                else
                    if a[0] < b[0]
                        return -1
                    else if a[0] > b[0]
                        return 1
                    else return 0
            )

            return @template_json_table.container
                table_attr: @json_to_table_get_attr keys_sorted
                table_data: @json_to_table_get_values result, keys_sorted

        json_to_table_get_attr: (keys_sorted) ->
            attr = []
            for element, col in keys_sorted
                attr.push
                    key: element[0]
                    col: col
 
            return @template_json_table.tr_attr 
                attr: attr

        json_to_table_get_values: (result, keys_stored) ->
            document_list = []
            for element in result
                new_document = {}
                new_document.cells = []
                for key_container, col in keys_stored
                    key = key_container[0]
                    if key is '_anonymous object'
                        value = element
                    else
                        value = element[key]

                    new_document.cells.push @json_to_table_get_td_value value, col

                document_list.push new_document
            return @template_json_table.tr_value
                document: document_list

        json_to_table_get_td_value: (value, col) =>
            data = @compute_data_for_type(value, col)

            return @template_json_table.td_value
                class_td: 'col-'+col
                cell_content: @template_json_table.td_value_content data
            
        compute_data_for_type: (value,  col) =>
            data =
                value: value
                class_value: 'value-'+col

            value_type = typeof value
            if value is null
                data['value'] = 'null'
                data['classname'] = 'jta_null'
            else if value is undefined
                data['value'] = 'undefined'
                data['classname'] = 'jta_undefined'
            else if value.constructor? and value.constructor is Array
                if value.length is 0
                    data['value'] = '[ ]'
                    data['classname'] = 'empty array'
                else
                    #TODO Build preview
                    #TODO Add arrows for attributes
                    data['value'] = '[ ... ]'
                    data['data_to_expand'] = JSON.stringify(value)
            else if value_type is 'object'
                data['value'] = '{ ... }'
                data['data_to_expand'] = JSON.stringify(value)
            else if value_type is 'number'
                data['classname'] = 'jta_num'
            else if value_type is 'string'
                if /^(http|https):\/\/[^\s]+$/i.test(value)
                    data['classname'] = 'jta_url'
                else if /^[a-z0-9]+@[a-z0-9]+.[a-z0-9]{2,4}/i.test(value) # We don't handle .museum extension and special characters
                    data['classname'] = 'jta_email'
                else
                    data['classname'] = 'jta_string'
            else if value_type is 'boolean'
                data['classname'] = 'jta_bool'

            return data


        expand_tree_in_table: (event) =>
            dom_element = @.$(event.target).parent()
            data = dom_element.data('json_data')
            result = @json_to_tree data
            dom_element.html result
            classname_to_change = dom_element.parent().attr('class').split(' ')[0] #TODO Use a Regex
            $('.'+classname_to_change).css 'max-width', 'none'
            classname_to_change = dom_element.parent().parent().attr('class')
            $('.'+classname_to_change).css 'max-width', 'none'
 
            @.$(event.target).parent().css 'max-width', 'none'
            @.$(event.target).remove() #TODO Fix this trick



        expand_table_in_table: (event) ->
            dom_element = @.$(event.target).parent()
            parent = dom_element.parent()
            classname = dom_element.parent().attr('class').split(' ')[0] #TODO Use a regex
            data = dom_element.data('json_data')
            if data.constructor? and data.constructor is Array
                classcolumn = dom_element.parent().parent().attr('class')
                $('.'+classcolumn).css 'max-width', 'none'
                join_table = @join_table
                $('.'+classname).each ->
                    $(this).children('.jta_arrow_v').remove()
                    new_data = $(this).children('.jta_object').data('json_data')
                    if new_data? and new_data.constructor? and new_data.constructor is Array
                        $(this).children('.jta_object').html join_table(new_data)
                        $(this).children('.jta_arrow_h').remove()
                    $(this).css 'max-width', 'none'
                        
            else if typeof data is 'object'
                classcolumn = dom_element.parent().parent().attr('class')
                map = {}
                $('.'+classname).each ->
                    new_data = $(this).children('.jta_object').data('json_data')
                    if new_data? and typeof new_data is 'object'
                        for key of new_data
                            if map[key]?
                                map[key]++
                            else
                                map[key] = 1
                    $(this).css 'max-width', 'none'
                keys_sorted = []
                for key of map
                    keys_sorted.push [key, map[key]]

                # TODO Use a stable sort, Mozilla doesn't use a stable sort for .sort
                keys_sorted.sort (a, b) ->
                    if a[1] < b[1]
                        return 1
                    else if a[1] > b[1]
                        return -1
                    else
                        if a[0] < b[0]
                            return -1
                        else if a[0] > b[0]
                            return 1
                        else return 0
                for i in [keys_sorted.length-1..0] by -1
                    key = keys_sorted[i]
                    collection = $('.'+classcolumn)

                    is_description = true
                    template_json_table_td_attr = @template_json_table.td_attr
                    json_to_table_get_td_value = @json_to_table_get_td_value

                    collection.each ->
                        if is_description
                            is_description = false
                            prefix = $(this).children('.jta_attr').html()
                            $(this).after template_json_table_td_attr
                                classtd: classcolumn+'-'+i
                                key: prefix+'.'+key[0]
                                col: $(this).data('col')+'-'+i
                        else
                            new_data = $(this).children().children('.jta_object').data('json_data')
                            if new_data? and new_data[key[0]]?
                                value = new_data[key[0]]
                                    
                            full_class = classname+'-'+i
                            col = full_class.slice(full_class.indexOf('-')+1) #TODO Replace this trick

                            $(this).after json_to_table_get_td_value(value, col)
                            
                        return true

                $('.'+classcolumn) .remove();


        join_table: (data) =>
            result = ''
            for value, i in data
                data_cell = @compute_data_for_type(value, 'float')
                data_cell['is_inline'] = true
                if i isnt data.length-1
                    data_cell['need_comma'] = true

                result += @template_json_table.data_inline data_cell
                 
            return result

        #TODO change cursor
        mouse_down: false
        handle_mousedown: (event) ->
            if event.target.nodeName is 'TD' and event.which is 1
                @event_target = event.target
                @col_resizing = event.target.dataset.col
                @start_width = @.$(event.target).width()
                @start_x = event.pageX
                @mouse_down = true
                @.$('.json_table').toggleClass('resizing', true)

        #TODO Handle when last column is resized or when table expands too much
        handle_mousemove: (event) =>
            if @mouse_down
                # +30 for padding
                # Fix bug with Firefox (-30) or fix chrome bug...
                $('.col-'+@col_resizing).css 'max-width', @start_width-@start_x+event.pageX
                $('.value-'+@col_resizing).css 'max-width', @start_width-@start_x+event.pageX-20

                $('.col-'+@col_resizing).css 'width' ,@start_width-@start_x+event.pageX
                $('.value-'+@col_resizing).css 'width', @start_width-@start_x+event.pageX-20

        handle_mouseup: (event) =>
            @mouse_down = false
            @.$('.json_table').toggleClass('resizing', false)

        render: (query, result, type) =>
            @current_result = result

            @.$el.html @template
                query: query
            
            if @current_result.length is 0
                @.$('.results').html @template_no_result
                @.$('#tree_view').addClass 'active'
                return @

            @.$('#tree_view').html @json_to_tree @current_result
            @.$('#table_view').html @json_to_table @current_result
            @.$('.raw_view_textarea').html JSON.stringify @current_result
 
            if !type?
                type = 'json'
                ### No table view per default
                if @current_result.length is 1
                    type = "json"
                else
                    type = "table"
                ###


            #TODO We should really remove bootstraps...
            switch type
                when  'json'
                    @.$('.link_to_tree_view').tab 'show'
                    @.$('#tree_view').addClass 'active'
                    @.$('#table_view').removeClass 'active'
                    @.$('#raw_view').removeClass 'active'
                when  'table'
                    @.$('.link_to_table_view').tab 'show'
                    @.$('#table_view').addClass 'active'
                    @.$('#tree_view').removeClass 'active'
                    @.$('#raw_view').removeClass 'active'
                when  'raw'
                    @.$('.link_to_raw_view').tab 'show'
                    @.$('#raw_view').addClass 'active'
                    @.$('#table_view').removeClass 'active'
                    @.$('#tree_view').removeClass 'active'
 

            @delegateEvents()

            return @

        toggle_collapse: (event) =>
            @.$(event.target).nextAll('.jt_collapsible').toggleClass('jt_collapsed')
            @.$(event.target).nextAll('.jt_points').toggleClass('jt_points_collapsed')
            @.$(event.target).nextAll('.jt_b').toggleClass('jt_b_collapsed')
            @.$(event.target).toggleClass('jt_arrow_hidden')

       
        handle_keypress: (event) =>
            if event.which is 13 and !event.shiftKey
                event.preventDefault()
                @.$('suggestion_name_list').css 'display', 'none'
                @.$(event.target).blur()

        on_editable_blur: (data) ->
            @send_update(data)


        #TODO Fix it for Firefox
        expand_raw_textarea: =>
            setTimeout(@bootstrap_hack, 0) #TODO remove this trick when we will remove bootstrap's tab 
        bootstrap_hack: =>
            @expand_textarea 'raw_view_textarea'
            return @

        expand_textarea: (classname) =>
            if $('.'+classname).length > 0
                height = $('.'+classname)[0].scrollHeight
                $('.'+classname).height(height)

        #TODO complete method
        #TODO change color
        #TOOD handle change type
        send_update: (target) ->
            console.log 'update'

    class @DefaultView extends Backbone.View
        className: 'helper_view'
        template: Handlebars.compile $('#dataexplorer_default_view-template').html()
        template_query: Handlebars.compile $('#dataexplorer_query_element-template').html()
        template_query_list: Handlebars.compile $('#dataexplorer_query_list-template').html()


        history_queries: []

        initialize :->
            namespaces.on 'all', @render

        add_query: (query) =>
            @history_queries.unshift query
            # Let's check if the list already exists
            if @history_queries.length is 1
                @.$('.history_query_container').html @template_query_list

            #TODO Trunk query
            @.$('.history_query_list').prepend @template_query 
                query: query

        render: => 
            json = {}
            json.namespaces = []
            for namespace in namespaces.models
                json.namespaces.push
                    name: namespace.get('name')

            json.has_namespaces = if json.namespaces.length is 0 then false else true

            json.has_old_queries = if @history_queries.length is 0 then false else true
            json.old_queries = @history_queries

            @.$el.html @template json
        
            return @

        destroy: ->
            namespaces.off()
