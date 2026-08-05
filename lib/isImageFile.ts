export function isImageFile(name: string | null | undefined) {
  if (!name) return false;
  return /\.(jpe?g|png|gif|webp|bmp|svg)$/i.test(name);
}
