# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/



ready = ->
    $("input:text").focus ->
        $(this).select()
        
    $("input:text").click ->
        $(this).select()
    
    if $('.btn-info').length > 0
        $("#dialog1").dialog
            autoOpen: false
            width: 520
            buttons : 
                Ok: ->
                    $(this).dialog("close")
        
        $('#btn-info1').on "click", ->
            $("#dialog1").dialog("open")
            
        $("#dialog2").dialog
            autoOpen: false
            width: 520
            buttons : 
                Ok: ->
                    $(this).dialog("close")
        
        $('#btn-info2').on "click", ->
            $("#dialog2").dialog("open")    
            
            
    if $('#add-more-button').length > 0
        timesClicked = 1
        $('#add-more-button').on "click", ->
            $(".click-" + timesClicked).fadeIn()
            timesClicked = timesClicked + 1
            if timesClicked == 4
                $('#add-more-button').fadeOut()
            
    if $('.teachReqOption').length > 0
        $('.teachReqOption').on "click", ->
            $('.teachReqOption').removeClass("highSingOpt").addClass("lowSingOpt")
            $(this).addClass("highSingOpt")
            req_id = $(this).attr('req_id')
            seminar_student_id = $(this).attr('seminar_student_id')
            url = '/seminar_students/'+seminar_student_id
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    seminar_student:
                        teach_request: req_id
                    
    if $('.learnReqOption').length > 0
        $('.learnReqOption').on "click", ->
            $('.learnReqOption').removeClass("highSingOpt").addClass("lowSingOpt")
            $(this).addClass("highSingOpt")
            req_id = $(this).attr('req_id')
            seminar_student_id = $(this).attr('seminar_student_id')
            url = '/seminar_students/'+seminar_student_id
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    seminar_student:
                        learn_request: req_id
                        
                    
    if $('.prefReqOption').length > 0
        $('.prefReqOption').on "click", ->
            $('.prefReqOption').removeClass("highSingOpt").addClass("lowSingOpt")
            $(this).addClass("highSingOpt")
            req_id = $(this).attr('req_id')
            seminar_student_id = $(this).attr('seminar_student_id')
            url = '/seminar_students/'+seminar_student_id
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    seminar_student:
                        pref_request: req_id
    
    if $('.achievement_change').length > 0
        $('.achievement_change').on "change", ->
            checkpoint_id = $(this).attr('checkpoint_id')
            url = '/checkpoints/'+checkpoint_id
            $('#achievement_text_'+checkpoint_id).text($("option:selected", this).text())
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    checkpoint:
                        achievement: $(this).val()
            
    
    if $('.goal_approval').length > 0
        $('.goal_approval').on "click", ->
            if $(this).text() == "Lock This Goal"
                send_boolean = true
                new_text = "Unlock This Goal"
                $(this).addClass("unlock_button")
            else
                send_boolean = false
                new_text = "Lock This Goal"
                $(this).removeClass("unlock_button")
            gs_id = $(this).attr('gs_id')
            url = '/goal_students/'+gs_id
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    goal_student:
                        approved: send_boolean
            $(this).text(new_text)

        $('.goal_change').on "change", ->
            gs_id = $(this).attr('gs_id')
            url = '/goal_students/'+gs_id
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    goal_student:
                        approved: true
                        goal_id: $(this).val()
            $('#approval_button_'+gs_id).fadeOut()
            $('#goal_text_'+gs_id).text($("option:selected", this).text())
    
    $('.target_text').on "click", ->
        gs_id = $(this).attr('gs_id')
        $(this).hide()
        $('#target_span_'+gs_id).show()
    
    $('.target_change').on "change", ->
        gs_id = $(this).attr('gs_id')
        url = '/goal_students/'+gs_id
        $.ajax
            type: "PUT",
            url: url,
            dataType: "json"
            data:
                goal_student:
                    approved: true
                    target: $(this).val()
        $(this).fadeOut()
        $('#target_text_'+gs_id).show()
        $('#target_text_'+gs_id).text($(this).val())
        
    $('#goal_student_goal_id').on "change", ->
        $('.currently_hidden').show()
                        
    if $('.checkpoint_change').length > 0
        $('.checkpoint_change').on "change", ->
            checkpoint_id = $(this).attr('checkpoint_id')
            url = '/checkpoints/'+checkpoint_id
            $('#checkpoint_text_'+checkpoint_id).text($("option:selected", this).text())
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    checkpoint:
                        action: $(this).val()
                        
    
    if $('.tyrion').length > 0
        $('.seatButt').prop("disabled",true)
        currSeating = $('.tyrion').val().split(" ")
        currNeed = $('.jaime').val().split(" ")
        $('.tyrion').val(currSeating)
        $('.jaime').val(currNeed)
        
        $('.draggable-item').draggable
            stack: '.droppable-item'
            stack: '.draggable-item'
            start: (event, ui) ->
                if $(this).parent().attr("id") == "orphans"
                    orphanIndex = currNeed.indexOf($(this).attr("id"))
                    currNeed.splice(orphanIndex,1)
                    $('.jaime').val(currNeed)
                    
                else
                    seat = $(this).closest(".seat").attr("id")-1000;
                    currSeating[seat] = 0
                    $('.tyrion').val(currSeating)
                
                    
        $('.droppable-item').droppable
            over: (event, ui) ->
                $(this).addClass("my-placeholder")
            drop: (event, ui) ->
                $(this).removeClass("my-placeholder")
                if ($(this).children().length) > 0
                    oldStudent = $(this).children().first()
                    $("#dashOutline").hide()
                    oldStudent.detach().addClass("block").appendTo(".orphans")
                    currNeed.push(oldStudent.attr("id"))
                    $('.jaime').val(currNeed)
                justdragged = $(ui.draggable) 
                kid = justdragged.attr("id")
                seat = $(this).attr("id")-1000
                currSeating[seat] = kid
                $('.tyrion').val(currSeating)
                justdragged.removeClass("block")
                $(this).append(justdragged.removeAttr('style'))
                if ($('#orphans').children().size()) == 1
                    $("#dashOutline").show()
                $('.seatButt').prop("disabled",false)
            out: (event, ui) ->
                $(this).removeClass("my-placeholder")
            
                
        $('.supernaut').droppable
            drop: (event, ui) ->
                $("#dashOutline").hide()
                justdragged = $(ui.draggable)
                kid = justdragged.attr("id")
                currNeed.push(kid)
                $('.jaime').val(currNeed)
                justdragged.removeAttr('style').detach().addClass("block").appendTo(".orphans")
                $('.seatButt').prop("disabled",false)
    
    $('#toggle_text').on "click", ->
        if $('.to_unhide').hasClass("currently_hidden")
            $('.to_unhide').fadeIn()
            $('.to_unhide').removeClass("currently_hidden")
            $(this).text($(this).attr("first_text"))
        else
            $('.to_unhide').fadeOut()
            $('.to_unhide').addClass("currently_hidden")
            $(this).text($(this).attr("second_text"))
   
   
    if $('.clickySeat').length > 0
        $('.clickySeat').on "click", ->
            this_present_marking = $(this).find(".presentTag")
            seminar_student_id = $(this).attr('id').replace('attendance_div_','')
            url = '/seminar_students/'+seminar_student_id
            if this_present_marking.text() == "Absent"
                attendance = true
                $(this).removeClass("absent")
                this_present_marking.text("Present")
            else
                attendance = false
                $(this).addClass("absent")
                this_present_marking.text("Absent")
            $.ajax
                type: "PUT",
                url: url,
                dataType: "json"
                data:
                    seminar_student:
                        present: attendance
    
    if $('#scoreTable').length > 0
        $("#r0c0").focus()
        
        $('.score_cell').focus ->
            $('.score_box').removeClass('highlighted')
            $('.row_'+$(this).attr("cell_row")).addClass('highlighted')
            $('.col_'+$(this).attr("cell_col")).addClass('highlighted')
        
        $(".score_cell").keydown (e) ->
            if e.which == 38
                next_row = parseInt($(this).attr("cell_row")) - 1
                next_col = parseInt($(this).attr("cell_col"))
                
            else if e.which == 40
                next_row = parseInt($(this).attr("cell_row")) + 1
                next_col = parseInt($(this).attr("cell_col"))
                
            else if e.which == 37
                next_row = parseInt($(this).attr("cell_row"))
                next_col = parseInt($(this).attr("cell_col")) - 1
                
            else if e.which == 39
                next_row = parseInt($(this).attr("cell_row"))
                next_col = parseInt($(this).attr("cell_col")) + 1
            
            $("#r"+next_row+"c"+next_col).focus()
            callback = -> 
                $("#r"+next_row+"c"+next_col).select()
            setTimeout callback, 10
        
    
    if $('#dialog5').length > 0
        unpressed = true
        $("#dialog5").dialog
            autoOpen: false
            width: 520
            buttons : 
                Ok: ->
                    $(this).dialog("close")
                    
        $('.boulderfist').on "click", (event) ->
            if unpressed and $(this).prop("checked") == true
                $("#dialog5").dialog("open")
                
    if $('.select_box').length > 0
        $('.select_box').on "change", (event) ->
            points_poss = 0
            $(".left_box").each (index, element) =>
                a = $(element).val()
                partner_num = $(element).attr('partner')
                b = $("#syl_"+partner_num+"_point_value").val()
                points_poss += a * b
        
            $('#total_disp').text(points_poss)
    
    if $('.reveal').length > 0
        $('.reveal'). on "click", (event) ->
            submenu = $(this).attr("submenu")
            $('.reveal').removeClass('highlighted')
            $(this).addClass('highlighted')
            $('.submenu_item').hide()
            $('.submenu_'+submenu).show()
     
    if $('.remove_btn').length > 0
        $('.cancel_button').hide()
        $('.confirm_button').hide()
        $('.remove_btn').on "click", (event) ->
            id_to_fade = $(this).prop("id").replace('delete_','')
            $('#confirm_'+id_to_fade).text("Confirm")
            $('#confirm_'+id_to_fade).fadeIn()
            $('#cancel_'+id_to_fade).fadeIn()
            $(this).removeClass("btn btn-small btn-primary")
        $('.cancel_button').on "click", (event) ->
            id_to_fade = $(this).prop("id").replace('cancel_','')
            $('#confirm_'+id_to_fade).fadeOut()
            $(this).fadeOut()
            return false
    
    if $('.datepicker').length > 0
        $('.datepicker').on "click", (event) ->
            $(this).datepicker()
    
$(document).on('turbolinks:load', ready)
