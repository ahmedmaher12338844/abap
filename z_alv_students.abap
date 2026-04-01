*&---------------------------------------------------------------------*
*& Report Z_ALV_STUDENTS
*&---------------------------------------------------------------------*
REPORT z_alv_students.

*=======================================================================
* DECLARE MAIN STRUCTURE
*=======================================================================
TYPES: BEGIN OF ty_alv,
         student_id         TYPE zde_student_id,
         student_name       TYPE zde_student_names,
         class_name         TYPE zde_class_names,
         course_id          TYPE zde_course_ids,
         course_name        TYPE zde_course_names,
         course_duration    TYPE zde_course_duration,
         completed_duration TYPE zde_completed_duration,
         course_salary      TYPE zde_course_salary,
         currency           TYPE waers,
       END OF ty_alv.

*=======================================================================
* DECLARE DATA
*=======================================================================
DATA: gt_alv      TYPE STANDARD TABLE OF ty_alv,
      gs_alv      TYPE ty_alv,
      gt_fieldcat TYPE lvc_t_fcat,
      gs_fieldcat TYPE lvc_s_fcat,
      gs_layout   TYPE lvc_s_layo,
      gt_sort     TYPE lvc_t_sort,
      gs_sort     TYPE lvc_s_sort.

*=======================================================================
* SELECTION SCREEN
*=======================================================================
DATA: lv_course TYPE zde_course_ids,
      lv_class  TYPE zde_class_names,
      lv_stud   TYPE zde_student_id.

PARAMETERS: p_stuid TYPE zde_student_id.

SELECT-OPTIONS: s_course FOR lv_course,
                s_class  FOR lv_class,
                s_stud   FOR lv_stud.

*=======================================================================
* START EXECUTION
*=======================================================================
START-OF-SELECTION.
  PERFORM get_data.
  PERFORM display_alv.

*=======================================================================
* GET DATA
*=======================================================================
FORM get_data.

  CLEAR gt_alv.

  SELECT st~student_id,
         st~student_name,
         cl~class_name,
         co~course_id,
         co~course_name,
         co~course_duration,
         sc~completed_duration,
         co~course_salary,
         co~currency
    FROM zstudent_tabl AS st
    INNER JOIN zclasses_table AS cl
      ON cl~class_id = st~class_id
    INNER JOIN zsc_table AS sc
      ON sc~student_id = st~student_id
    INNER JOIN zcourses_table AS co
      ON co~course_id = sc~course_id
    WHERE ( st~student_id = @p_stuid OR @p_stuid IS INITIAL )
      AND co~course_id IN @s_course
      AND cl~class_name IN @s_class
      AND st~student_id IN @s_stud
    INTO TABLE @gt_alv.

ENDFORM.

*=======================================================================
* FIELD CATALOG
*=======================================================================
FORM build_fieldcat.

  CLEAR gt_fieldcat.

  gs_fieldcat-fieldname = 'STUDENT_NAME'.
  gs_fieldcat-coltext   = 'Student Name'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'CLASS_NAME'.
  gs_fieldcat-coltext   = 'Class'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'COURSE_NAME'.
  gs_fieldcat-coltext   = 'Course'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'COURSE_DURATION'.
  gs_fieldcat-coltext   = 'Duration'.
  gs_fieldcat-do_sum    = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'COMPLETED_DURATION'.
  gs_fieldcat-coltext   = 'Completed'.
  gs_fieldcat-edit      = 'X'.
  gs_fieldcat-do_sum    = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'COURSE_SALARY'.
  gs_fieldcat-coltext   = 'Salary'.
  gs_fieldcat-do_sum    = 'X'.
  gs_fieldcat-currency  = 'CURRENCY'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'STUDENT_ID'.
  gs_fieldcat-no_out    = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

  CLEAR gs_fieldcat.
  gs_fieldcat-fieldname = 'COURSE_ID'.
  gs_fieldcat-no_out    = 'X'.
  APPEND gs_fieldcat TO gt_fieldcat.

ENDFORM.

*=======================================================================
* LAYOUT
*=======================================================================
FORM build_layout.
  gs_layout-zebra      = 'X'.
  gs_layout-cwidth_opt = 'X'.
ENDFORM.

*=======================================================================
* SORT
*=======================================================================
FORM build_sort.
  CLEAR gs_sort.
  gs_sort-fieldname = 'COURSE_NAME'.
  gs_sort-up        = 'X'.
  gs_sort-subtot    = 'X'.
  APPEND gs_sort TO gt_sort.
ENDFORM.

