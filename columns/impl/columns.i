/**
 * @file   columns.i
 * @Author Carlos Carvalho <carloslack@gmail.com>
 * @brief  This is the implementation file.
 */

/**
 * @brief Internal helper to
 * to discover the buffer which has
 * highest number of tokens, in this
 * case, new lines.
 *
 * @param [in] num delimiter
 * @param [in] val value to be compared with
 * @param [out] highest number
 */
static int
_columns_get_max(int num, int val)
{
   static int siz = 0;
   static int n = 0;
   int ret;

   if(n == num)
     {
        ret = siz;
        siz = n = 0;
        return ret;
     }

   ++n;

   if(val > siz)
     siz = val;

   return siz;
}

/**
 * @brief Access function to _columns_get_max
 *
 * @param[in] base_index buffer base index
 * @param [in] range range to be searched
 * @param [in] data main data
 * @param [out] Highest number
 */
static int
columns_get_max(int base_index, int range, cldata_t *data)
{
   cldata_t *cl;
   int max = 0;
   int i = 0;
   assert(data != NULL);
   cl = data;

   for(; i <= range; ++i)
     {
        assert(cl->buf_st[base_index+i].buf != NULL);
        max = 
           _columns_get_max(cl->columns, cl->buf_st[base_index+i].num_tokens);
     }
   return max;
}


/**
 * @brief Setup columns information and data
 *
 * @param [in] argv user input list
 * @param [in] index argv base index
 * @param [in] columns to be used as reference for static
 * @param [in] data main data
 * @param [out] number of columns calculated from user input.
 */
static int
columns_load_columns(char **argv, int index, int columns, cldata_t *data)
{
    int idx = index;
    int col = columns;
    int iarg;

    while(argv[idx])
    {
        iarg = (unsigned int)atoi(argv[idx]);
        assert((iarg > 0) && (iarg <= __MAXWIDTH)); // validate arg
        data->column_width[col] = iarg;
        data->columns++;
        ++col;
        ++idx;
    }
    return col;
}

/**
 * @brief Handles keyboard keys for the line pager.
 * POSIX.1-2001.
 */
static char
columns_get_keyboard_input(void)
{
    char c;
    struct termios new_kbd_mode;
    struct termios g_old_kbd_mode;

    /**
     * sets raw mode
     */
    tcgetattr (0, &g_old_kbd_mode);
    memcpy (&new_kbd_mode, &g_old_kbd_mode, sizeof (struct termios));

    new_kbd_mode.c_lflag &= ~(ICANON | ECHO);
    new_kbd_mode.c_cc[VTIME] = 0;
    new_kbd_mode.c_cc[VMIN] = 1;
    tcsetattr(0, TCSANOW, &new_kbd_mode);

    /**
     * we could map ctrl+ip and ctrl+down 
     * to emulate 'less' (linux) command.
     */
    (void)read(0, &c, 1);

    /**
     * restores from raw mode
     */
    tcsetattr(0, TCSANOW, &g_old_kbd_mode);

    return c;
}

/**
 * @brief Prepares the buffer to be parser later on.
 *
 * @param [in] buf_index index of array of strings
 * @param [in] columns_width 
 * @param [in] buf buffer from getline()
 * @param [in] data main data
 *
 */
static void 
columns_pre_setup(int buf_index, int column_width, 
                  const char *buf, cldata_t *data)
{
    size_t ncolumns; 
    size_t buflen;
    static int init = 0;
    cldata_t *cl;

    assert(buf != NULL);
    assert(data != NULL);

    cl = data;

    if(!init)
    {
        init = 1;
        cl->buf_index_range = 0;
    }
    else
        ++(cl->buf_index_range);


    buflen = strlen(buf);

    // set number of columns (token) per line
    if(column_width >= buflen)
        cl->buf_st[buf_index].num_tokens = 1;
    else
    {
        /**
         *
         * By knowing the lenght is even is possible
         * to calculate width.
         */
        if(_ISEVEN(buflen))
        {
            cl->buf_st[buf_index].num_tokens = buflen / column_width;
        }
        else
        {
            cl->buf_st[buf_index].num_tokens = (buflen / column_width) + 1;
        }
    }

    cl->buf_st[buf_index].bufsiz = buflen;
    _CALLOC(cl->buf_st[buf_index].buf, 1, cl->buf_st[buf_index].bufsiz + 1);

    /*
     * here we make sure we skip the last '\n' 
     * and then the buffer is copied
     */
    memcpy(cl->buf_st[buf_index].buf, buf, cl->buf_st[buf_index].bufsiz - 1);

    cl->buf_st[buf_index].width = column_width;
}


