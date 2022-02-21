# test program for DctmAPI.awk and the interface dctm.c;
# Cesare Cervini
# dbi-services.com
# 5/2018
# Revisited 11/2021;
# Final 2/2022;
 
@include "DctmAPI.awk"
 
BEGIN {
   dmLogLevel = 1
 
   # keywords used to specify color in calls to simple_show_table() and show_table();
   # use uppercase variants for bright colors, lowercase ones for dim/normal colors;
   # syntax: fg_color[.bg_color], e.g. RED.YELLOW, white, -blue.black;
   # reset means no extra-colors, same as in current terminal;
   # missing or incorrect color defaults to black;
   # call test_colors() to check how they look on the terminal;
   COLORS = "black, red, green, yellow, blue, magenta, cyan, white, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset"

   # initialize the color arrays FG_COLORS and BG_COLORS with the color ANSI code sequences;
   #test_colors_8bits()
   init_colors(FG_COLORS, BG_COLORS)
   #test_colors()
   test_colors_compact()

   # grid_types;
   grid_types_str = "light light-double-dash light-triple-dash light-quadruple-dash heavy heavy-double-dash heavy-triple-dash heavy-quadruple-dash double hdouble-vsingle hsingle-vdouble light-with-round-corners ascii no-grid hheavy-vlight hlight-vheavy half-light"
   nb_grid_types = split(grid_types_str, grid_types, " ")
   test_grid(g, 3, "3,6,10,4")

   session = dmConnect("dmtest", "dmadmin" , "dmadmin")
   printf("dmConnect: session=%s\n", session)
   if (!session) {
      print("no session opened, exiting ...")
      exit(1)
   }
 
   printf "\n"
   dump = dmAPIGet("dump," session ",0900c35080008107")
   print("object 0900c35080008107 dumped:\n" dump)
 
   printf "\n"
   stmt = "update dm_document object set language_code = 'FR' where r_object_id = '0900c35080008107'"
   status = dmExecute(session, stmt)
   if (status)
      print("dmExecute [" stmt "] was successful")
   else
      print("dmExecute [" stmt "] was not successful")
 
   printf "\n"
   stmt = "select r_object_id, object_name, authors, r_version_label, keywords, i_folder_id, owner_name, acl_domain, acl_name, r_version_label as version_label, i_folder_id as folder_id from dm_document enable(return_top 100)"
   #stmt = "select r_object_id, object_name, owner_name, r_version_label, acl_domain, acl_name from dm_document enable(return_top 100)"
   status = dmSelecto(session, stmt)
   if (status >= 0)
      print("dmSelecto [" stmt "] was successful")
   else
      print("dmSelecto [" stmt "] was not successful")
 
   printf "\n"
   status = dmSelecta(session, stmt, result)
   if (status >= 0) {
      print("dmSelecta [" stmt "] was successful")

      simple_show_table("test selecta in simple_show_table", result)
      simple_show_table("test selecta in simple_show_table", result, "yellow.black")
      simple_show_table("test selecta in simple_show_table", result, "YELLOW.black", "1.0")
      simple_show_table("test selecta in simple_show_table", result, "yellow.red", "3.3",    "no-grid")
      simple_show_table("test selecta in simple_show_table", result, "YELLOW.RED", "3.3",    "no-grid")
      simple_show_table("test selecta in simple_show_table", result, "blue.green", "2.5",    "no-grid")
      simple_show_table("test selecta in simple_show_table", result, "green.blue", "2.5",    "no-grid")
      simple_show_table("test selecta in simple_show_table", result, "cyan.black", "2.-4")
      simple_show_table("test selecta in simple_show_table", result, "cyan.white", "2.-4")
      simple_show_table("test selecta in simple_show_table", result, "cyan.white", "0.0")
      simple_show_table("test selecta in simple_show_table", result, "white.magenta", "1")
      simple_show_table("test selecta in simple_show_table", result, "white.magenta")

      simple_show_table("test selecta in simple_show_table", result, "yellow.red", "3.3",    "ascii")
      simple_show_table("test selecta in simple_show_table", result, "YELLOW.reset", "2.5",  "light")
      simple_show_table("test selecta in simple_show_table", result, "white.black", "2.5",  "double")
      simple_show_table("test selecta in simple_show_table", result, "YELLOW.RED", "2.-5",  "light-quadruple-dash")

      for (i = 1; i <= nb_grid_types; i++)
         simple_show_table("test selecta in simple_show_table", result, "yellow.reset", "1.3", grid_types[i])
      simple_show_table("test selecta in simple_show_table", result, "white.black", "2.5",   "double")
      simple_show_table("test selecta in simple_show_table", result, "black.white", "2.5",   "double")
      simple_show_table("test selecta in simple_show_table", result, "white.black", "5.2",   "double")
      simple_show_table("test selecta in simple_show_table", result, "black.white", "5.2",   "double")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "2.3",    "no-grid")
      simple_show_table("test selecta in simple_show_table", result, "YELLOW.reset", "2.-5", "light")
      simple_show_table("test selecta in simple_show_table", result, "white.black", "-2.5",  "double")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5",  "hdouble-vsingle")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5",  "hsingle-vdouble")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5",  "light-quadruple-dash")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5",  "heavy-quadruple-dash")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5",  "ascii")
      simple_show_table("test selecta in simple_show_table", result, "RED.YELLOW", "-2.-5")

      printf "\n"
      # test show_table() defined as below:
      #    show_table(title, object, maxw, display_width, requested_max_widths_str, wrap_str, truncate_str, ellipsis)
      # maxw > 0, i.e. same width for all the columns, with wrap-around or truncation;
      # maxw = 0, display_width > 0: maxw will be set to max(default_min_col, int(display_width/length(result["metadata"]["nb_cols"])))
      # maxw = 0, display_width = 0: $COLUMNS is taken as display_width, same as above; if not set, maxw is set to default_min_col;
      # when display_width is used, available space is allocated to columns as needed; e.g., if a column is empty in all the result set, it will receive no additional space; the idea is to minimize wrapping;
      # maxw = -1: requested_max_widths_str is used if not empty; missing values defaults to their respective value object["medatada"]["max_col_length"][0...];
      # maxw = -1, empty requested_max_widths_str: max column width defaults to object["medatada"]["max_col_length"][0...], i.e. the widest data of the respective column;
      # when object["medatada"]["max_col_length"][0...] is used, obviously no truncation nor wrap around take place as the respective column widths are large enough for all their data, particularly for their largest datum;
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "green.black", "2.3", "ascii")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "CYAN.black", "2.-3", "no-grid")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "CYAN.black", "2.3", "no-grid")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "white.black", "-2.3", "light")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.YELLOW", "-2.-3", "double")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.reset", "2.3", "heavy")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "GREEN.black", "2.3", "light-quadruple-dash")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, 20, 0, "", "", "", "", "GREEN.black", "2.5", "double")
      show_table("test selecta in show_table (use current screen width, wrap if needed, ultra-minimal parameters)", result)
      show_table("test selecta in show_table (use current screen width, wrap if needed, minimal parameters)", result, 0)
      show_table("test selecta in show_table (use current screen width, wrap if needed, minimal parameters)", result, 0)
      show_table("test selecta in show_table (use fixed column width of 10 characters)", result, 10, 0, "", "", "", "")
      show_table("test selecta in show_table (use screen width=100, wrap if needed)", result, 0, 100, "", "", "", "")
      show_table("test selecta in show_table (use screen width=50, wrap if needed)", result, 0, 50, "", "", "", "")
      show_table("test selecta in show_table (use current screen width, wrap if needed)", result, 0, 0, "", "", "", "")
      show_table("test selecta in show_table (use current screen width, wrap if needed)", result, 0, 0, "", "", "", "", "blue.reset", "1.-2", 2)
      show_table("test selecta in show_table (use given column widths, wrap or truncate as specified)", result, -1, 0, "10,20,,6,12,8,11,20,15,15,,", "1,0,1,0,,,,,0", ",1,,1,,,,,1", "...")
      show_table("test selecta in show_table (use given column widths, wrap or truncate as specified)", result, -1, 0, "10,20,,6,12,8,11,20,15,15,", "1,0,1,0,,,,,0", ",1,,1,,,,,1", "...", "green.blue", "1.1", "ascii")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1)
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation)", result, -1, 0, "", "", "", "")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.YELLOW", "2.3")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.YELLOW", "2.-3", "light-quadruple-dash")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.YELLOW", "-2.3", "hheavy-vlight")
      show_table("test selecta in show_table (use unlimited screen width, no wrapping around/no truncation, minimal parameters)", result, -1, 0, "", "", "", "", "RED.YELLOW", "-2.-3", "light-with-round-corners")
   }
   else
      print("dmSelecta [" stmt "] was not successful")
 
   printf "\n"
   stmt = "select count(*) from dm_document"
   status = dmSelecto(session, stmt)
   if (status)
      print("dmSelect [" stmt "] was successful")
   else
      print("dmSelect [" stmt "] was not successful")
 
   printf "\n"
   status = dmSelecta(session, stmt, result)
   if (status >= 0) {
      print("dmSelecta [" stmt "] was successful")
      #show_table("test selecta", result, 0, 0, "", "", "", "")
      show_table("test selecta in show_table", result, -1, 50, "", "", "", "")
   }
   else
      print("dmSelecta [" stmt "] was not successful")
 
   printf "\n"
   status = dmDisconnect(session)
   if (status)
      print("successfully disconnected")
   else
      print("error while  disconnecting")
 
   printf "\n"
   status = dmAPIDeInit()
   if (status)
      print("successfully deInited")
   else
      print("error while  deInited")
 
   exit(0)
}