*=======================================================================
* DISPLAY ALV
*=======================================================================
FORM display_alv.

  PERFORM build_fieldcat.
  PERFORM build_layout.
  PERFORM build_sort.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'USER_COMMAND'
      i_callback_pf_status_set = 'SET_PF'
      is_layout_lvc            = gs_layout
      it_fieldcat_lvc          = gt_fieldcat
      it_sort_lvc              = gt_sort
    TABLES
      t_outtab                 = gt_alv.

ENDFORM.

*=======================================================================
* PF STATUS
*=======================================================================
FORM set_pf USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS 'ZSTATUS'.
ENDFORM.

*=======================================================================
* USER COMMAND
*=======================================================================
FORM user_command USING r_ucomm     LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  CASE r_ucomm.

    WHEN 'ADD_ROW'.
      PERFORM popup_add_row.

    WHEN 'DEL_ROW'.
      READ TABLE gt_alv INDEX rs_selfield-tabindex INTO gs_alv.
      IF sy-subrc = 0.

        DELETE FROM zsc_table
          WHERE student_id = gs_alv-student_id
            AND course_id  = gs_alv-course_id.

        COMMIT WORK.

        DELETE gt_alv INDEX rs_selfield-tabindex.

      ENDIF.

    WHEN 'SAVE'.
      PERFORM save_data.
      PERFORM get_data.

  ENDCASE.

  rs_selfield-refresh = 'X'.

ENDFORM.

*=======================================================================
* POPUP
*=======================================================================
FORM popup_add_row.

  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval,
        ls_sc     TYPE zsc_table.

  ls_field-tabname   = 'ZSC_TABLE'.
  ls_field-fieldname = 'STUDENT_ID'.
  APPEND ls_field TO lt_fields.

  CLEAR ls_field.
  ls_field-tabname   = 'ZSC_TABLE'.
  ls_field-fieldname = 'COURSE_ID'.
  APPEND ls_field TO lt_fields.

  CLEAR ls_field.
  ls_field-tabname   = 'ZSC_TABLE'.
  ls_field-fieldname = 'COMPLETED_DURATION'.
  APPEND ls_field TO lt_fields.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING popup_title = 'Add Record'
    TABLES    fields      = lt_fields.

  DATA: lv_stud   TYPE zde_student_id,
        lv_course TYPE zde_course_ids,
        lv_comp   TYPE zde_completed_duration.

  READ TABLE lt_fields INDEX 1 INTO ls_field.
  lv_stud = ls_field-value.

  READ TABLE lt_fields INDEX 2 INTO ls_field.
  lv_course = ls_field-value.

  READ TABLE lt_fields INDEX 3 INTO ls_field.
  lv_comp = ls_field-value.

  IF lv_stud IS INITIAL OR lv_course IS INITIAL.
    MESSAGE 'Enter IDs first' TYPE 'E'.
  ENDIF.

  CLEAR gs_alv.

  SELECT SINGLE student_name
    INTO gs_alv-student_name
    FROM zstudent_tabl
    WHERE student_id = lv_stud.

  IF sy-subrc <> 0.
    MESSAGE 'Invalid Student ID' TYPE 'E'.
  ENDIF.

  SELECT SINGLE course_name course_duration course_salary currency
    INTO (gs_alv-course_name,
          gs_alv-course_duration,
          gs_alv-course_salary,
          gs_alv-currency)
    FROM zcourses_table
    WHERE course_id = lv_course.

  IF sy-subrc <> 0.
    MESSAGE 'Invalid Course ID' TYPE 'E'.
  ENDIF.

  SELECT SINGLE class_name
    INTO gs_alv-class_name
    FROM zclasses_table AS cl
    INNER JOIN zstudent_tabl AS st
      ON cl~class_id = st~class_id
    WHERE st~student_id = lv_stud.

  gs_alv-student_id         = lv_stud.
  gs_alv-course_id          = lv_course.
  gs_alv-completed_duration = lv_comp.

  CLEAR ls_sc.
  ls_sc-student_id         = lv_stud.
  ls_sc-course_id          = lv_course.
  ls_sc-completed_duration = lv_comp.

  INSERT zsc_table FROM ls_sc.

  IF sy-subrc = 0.
    COMMIT WORK.
    APPEND gs_alv TO gt_alv.
  ELSE.
    MESSAGE 'Record already exists!' TYPE 'E'.
  ENDIF.

ENDFORM.

*=======================================================================
* SAVE
*=======================================================================
FORM save_data.

  DATA: ls_sc TYPE zsc_table.

  LOOP AT gt_alv INTO gs_alv.
    CLEAR ls_sc.
    ls_sc-student_id         = gs_alv-student_id.
    ls_sc-course_id          = gs_alv-course_id.
    ls_sc-completed_duration = gs_alv-completed_duration.
    MODIFY zsc_table FROM ls_sc.
  ENDLOOP.

  COMMIT WORK.
  MESSAGE 'Saved successfully' TYPE 'S'.

ENDFORM.
