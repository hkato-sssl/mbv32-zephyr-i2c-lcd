#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/i2c.h>
#include <zephyr/shell/shell.h>

#include <stdlib.h>

#include "lcd_drv.h"

static int cmd_lcd_init(const struct shell *sh, size_t argc, char **argv)
{
	return lcd_init();
}

static int cmd_lcd_str(const struct shell *sh, size_t argc, char **argv)
{
	if (argc < 3) {
		return -1;
	}

	return lcd_write_string(argv[2]);
}

static int cmd_lcd_clear(const struct shell *sh, size_t argc, char **argv)
{
	return lcd_clear();
}

static int cmd_lcd_cr(const struct shell *sh, size_t argc, char **argv)
{
	return lcd_putc('\r');
}

static int cmd_lcd_lf(const struct shell *sh, size_t argc, char **argv)
{
	return lcd_putc('\n');
}

static int cmd_lcd_cursor(const struct shell *sh, size_t argc, char **argv)
{
	int ret;

	if (argc < 3) {
		ret = -1;
	} else if (strcmp(argv[2], "on") == 0) {
		ret = lcd_display_cursor(true);
	} else if (strcmp(argv[2], "off") == 0) {
		ret = lcd_display_cursor(false);
	} else {
		ret = -1;
	}

	return ret;
}

static int cmd_lcd(const struct shell *sh, size_t argc, char **argv)
{
	static struct {
		const char *name;
		int (*func)(const struct shell *sh, size_t argc, char **argv);
	} commands[] = {
		{"init", cmd_lcd_init},
		{"str", cmd_lcd_str},
		{"clear", cmd_lcd_clear},
		{"cr", cmd_lcd_cr},
		{"lf", cmd_lcd_lf},
		{"cursor", cmd_lcd_cursor},
		{NULL, NULL} /* terminator */
	};

	int ret;
	int i;

	if (argc < 2) {
		return -1;
	}

	for (i = 0; commands[i].name != NULL; ++i) {
		if (strcmp(argv[1], commands[i].name) == 0) {
			break;
		}
	}

	if (commands[i].func != NULL) {
		ret = (commands[i].func)(sh, argc, argv);
	} else {
		ret = -1;
	}

	return ret;
}

SHELL_CMD_REGISTER(lcd, NULL, "LCD commands", cmd_lcd);
