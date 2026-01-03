#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/i2c.h>

#include <stdint.h>

#define EOS '\0'
#define CR  '\r'
#define LF  '\n'

#define LCD_WIDTH  20
#define LCD_HEIGHT 4

#define SIGNAL_RS 0x01
#define SIGNAL_RW 0x02
#define SIGNAL_E  0x04
#define BACKLIGHT 0x08

#define I2C_TARGET_ADDR 0x27
#define I2C_TARGET_NODE DT_NODELABEL(axi_iic_0)

static const struct device *lcd_i2c_dev = DEVICE_DT_GET(I2C_TARGET_NODE);
static bool lcd_backlight;
static int lcd_x;
static int lcd_y;

static int expander_write(uint8_t data)
{
	int ret;

	ret = i2c_write(lcd_i2c_dev, &data, sizeof(data), I2C_TARGET_ADDR);

	return ret;
}

static int writeb(uint8_t d)
{
	int ret;

	if (lcd_backlight) {
		d |= BACKLIGHT;
	}

	ret = expander_write(d);
	if (ret < 0) {
		return ret;
	}

	d |= SIGNAL_E;
	ret = expander_write(d);
	if (ret < 0) {
		return ret;
	}
	k_usleep(1);

	d ^= SIGNAL_E;
	ret = expander_write(d);
	if (ret == 0) {
		k_usleep(50);
	}

	return ret;
}

static int write_byte(uint8_t d, bool is_command)
{
	int ret;
	uint8_t rs;

	rs = is_command ? 0 : SIGNAL_RS;

	/* Write upper nibble */
	ret = writeb((d & 0xf0) | rs);
	if (ret < 0) {
		return ret;
	}

	/* Write lower nibble */
	ret = writeb((d << 4) | rs);

	return ret;
}

static int write_command(uint8_t cmd)
{
	int ret;

	ret = write_byte(cmd, true);

	return ret;
}

static int write_data(uint8_t data)
{
	int ret;

	ret = write_byte(data, false);

	return ret;
}

int configure_4bit_mode(void)
{
	int ret;

	ret = writeb(0x30);
	if (ret < 0) {
		return ret;
	}
	k_usleep(4500);

	ret = writeb(0x30);
	if (ret < 0) {
		return ret;
	}
	k_usleep(150);

	ret = writeb(0x30);
	if (ret < 0) {
		return ret;
	}

	ret = writeb(0x20);

	return ret;
}

int lcd_init(void)
{
	int ret;

	/* Wait at least 40ms after the power supply exceeds 2.7V */
	k_msleep(50);

	lcd_backlight = true;
	lcd_x = 0;
	lcd_y = 0;

	ret = configure_4bit_mode();
	if (ret < 0) {
		return ret;
	}

	/* Function set */
	ret = write_command(0x28);
	if (ret < 0) {
		return ret;
	}

	/* Display on */
	ret = write_command(0x0e);
	if (ret < 0) {
		return ret;
	}

	/* Display clear */
	ret = write_command(0x01);
	if (ret < 0) {
		return ret;
	}

	/* Entry mode set */
	ret = write_command(0x06);
	if (ret < 0) {
		return ret;
	}

	return ret;
}

int lcd_clear(void)
{
	int ret;

	lcd_x = 0;
	lcd_y = 0;

	/* Clear display */
	ret = write_command(0x01);

	return ret;
}

static int update_cursor_position(void)
{
	static uint8_t offset[] = {0, 0x40, LCD_WIDTH, 0x40 + LCD_WIDTH};

	int ret;
	uint8_t d;

	/* Set DDRAM address */
	d = 0x80 | (offset[lcd_y] + lcd_x);
	ret = write_command(d);

	return ret;
}

int lcd_putc(int ch)
{
	int ret;

	if (ch == CR) {
		lcd_x = 0;
		ret = update_cursor_position();
	} else if (ch == LF) {
		lcd_x = 0;
		++lcd_y;
		if (lcd_y >= LCD_HEIGHT) {
			lcd_y = 0;
		}
		ret = update_cursor_position();
	} else {
		ret = write_data(ch);
		if (ret != 0) {
			return ret;
		}

		++lcd_x;
		if (lcd_x >= LCD_WIDTH) {
			lcd_x = 0;
			++lcd_y;
			if (lcd_y >= LCD_HEIGHT) {
				lcd_y = 0;
			}
			ret = update_cursor_position();
		}
	}

	return ret;
}

int lcd_write_string(const char *str)
{
	int ret = -1;

	for (int i = 0; str[i] != EOS; ++i) {
		ret = lcd_putc(str[i]);
		if (ret < 0) {
			break;
		}
	}

	return ret;
}

int lcd_display_cursor(bool fg)
{
	int ret;
	uint8_t d;

	/* Display on/off control */
	d = fg ? 0x0e : 0x0c;
	ret = write_command(d);

	return ret;
}