# print a grid of all the fg.bg color combinations;
# usesful to check the color renditions in the terminal;
# quality of rendition is quite approximative sometimes;
function test_colors(    fg_colors_str, fg_nb_colors, bg_colors_str, bg_nb_colors, i, j) {
   print FG_COLORS["reset_all"] "testing color rendition"
   fg_colors_str = "black, red, green, yellow, blue, magenta, cyan, white, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset_fg"
   bg_colors_str = "black, red, green, yellow, blue, magenta, cyan, white, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset_bg"
   fg_nb_colors = split(fg_colors_str, fg_color_tab, ", ")
   bg_nb_colors = split(bg_colors_str, bg_color_tab, ", ")
   for (i = 1; i <= bg_nb_colors; i++) {
      for (j = 1; j <= fg_nb_colors; j++)
         printf("%20s: %s%s%s%s\n", fg_color_tab[j] "/" bg_color_tab[i], BG_COLORS[bg_color_tab[i]], FG_COLORS[fg_color_tab[j]], "the quick brown fox jumped over the lazy dog", FG_COLORS["reset_fg"])
      printf("%s%s\n\n", "This is an empty line in reset foreground and background", cleol)
   }
}

# more compact presentation with nb_tests_per_line tests;
function test_colors_compact(    nb_tests_per_line, nb_tests, fg_colors_str, fg_nb_colors, bg_colors_str, bg_nb_colors, i, j) {
   fg_colors_str = "black, red, green, yellow, blue, magenta, cyan, white, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset_fg"
   bg_colors_str = "black, red, green, yellow, blue, magenta, cyan, white, BLACK, RED, GREEN, YELLOW, BLUE, MAGENTA, CYAN, WHITE, reset_bg"
   fg_nb_colors = split(fg_colors_str, fg_color_tab, ", ")
   bg_nb_colors = split(bg_colors_str, bg_color_tab, ", ")
   nb_tests_per_line = 6
   for (i = 1; i <= bg_nb_colors; i++) {
      nb_tests = 0
      for (j = 1; j <= fg_nb_colors; j++) {
         printf("%s%20s: %s%s%s%s%s", nb_tests > 0 ? "   " : "", fg_color_tab[j] "/" bg_color_tab[i], BG_COLORS[bg_color_tab[i]], FG_COLORS[fg_color_tab[j]], "the quick brown fox jumped over the lazy dog", FG_COLORS["reset"], BG_COLORS["reset"])
         nb_tests++
         if (nb_tests == nb_tests_per_line) {
            printf "\n"
            nb_tests = 0
         }
      } 
      printf "\n"
      printf "\n"
   }
}

