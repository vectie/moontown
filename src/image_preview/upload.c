#include <moonbit.h>
#include <png.h>
#include <stdio.h>
#include <jpeglib.h>
#include <webp/decode.h>
#include <setjmp.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define INPUT_LIMIT (8u * 1024u * 1024u)
#define EDGE_LIMIT 2048u

static int bounds(unsigned w, unsigned h) {
  return w > 0 && h > 0 && w <= EDGE_LIMIT && h <= EDGE_LIMIT;
}

static uint32_t big32(const unsigned char *p) {
  return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
         ((uint32_t)p[2] << 8) | p[3];
}

/* Reject appended payloads and animation before libpng decodes any pixels. */
static int png_container(const unsigned char *p, size_t n) {
  if (n < 32 || memcmp(p, "\x89PNG\r\n\x1a\n", 8)) return 0;
  size_t at = 8;
  while (at + 12 <= n) {
    uint32_t size = big32(p + at);
    if (size > n - at - 12) return 0;
    if (!memcmp(p + at + 4, "acTL", 4)) return 0;
    int end = !memcmp(p + at + 4, "IEND", 4);
    at += (size_t)size + 12;
    if (end) return size == 0 && at == n;
  }
  return 0;
}

struct jpeg_failure { struct jpeg_error_mgr base; jmp_buf jump; };
struct jpeg_state {
  struct jpeg_decompress_struct decoder;
  struct jpeg_failure failure;
  unsigned char *rgba;
  unsigned char *row;
  int created;
};
static void jpeg_fail(j_common_ptr info) {
  struct jpeg_failure *failure = (struct jpeg_failure *)info->err;
  longjmp(failure->jump, 1);
}
static void jpeg_silent(j_common_ptr info) { (void)info; }
static unsigned char *decode_jpeg(const unsigned char *p, size_t n,
                                  unsigned *w, unsigned *h) {
  struct jpeg_state *s = calloc(1, sizeof(*s));
  if (!s) return NULL;
  s->decoder.err = jpeg_std_error(&s->failure.base);
  s->failure.base.error_exit = jpeg_fail;
  s->failure.base.output_message = jpeg_silent;
  if (setjmp(s->failure.jump)) goto invalid;
  jpeg_create_decompress(&s->decoder);
  s->created = 1;
  jpeg_mem_src(&s->decoder, p, (unsigned long)n);
  if (jpeg_read_header(&s->decoder, TRUE) != JPEG_HEADER_OK ||
      !bounds(s->decoder.image_width, s->decoder.image_height)) goto invalid;
  s->decoder.out_color_space = JCS_RGB;
  if (!jpeg_start_decompress(&s->decoder) || s->decoder.output_components != 3)
    goto invalid;
  *w = s->decoder.output_width; *h = s->decoder.output_height;
  s->rgba = malloc((size_t)*w * *h * 4);
  s->row = malloc((size_t)*w * 3);
  if (!s->rgba || !s->row) goto invalid;
  while (s->decoder.output_scanline < *h) {
    unsigned y = s->decoder.output_scanline;
    JSAMPROW row = s->row;
    if (jpeg_read_scanlines(&s->decoder, &row, 1) != 1) goto invalid;
    for (unsigned x = 0; x < *w; ++x) {
      size_t i = ((size_t)y * *w + x) * 4;
      memcpy(s->rgba + i, s->row + x * 3, 3); s->rgba[i + 3] = 255;
    }
  }
  if (!jpeg_finish_decompress(&s->decoder)) goto invalid;
  unsigned char *pixels = s->rgba;
  jpeg_destroy_decompress(&s->decoder); free(s->row); free(s);
  return pixels;
invalid:
  if (s->created) jpeg_destroy_decompress(&s->decoder);
  free(s->rgba); free(s->row); free(s); return NULL;
}

/* Only newly encoded pixel data survives. No original name, EXIF, text, script,
   ICC profile, animation, application segment or trailing byte is published. */
MOONBIT_FFI_EXPORT moonbit_bytes_t
moontown_sanitize_upload(moonbit_bytes_t input, int32_t kind) {
  size_t n = (size_t)Moonbit_array_length(input);
  unsigned char *rgba = NULL;
  unsigned w = 0, h = 0;
  moonbit_bytes_t result = NULL;
  png_image image;
  memset(&image, 0, sizeof(image)); image.version = PNG_IMAGE_VERSION;
  if (n < 32 || n > INPUT_LIMIT) goto done;
  if (kind == 1) {
    if (!png_container(input, n) ||
        !png_image_begin_read_from_memory(&image, input, n)) goto done;
    w = image.width; h = image.height;
    if (!bounds(w, h)) goto done;
    image.format = PNG_FORMAT_RGBA;
    rgba = malloc(PNG_IMAGE_SIZE(image));
    if (!rgba || !png_image_finish_read(&image, NULL, rgba, 0, NULL)) goto done;
    png_image_free(&image);
  } else if (kind == 2) {
    if (input[0] != 0xff || input[1] != 0xd8 ||
        input[n - 2] != 0xff || input[n - 1] != 0xd9) goto done;
    rgba = decode_jpeg(input, n, &w, &h);
    if (!rgba) goto done;
  } else if (kind == 3) {
    WebPBitstreamFeatures features;
    if (memcmp(input, "RIFF", 4) || memcmp(input + 8, "WEBP", 4)) goto done;
    uint32_t total = (uint32_t)input[4] | ((uint32_t)input[5] << 8) |
                     ((uint32_t)input[6] << 16) | ((uint32_t)input[7] << 24);
    if ((uint64_t)total + 8 != n || WebPGetFeatures(input, n, &features) != VP8_STATUS_OK ||
        features.has_animation || !bounds(features.width, features.height)) goto done;
    w = features.width; h = features.height;
    rgba = malloc((size_t)w * h * 4);
    if (!rgba || !WebPDecodeRGBAInto(input, n, rgba, (size_t)w * h * 4, w * 4)) goto done;
  } else goto done;
  memset(&image, 0, sizeof(image)); image.version = PNG_IMAGE_VERSION;
  image.width = w; image.height = h; image.format = PNG_FORMAT_RGBA;
  png_alloc_size_t length = 0;
  if (!png_image_write_to_memory(&image, NULL, &length, 0, rgba, 0, NULL) ||
      length == 0 || length > 12582912) goto done;
  result = moonbit_make_bytes((int32_t)length, 0);
  if (!png_image_write_to_memory(&image, result, &length, 0, rgba, 0, NULL)) {
    moonbit_decref(result); result = NULL;
  }
done:
  free(rgba); png_image_free(&image);
  return result ? result : moonbit_make_bytes(0, 0);
}
