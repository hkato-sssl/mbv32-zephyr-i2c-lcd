#ifndef LCD_H
#define LCD_H

#ifdef __cplusplus
extern "C" {
#endif

int lcd_init(void);
int lcd_clear(void);
int lcd_putc(int ch);
int lcd_write_string(const char *str);
int lcd_display_cursor(bool fg);

#ifdef __cplusplus
}
#endif

#endif /* LCD_H */
