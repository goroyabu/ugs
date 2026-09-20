#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

enum {
  WINDOW_WIDTH = 320,
  WINDOW_HEIGHT = 240,
  MAP_TIMEOUT_MILLISECONDS = 5000,
  MAP_POLL_MILLISECONDS = 10
};

static int parse_capture_path(int argc, char **argv, const char **capture_path) {
  *capture_path = NULL;

  if (argc == 1) {
    return 1;
  }
  if (argc == 3 && strcmp(argv[1], "--capture") == 0) {
    *capture_path = argv[2];
    return 1;
  }

  fprintf(stderr, "usage: %s [--capture output.ppm]\n", argv[0]);
  return 0;
}

static int wait_until_viewable(Display *display, Window window) {
  int elapsed = 0;

  while (elapsed < MAP_TIMEOUT_MILLISECONDS) {
    XWindowAttributes attributes;

    XSync(display, False);
    if (XGetWindowAttributes(display, window, &attributes) != 0 &&
        attributes.map_state == IsViewable) {
      return 1;
    }

    usleep(MAP_POLL_MILLISECONDS * 1000);
    elapsed += MAP_POLL_MILLISECONDS;
  }

  return 0;
}

static void draw_reference_frame(Display *display, Window window, GC gc,
                                 unsigned long black, unsigned long white) {
  int row;
  int column;

  XSetForeground(display, gc, white);
  XFillRectangle(display, window, gc, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

  XSetForeground(display, gc, black);
  XSetLineAttributes(display, gc, 4, LineSolid, CapButt, JoinMiter);
  XDrawRectangle(display, window, gc, 18, 18, WINDOW_WIDTH - 40,
                 WINDOW_HEIGHT - 40);
  XDrawLine(display, window, gc, 20, 20, WINDOW_WIDTH - 21,
            WINDOW_HEIGHT - 21);
  XDrawLine(display, window, gc, WINDOW_WIDTH - 21, 20, 20,
            WINDOW_HEIGHT - 21);

  for (row = 0; row < 3; ++row) {
    for (column = 0; column < 5; ++column) {
      if ((row + column) % 2 == 0) {
        XFillRectangle(display, window, gc, 85 + column * 30,
                       75 + row * 30, 30, 30);
      }
    }
  }

  XSync(display, False);
}

static unsigned int channel_from_mask(unsigned long pixel, unsigned long mask) {
  unsigned long value;
  unsigned long maximum;

  if (mask == 0) {
    return 0;
  }

  value = pixel & mask;
  while ((mask & 1UL) == 0) {
    mask >>= 1;
    value >>= 1;
  }
  maximum = mask;

  return (unsigned int)((value * 255UL + maximum / 2UL) / maximum);
}

static int write_capture(Display *display, Window window, const char *path) {
  XImage *image;
  FILE *output;
  int x;
  int y;
  int ok = 1;

  image = XGetImage(display, window, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT,
                    AllPlanes, ZPixmap);
  if (image == NULL) {
    fprintf(stderr, "[xwtest-smoke] failed to capture the window\n");
    return 0;
  }

  output = fopen(path, "wb");
  if (output == NULL) {
    fprintf(stderr, "[xwtest-smoke] failed to open capture output: %s\n", path);
    XDestroyImage(image);
    return 0;
  }

  if (fprintf(output, "P6\n%d %d\n255\n", WINDOW_WIDTH, WINDOW_HEIGHT) < 0) {
    ok = 0;
  }

  for (y = 0; ok && y < WINDOW_HEIGHT; ++y) {
    for (x = 0; x < WINDOW_WIDTH; ++x) {
      unsigned long pixel = XGetPixel(image, x, y);
      unsigned char rgb[3];

      rgb[0] = (unsigned char)channel_from_mask(pixel, image->red_mask);
      rgb[1] = (unsigned char)channel_from_mask(pixel, image->green_mask);
      rgb[2] = (unsigned char)channel_from_mask(pixel, image->blue_mask);
      if (fwrite(rgb, sizeof(rgb), 1, output) != 1) {
        ok = 0;
        break;
      }
    }
  }

  if (fclose(output) != 0) {
    ok = 0;
  }
  XDestroyImage(image);

  if (!ok) {
    fprintf(stderr, "[xwtest-smoke] failed to write capture output: %s\n", path);
  }
  return ok;
}

int main(int argc, char **argv) {
  const char *capture_path;
  Display *display;
  int screen;
  Window root;
  Window window;
  GC gc;
  unsigned long black;
  unsigned long white;
  int status = EXIT_SUCCESS;

  if (!parse_capture_path(argc, argv, &capture_path)) {
    return EXIT_FAILURE;
  }

  display = XOpenDisplay(NULL);
  if (display == NULL) {
    fprintf(stderr, "[xwtest-smoke] unable to open the X display\n");
    return EXIT_FAILURE;
  }

  screen = DefaultScreen(display);
  root = RootWindow(display, screen);
  black = BlackPixel(display, screen);
  white = WhitePixel(display, screen);
  window = XCreateSimpleWindow(display, root, 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT,
                               0, black, white);
  XStoreName(display, window, "UGS X11 smoke harness");
  XSelectInput(display, window, StructureNotifyMask);
  XMapWindow(display, window);

  if (!wait_until_viewable(display, window)) {
    fprintf(stderr, "[xwtest-smoke] window did not become viewable\n");
    XDestroyWindow(display, window);
    XCloseDisplay(display);
    return EXIT_FAILURE;
  }

  printf("[xwtest-smoke] window is viewable\n");
  fflush(stdout);

  gc = XCreateGC(display, window, 0, NULL);
  draw_reference_frame(display, window, gc, black, white);
  if (capture_path != NULL && !write_capture(display, window, capture_path)) {
    status = EXIT_FAILURE;
  }

  XFreeGC(display, gc);
  XDestroyWindow(display, window);
  XCloseDisplay(display);
  return status;
}