/**
 * @brief This is where things happen, some more 
 * formatting takes place then the output is printed to 
 * console.
 *
 * @param [in] data main data
 *
 */
static void
columns_format_and_display(cldata_t *data)
{
    cldata_t *cl;
    int index = 0, page = 0, col = 0, line = 0;
    assert(data != NULL);

    cl = data;

    /**
     * Saves ptr addresses for later 
     * cleanup.
     */
    for(index=0; index <= cl->buf_index_range; ++index)
        cl->buf_st[index].o_buf = cl->buf_st[index].buf;

    /**
     * @bug The very last line of inputfile
     * is not being displayed.
     * Fix is quite close because '|' are displayed is the hidden
     * collumns is longer than the one is seen.
     *
     * TODO/FIXME: make it display the last line of
     * input file.
     *
     */
    for(index=0; index < cl->buf_index_range; )
    {
        int m; 
        for(col=0; col < cl->columns; ++col)
        {
            /**
             * The following formula 
             * help us to know the exact range to traverse.
             */
            int range = 
                ((index+cl->columns) < data->buf_index_range) ? 
                cl->columns : data->buf_index_range - index;

            int max = columns_get_max(index, range, cl);
            char *tok;

            for(m=0; m <= max; ++m)
            {
                int x;
                for(x=0; x < range; ++x)
                {
                    char *s = NULL;
                    size_t len = strlen(cl->buf_st[index+x].buf);

                    /**
                     * Make sure remaining bytes, the ones
                     * exeeding the width, are shown.
                     */
                    if(len <= cl->buf_st[index+x].width)
                    {
                        int diff = cl->buf_st[index+x].width - len;
                        _CALLOC(s, 1, len+diff+1);
                        strncpy(s, &cl->buf_st[index+x].buf[0] , len);
                        strncat(s, outter_space, diff); 
                        printf(" %s | ",s);
                        cl->buf_st[index+x].buf += len;
                        free(s); s=NULL;
                    } 

                    /**
                     * Main displayer.
                     */
                    else
                    {
                        _CALLOC(s, 1, cl->buf_st[index+x].width+1);
                        strncpy(s, &cl->buf_st[index+x].buf[0], cl->buf_st[index+x].width);
                        printf(" %s | ",s);
                        cl->buf_st[index+x].buf += cl->buf_st[index+x].width;
                        free(s); s=NULL;
                    }
                }
                puts("");

                /**
                 * This is for paging.
                 */
                if(line == cl->page_lines)
                {
                    line = 0;
                    columns_get_keyboard_input();
                }
                else
                    ++line;
            }
            index += range;
            puts("");
        }
    }
}

/**
 * @brief cleanup allocated data
 *
 * @param [in] data main data
 */
static void 
cleanup(cldata_t *data)
{
    cldata_t *cl;
    int index;

    assert(data != NULL);

    cl = data;

    /**
     * Here I use previously saved
     * ptr addresses to properly locate original 
     * entry points so we can free the memory.
     *
     * Note that I shift original pointers 
     * at columns_format_and_display()
     */
    for(index = 0; index <= cl->buf_index_range; ++index) {
        free(cl->buf_st[index].o_buf);

        //make both point to NULL, just in case
        cl->buf_st[index].o_buf = NULL;
        cl->buf_st[index].buf = NULL;
    }
}