# test 8-bit colors if available in the terminal emulator;
# see https://en.wikipedia.org/wiki/ANSI_escape_code;
function test_colors_8bits(   esc, i, j) {
   esc = 0x1b
   # background;
   for (i = 0; i <= 255; i++) {
      # foreground;
      #for (j = 0; j <= 231; j++)
      for (j = 0; j <= 255; j++)
         printf("%s%c[48;5;%dm%c[38;5;%dm%03d/%03d", j > 0 ? " " : "", esc, i, esc, j, j, i)
      printf "\n"
   }
}

# Display all the supported grid with the given sizing;
# if widths_str is not empty and nb_cols is not null, a grid for each supported grid type is actually displayed with the cell dimensions from the comma-delimited strings widths_str and heights_str with positional values, which is helpful for testing and chosing a grid style;
# e.g. call:
#    test_grid(g, 3, "3,6,10,4")
function test_grid(g, nb_lines, widths_str     , nb_widths, widths, grid_type) {
   if (!widths_str || !nb_lines)
      return

   init_grid_symbols(g)

   # test section here;
   nb_widths =  split(widths_str, widths, ",")

   # prepare the lines;
   for (grid_type in g) {
      print "grid style:", grid_type
      if ("no-grid" == grid_type)
         continue
      top_grid_line =    sprintf("%0c", g[grid_type]["ltc"])
      middle_grid_line = sprintf("%0c", g[grid_type]["lt"])
      bottom_grid_line = sprintf("%0c", g[grid_type]["lbc"])
      content_line     = g[grid_type]["ver_line"]
      for (i = 1; i <= nb_widths; i++) {
         top_grid_line    = top_grid_line    repeat_str(g[grid_type]["hor_line"], widths[i])
         middle_grid_line = middle_grid_line repeat_str(g[grid_type]["hor_line"], widths[i])
         bottom_grid_line = bottom_grid_line repeat_str(g[grid_type]["hor_line"], widths[i])
         content_line     = content_line     repeat_str(" ", widths[i])

         top_grid_line    = top_grid_line    (i < nb_widths ? sprintf("%0c", g[grid_type]["tt"]) : "")
         middle_grid_line = middle_grid_line (i < nb_widths ? sprintf("%0c", g[grid_type]["x"])  : "")
         bottom_grid_line = bottom_grid_line (i < nb_widths ? sprintf("%0c", g[grid_type]["bt"]) : "")
         content_line     = content_line     (i < nb_widths ? g[grid_type]["ver_line"] : "")
      }
      top_grid_line    = top_grid_line    sprintf("%0c", g[grid_type]["rtc"])
      middle_grid_line = middle_grid_line sprintf("%0c", g[grid_type]["rt"])
      bottom_grid_line = bottom_grid_line sprintf("%0c", g[grid_type]["rbc"])
      content_line     = content_line     g[grid_type]["ver_line"]

      # print the grid now that its components are ready;
      print top_grid_line
      for (i = 0; i < nb_lines; i++) {
         print content_line
         if (i < nb_lines - 1)
            print middle_grid_line
      }
      print bottom_grid_line
      printf "\n"
   } 
}
