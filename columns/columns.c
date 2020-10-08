/**
 * @file   columns.c
 * @Author Carlos Carvalho <carloslack@gmail.com>
 *
 * Compile:
 *    $ make
 *
 * Execution help
 *    $ ./columns --help
 *
 * Note: there is a limitation in the number of columns 
 * that can be displayed , see -DMAXCOLUMNS in Makefile - adjust for 
 * your monitor. Mine is a small notebook.
 *
 * Limitations:
 *
 *    The only kind of input file used for developing
 *    this tool was the ones os string type and all
 *    lines terminated by new lines ('\n').
 *
 *    Any other input file format that may
 *    be used may not work as expected.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <errno.h>
#include <termios.h>
#include <unistd.h>

#include "columns.h"

/**
 * @brief simple help function
 *
 * @param [in] exe program executable name
 */
static void help(const char *exe)
{
   printf("Use: %s <inputfile> <page_lines> [<col_width1> <col_width2> ...] <col_widthN>\n", exe);
   exit(0);
}

/**
 * @brief Implementation goes here
 */
#include "impl/columns.i"

/**
 * @brief   Returns static main data 
 *
 * @param [out] statically allocated data
 */
static inline cldata_t *getdata(void)
{
    static cldata_t data;
    static int init = 0;

    if(!init)
    {
        init = 1;
        memset(data.column_width, -1, __MAXCOLUMNS);
    }

    return &data;
}

/**
 * @brief Returns file size.
 *
 * @param [in] fp FILE pointer.
 * @param [out] file size
 */
static size_t
columns_get_file_size(FILE *fp)
{
    assert(fp);
    size_t size;
    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    return size;
}

/**
 * @brief   Displays debug information. 
 *
 * See __DO_DEBUG parameter compilation at Makefile
 *
 */
static void 
debug(void)
{
   cldata_t *cl = getdata();
   int index;
   assert(cl != NULL);

   for(index = 0; index <= cl->buf_index_range; ++index)
     {
        printf("buf[%d].buf: \"%s\"\n", index, cl->buf_st[index].buf);
        printf("buf[%d].bufsiz: %lu\n", index, cl->buf_st[index].bufsiz);
        printf("buf[%d].width: %d\n", index, cl->buf_st[index].width);
        printf("buf[%d].num_tokens: %d\n", index, cl->buf_st[index].num_tokens);
        printf("buf[%d].is_even: %s\n\n",index, cl->buf_st[index].is_even ? "yes" : "no");
     }
}

int main(int argc, char **argv)
{
    cldata_t *data = getdata();
    char *buf = NULL, *line = NULL;
    int buf_index;
    int lines = 0;
    FILE *fp = NULL;
    unsigned int i = 3, pos = 0, advt_num = 0, cols = 0;
    size_t fsize = 0, len = 0;

    argc < 3 ? help(argv[0]) : 0;

    /**
     * To fill the gaps and adjust columns
     */
    memset(outter_space, ' ', __MAXSLOTS);

    /**
     * Number of columns cannot be higher than total allowed 
     * by __MAXCOLUMNS compilation definition.
     * -3: argv[0] progname, argv[1] inputfile, argv[2] page_lines
     */
    argc-i > __MAXCOLUMNS ? help(argv[0]) : 0;

    fp = fopen(argv[1], "r");
    if(NULL == fp)
    {
        printf("%s: %s\n", argv[1], strerror(errno));
        exit(-1);
    }

    // number of lines to be output per page
    data->page_lines = atoi(argv[2]);

    // width per column. number of columns are limited by __MAXCOLUMNS
    cols = columns_load_columns(argv, 3 /* argv index */, cols, data);

    fsize = columns_get_file_size(fp);

    buf_index = 0;
    while(getline(&line, &len, fp) != -1) 
    {
        static int column_index = 0;

        if(column_index == cols)
            column_index = 0;

        columns_pre_setup(buf_index, data->column_width[column_index], line, data);

        ++column_index;
        ++buf_index;

    }

    fclose(fp);

    if(line)
    {
        free(line);
        line = NULL;
    }

#ifdef __DODEBUG
    debug();
#endif
    columns_format_and_display(data);

    cleanup(data);

    return 0;
}

