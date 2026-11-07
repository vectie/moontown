#include <moonbit.h>
#include <png.h>
#include <webp/encode.h>
#include <webp/decode.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Decode only bounded PNGs produced by the trusted image worker. This function
// performs no file, network or GPU work and copies no PNG metadata into WebP.
MOONBIT_FFI_EXPORT moonbit_bytes_t
moontown_preview_webp(moonbit_bytes_t input, int32_t edge) {
  png_image image;
  WebPPicture picture;
  WebPConfig config;
  WebPMemoryWriter writer;
  unsigned char *rgba = NULL;
  int picture_ready = 0;
  int writer_ready = 0;
  moonbit_bytes_t result = NULL;
  size_t length = (size_t)Moonbit_array_length(input);
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;
  if (length < 32 || length > 12582912 || (edge != 384 && edge != 768))
    goto done;
  if (!png_image_begin_read_from_memory(&image, input, length)) goto done;
  if (image.width == 0 || image.height == 0 ||
      image.width > 2048 || image.height > 2048) goto done;
  image.format = PNG_FORMAT_RGBA;
  rgba = malloc(PNG_IMAGE_SIZE(image));
  if (!rgba || !png_image_finish_read(&image, NULL, rgba, 0, NULL)) goto done;
  if (!WebPPictureInit(&picture)) goto done;
  picture_ready = 1;
  picture.use_argb = 1;
  picture.width = (int)image.width;
  picture.height = (int)image.height;
  if (!WebPPictureImportRGBA(&picture, rgba, picture.width * 4)) goto done;
  int longest = picture.width > picture.height ? picture.width : picture.height;
  if (longest > edge) {
    int width = (picture.width * edge + longest / 2) / longest;
    int height = (picture.height * edge + longest / 2) / longest;
    if (width < 1) width = 1;
    if (height < 1) height = 1;
    if (!WebPPictureRescale(&picture, width, height)) goto done;
  }
  if (!WebPConfigInit(&config)) goto done;
  config.quality = 82;
  config.method = 4;
  config.thread_level = 0;
  config.low_memory = 1;
  WebPMemoryWriterInit(&writer);
  writer_ready = 1;
  picture.writer = WebPMemoryWrite;
  picture.custom_ptr = &writer;
  if (!WebPValidateConfig(&config) || !WebPEncode(&config, &picture) ||
      writer.size == 0 || writer.size > 1048576) goto done;
  result = moonbit_make_bytes((int32_t)writer.size, 0);
  memcpy(result, writer.mem, writer.size);
done:
  if (writer_ready) WebPMemoryWriterClear(&writer);
  if (picture_ready) WebPPictureFree(&picture);
  free(rgba);
  png_image_free(&image);
  return result ? result : moonbit_make_bytes(0, 0);
}

MOONBIT_FFI_EXPORT uint64_t
moontown_preview_info(moonbit_bytes_t input) {
  int w = 0, h = 0;
  int valid = WebPGetInfo(input, (size_t)Moonbit_array_length(input), &w, &h);
  if (!valid || w < 1 || h < 1 || w > 768 || h > 768) return 0;
  return ((uint64_t)(uint32_t)w << 32) | (uint32_t)h;
}

// Native test fixture; no runtime entry point exposes image creation.
MOONBIT_FFI_EXPORT moonbit_bytes_t moontown_preview_test_png(void) {
  png_image image;
  memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;
  image.width = 1024;
  image.height = 512;
  image.format = PNG_FORMAT_RGBA;
  unsigned char *rgba = malloc(PNG_IMAGE_SIZE(image));
  if (!rgba) return moonbit_make_bytes(0, 0);
  for (unsigned int y = 0; y < image.height; ++y) {
    for (unsigned int x = 0; x < image.width; ++x) {
      size_t i = ((size_t)y * image.width + x) * 4;
      rgba[i] = (unsigned char)(x / 4);
      rgba[i + 1] = (unsigned char)(y / 2);
      rgba[i + 2] = 100;
      rgba[i + 3] = 255;
    }
  }
  png_alloc_size_t size = 0;
  if (!png_image_write_to_memory(&image, NULL, &size, 0, rgba, 0, NULL)) {
    free(rgba); png_image_free(&image); return moonbit_make_bytes(0, 0);
  }
  unsigned char *png = malloc(size);
  if (!png || !png_image_write_to_memory(&image, png, &size, 0, rgba, 0, NULL)) {
    free(png); free(rgba); png_image_free(&image); return moonbit_make_bytes(0, 0);
  }
  free(rgba);
  moonbit_bytes_t result = moonbit_make_bytes((int32_t)size, 0);
  memcpy(result, png, size);
  free(png);
  png_image_free(&image);
  return result;
}
